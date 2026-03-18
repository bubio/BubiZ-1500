import Cocoa
import MetalKit

class EmulatorWindow: NSWindow, NSWindowDelegate {

    private let bridge: EmulatorBridge
    private(set) var emulatorView: EmulatorView!
    private var statusBarView: StatusBarView!
    private var isEmulating = false
    private var currentScale: Double = 1.0

    private var baseWidth: CGFloat { 640 }
    private var baseHeight: CGFloat { bridge.windowAspectMode() == 0 ? 400 : 480 }

    // 挿入中メディアのパスを追跡
    private var tapePath: String?
    private var quickDiskPath: String?
    private var floppyDiskPath: [String?] = [nil, nil]

    init(bridge: EmulatorBridge, width: CGFloat, height: CGFloat) {
        self.bridge = bridge

        let statusBarHeight = StatusBarView.barHeight
        let emulatorWidth = max(width, 640)
        let emulatorHeight = max(height, 400)

        // Calculate initial scale
        let aspectMode = bridge.windowAspectMode()
        let baseHeight: CGFloat = aspectMode == 0 ? 400 : 480
        self.currentScale = Double(emulatorHeight / baseHeight)

        let contentRect = NSRect(x: 0, y: 0, width: emulatorWidth, height: emulatorHeight + statusBarHeight)
        super.init(
            contentRect: contentRect,
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )

        self.delegate = self
        self.title = bridge.deviceName ?? "EmuZ-1500"
        self.center()
        self.isReleasedWhenClosed = false
        self.acceptsMouseMovedEvents = true
        self.minSize = NSSize(width: 320, height: 240 + statusBarHeight)
        self.collectionBehavior.insert(.fullScreenPrimary)

        // Container view
        let container = NSView(frame: NSRect(x: 0, y: 0, width: contentRect.width, height: contentRect.height))
        container.autoresizingMask = [.width, .height]
        self.contentView = container

        // Status bar at bottom
        statusBarView = StatusBarView(frame: NSRect(x: 0, y: 0, width: contentRect.width, height: statusBarHeight))
        statusBarView.autoresizingMask = [.width, .maxYMargin]
        container.addSubview(statusBarView)

        // Create Metal view above status bar
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Metal is not supported on this device")
        }

        let emulatorFrame = NSRect(x: 0, y: statusBarHeight, width: contentRect.width, height: contentRect.height - statusBarHeight)
        emulatorView = EmulatorView(frame: emulatorFrame, device: device, bridge: bridge)
        emulatorView.statusBarView = statusBarView
        emulatorView.autoresizingMask = [.width, .height]
        container.addSubview(emulatorView)

        startEmulation()
    }

    // MARK: - Window Size

    func setScale(_ scale: Double) {
        currentScale = scale
        let statusBarHeight = StatusBarView.barHeight
        let newSize = NSSize(
            width: baseWidth * CGFloat(scale),
            height: baseHeight * CGFloat(scale) + statusBarHeight
        )
        let oldFrame = self.frame
        setContentSize(newSize)
        // 左上基準でウィンドウ位置を維持（macOSは左下原点）
        var newFrame = self.frame
        newFrame.origin.x = oldFrame.origin.x
        newFrame.origin.y = oldFrame.maxY - newFrame.height
        setFrame(newFrame, display: true, animate: true)
    }

    func getCurrentScale() -> Double {
        return currentScale
    }

    func startEmulation() {
        guard !isEmulating else { return }
        isEmulating = true
        emulatorView.isPaused = false
        emulatorView.enableSetNeedsDisplay = false
    }

    func stopEmulation() {
        isEmulating = false
        emulatorView.isPaused = true
    }

    func resetEmulationTiming() {
        emulatorView.resetEmulationTiming()
    }

    func saveScreenshot(to url: URL) -> Bool {
        emulatorView.saveScreenshot(to: url)
    }

    // MARK: - Window Title

    private func nameFromPath(_ path: String) -> String {
        URL(fileURLWithPath: path).deletingPathExtension().lastPathComponent
    }

    func mediaInsertedTape(path: String) {
        tapePath = path
        updateTitle()
    }

    func mediaEjectedTape() {
        tapePath = nil
        updateTitle()
    }

    func mediaInsertedQuickDisk(path: String, diskInfo: String? = nil) {
        quickDiskPath = path
        statusBarView.qdDiskInfo = diskInfo
        updateTitle()
    }

    func mediaEjectedQuickDisk() {
        quickDiskPath = nil
        statusBarView.qdDiskInfo = nil
        updateTitle()
    }

    func mediaInsertedFloppyDisk(drive: Int, path: String) {
        floppyDiskPath[drive] = path
        updateTitle()
    }

    func mediaEjectedFloppyDisk(drive: Int) {
        floppyDiskPath[drive] = nil
        updateTitle()
    }

    private func updateTitle() {
        let baseName = bridge.deviceName ?? "EmuZ-1500"
        var mediaNames: [String] = []

        // FD: D88ディスク名があればそれを、なければファイル名
        for drv in 0..<2 {
            if let path = floppyDiskPath[drv] {
                if let diskName = bridge.floppyDiskName(Int32(drv)), !diskName.isEmpty {
                    mediaNames.append(diskName)
                } else {
                    mediaNames.append(nameFromPath(path))
                }
            }
        }

        // QD: ファイル名
        if let path = quickDiskPath {
            mediaNames.append(nameFromPath(path))
        }

        // CMT: ファイル名
        if let path = tapePath {
            mediaNames.append(nameFromPath(path))
        }

        if mediaNames.isEmpty {
            self.title = baseName
        } else {
            self.title = "\(baseName) — \(mediaNames.joined(separator: ", "))"
        }
    }

    // MARK: - NSWindowDelegate

    func windowWillResize(_ sender: NSWindow, to frameSize: NSSize) -> NSSize {
        if styleMask.contains(.fullScreen) {
            return frameSize
        }
        let statusBarHeight = StatusBarView.barHeight
        return NSSize(
            width: baseWidth * CGFloat(currentScale),
            height: baseHeight * CGFloat(currentScale) + statusBarHeight
        )
    }

    func windowDidExitFullScreen(_ notification: Notification) {
        let statusBarHeight = StatusBarView.barHeight
        let newSize = NSSize(
            width: baseWidth * CGFloat(currentScale),
            height: baseHeight * CGFloat(currentScale) + statusBarHeight
        )
        setContentSize(newSize)
    }

    // MARK: - Key Events

    override var acceptsFirstResponder: Bool { true }

    override func keyDown(with event: NSEvent) {
        if event.modifierFlags.contains(.command) {
            super.keyDown(with: event)
            return
        }
        let vk = macKeyToVK(Int(event.keyCode))
        if vk != 0 {
            bridge.keyDown(Int32(vk), extended: false, repeat: event.isARepeat)
        }
    }

    override func keyUp(with event: NSEvent) {
        let vk = macKeyToVK(Int(event.keyCode))
        if vk != 0 {
            bridge.keyUp(Int32(vk), extended: false)
        }
    }

    override func flagsChanged(with event: NSEvent) {
        // Handle modifier keys (Shift, Control, Option/Alt, Command)
        let flags = event.modifierFlags
        handleModifier(flags: flags, flag: .shift, vkLeft: 0xA0, vkRight: 0xA1)
        handleModifier(flags: flags, flag: .control, vkLeft: 0xA2, vkRight: 0xA3)
        handleModifier(flags: flags, flag: .option, vkLeft: 0xA4, vkRight: 0xA5)
    }

    private func handleModifier(flags: NSEvent.ModifierFlags, flag: NSEvent.ModifierFlags, vkLeft: Int32, vkRight: Int32) {
        if flags.contains(flag) {
            bridge.keyDown(vkLeft, extended: false, repeat: false)
        } else {
            bridge.keyUp(vkLeft, extended: false)
        }
    }

    override func resignKey() {
        super.resignKey()
        bridge.keyLostFocus()
    }

    // MARK: - Key Code Mapping

    // macOS keyCode -> Windows VK mapping (matches KeyCodeMap.h)
    private static let macToVKMap: [Int: Int] = [
        // Alphabetic keys
        0x00: 0x41, 0x01: 0x53, 0x02: 0x44, 0x03: 0x46, 0x04: 0x48,
        0x05: 0x47, 0x06: 0x5A, 0x07: 0x58, 0x08: 0x43, 0x09: 0x56,
        0x0B: 0x42, 0x0C: 0x51, 0x0D: 0x57, 0x0E: 0x45, 0x0F: 0x52,
        0x10: 0x59, 0x11: 0x54,
        // Number row & symbols
        0x12: 0x31, 0x13: 0x32, 0x14: 0x33, 0x15: 0x34, 0x16: 0x36,
        0x17: 0x35, 0x18: 0xBB, 0x19: 0x39, 0x1A: 0x37, 0x1B: 0xBD,
        0x1C: 0x38, 0x1D: 0x30, 0x1E: 0xDD,
        // More alphabetic & punctuation
        0x1F: 0x4F, 0x20: 0x55, 0x21: 0xDB, 0x22: 0x49, 0x23: 0x50,
        0x24: 0x0D, 0x25: 0x4C, 0x26: 0x4A, 0x27: 0xDE, 0x28: 0x4B,
        0x29: 0xBA, 0x2A: 0xDC, 0x2B: 0xBC, 0x2C: 0xBF, 0x2D: 0x4E,
        0x2E: 0x4D, 0x2F: 0xBE,
        // Special keys
        0x30: 0x09, 0x31: 0x20, 0x32: 0xC0, 0x33: 0x08, 0x35: 0x1B,
        // Arrow keys
        0x7B: 0x25, 0x7C: 0x27, 0x7D: 0x28, 0x7E: 0x26,
        // Function keys
        0x7A: 0x70, 0x78: 0x71, 0x63: 0x72, 0x76: 0x73,
        0x60: 0x74, 0x61: 0x75, 0x62: 0x76, 0x64: 0x77,
        0x65: 0x78, 0x6D: 0x79, 0x67: 0x7A, 0x6F: 0x7B,
        // Navigation
        0x73: 0x24, 0x77: 0x23, 0x74: 0x21, 0x79: 0x22,
        0x75: 0x2E, 0x72: 0x2D,
        // Numpad
        0x52: 0x60, 0x53: 0x61, 0x54: 0x62, 0x55: 0x63,
        0x56: 0x64, 0x57: 0x65, 0x58: 0x66, 0x59: 0x67,
        0x5B: 0x68, 0x5C: 0x69, 0x41: 0x6E, 0x43: 0x6A,
        0x45: 0x6B, 0x4B: 0x6F, 0x4E: 0x6D, 0x4C: 0x0D,
    ]

    private func macKeyToVK(_ keyCode: Int) -> Int {
        Self.macToVKMap[keyCode] ?? 0
    }
}
