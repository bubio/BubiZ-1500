import Cocoa

class StatusBarView: NSView {

    static let barHeight: CGFloat = 20

    private enum Colors {
        static let active = NSColor(red: 1.0, green: 0.2, blue: 0.2, alpha: 1.0)
        static let inactive = NSColor(red: 0.3, green: 0.08, blue: 0.08, alpha: 1.0)
        static let label = NSColor(red: 0.7, green: 0.7, blue: 0.7, alpha: 1.0)
        static let fastWind = NSColor(red: 1.0, green: 0.8, blue: 0.0, alpha: 1.0)
        static let recording = NSColor(red: 1.0, green: 0.3, blue: 0.3, alpha: 1.0)
        static let playing = NSColor(red: 0.3, green: 1.0, blue: 0.3, alpha: 1.0)
        static let stopped = NSColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0)
    }

    private var fdAccessed: UInt32 = 0
    private var qdAccessed: UInt32 = 0
    var qdDiskInfo: String? {
        didSet {
            if qdDiskInfo != oldValue { needsDisplay = true }
        }
    }
    private var tapeInserted = false
    private var tapePlaying = false
    private var tapeRecording = false
    private var tapePosition: Int32 = 0
    private var tapeMessage: String?
    private var fps: Double = 0

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.backgroundColor = NSColor.black.cgColor
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(bridge: EmulatorBridge, fps: Double = 0) {
        let newFD = bridge.floppyDiskAccessed()
        let newQD = bridge.quickDiskAccessed()
        let newTapeInserted = bridge.isTapeInserted(0)
        let newPlay = bridge.isTapePlaying(0)
        let newRec = bridge.isTapeRecording(0)
        let newPos = bridge.tapePosition(0)
        let newMsg = bridge.tapeMessage(0)

        // Reset position to 0 when tape is ejected
        let finalPos = newTapeInserted ? newPos : 0
        let finalMsg = newTapeInserted ? newMsg : NSLocalizedString("Stop", comment: "")

        if newFD != fdAccessed || newQD != qdAccessed ||
           newTapeInserted != tapeInserted ||
           newPlay != tapePlaying || newRec != tapeRecording ||
           finalPos != tapePosition || finalMsg != tapeMessage ||
           abs(fps - self.fps) >= 0.5 {
            fdAccessed = newFD
            qdAccessed = newQD
            tapeInserted = newTapeInserted
            tapePlaying = newPlay
            tapeRecording = newRec
            tapePosition = finalPos
            tapeMessage = finalMsg
            self.fps = fps
            needsDisplay = true
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.black.setFill()
        dirtyRect.fill()

        let activeColor = Colors.active
        let inactiveColor = Colors.inactive
        let labelColor = Colors.label
        let labelFont = NSFont.monospacedSystemFont(ofSize: 10, weight: .regular)
        let labelAttrs: [NSAttributedString.Key: Any] = [
            .font: labelFont,
            .foregroundColor: labelColor,
        ]

        let dotFont = NSFont.systemFont(ofSize: 12, weight: .bold)
        let y: CGFloat = 3

        var x: CGFloat = 8

        // FD: ●●
        let fdLabel = NSAttributedString(string: "FD:", attributes: labelAttrs)
        fdLabel.draw(at: NSPoint(x: x, y: y))
        x += fdLabel.size().width + 2

        for i in 0..<2 {
            let on = (fdAccessed & (1 << i)) != 0
            let dotAttrs: [NSAttributedString.Key: Any] = [
                .font: dotFont,
                .foregroundColor: on ? activeColor : inactiveColor,
            ]
            let dot = NSAttributedString(string: "\u{25CF}", attributes: dotAttrs)
            dot.draw(at: NSPoint(x: x, y: y - 1))
            x += dot.size().width + 1
        }

        x += 10

        // QD: ●
        let qdLabel = NSAttributedString(string: "QD:", attributes: labelAttrs)
        qdLabel.draw(at: NSPoint(x: x, y: y))
        x += qdLabel.size().width + 2

        let qdOn = (qdAccessed & 1) != 0
        let qdDotAttrs: [NSAttributedString.Key: Any] = [
            .font: dotFont,
            .foregroundColor: qdOn ? activeColor : inactiveColor,
        ]
        let qdDot = NSAttributedString(string: "\u{25CF}", attributes: qdDotAttrs)
        qdDot.draw(at: NSPoint(x: x, y: y - 1))
        x += qdDot.size().width

        if let diskInfo = qdDiskInfo {
            x += 4
            let diskInfoStr = NSAttributedString(string: diskInfo, attributes: labelAttrs)
            diskInfoStr.draw(at: NSPoint(x: x, y: y))
            x += diskInfoStr.size().width
        }

        x += 10

        // CMT: ● status text
        let cmtLabel = NSAttributedString(string: "CMT:", attributes: labelAttrs)
        cmtLabel.draw(at: NSPoint(x: x, y: y))
        x += cmtLabel.size().width + 2

        // Tape inserted indicator
        let tapeInsertedColor = tapeInserted ? activeColor : inactiveColor
        let tapeDotAttrs: [NSAttributedString.Key: Any] = [
            .font: dotFont,
            .foregroundColor: tapeInsertedColor,
        ]
        let tapeDot = NSAttributedString(string: "\u{25CF}", attributes: tapeDotAttrs)
        tapeDot.draw(at: NSPoint(x: x, y: y - 1))
        x += tapeDot.size().width + 4

        let statusText = tapeMessage ?? NSLocalizedString("Stop", comment: "")
        let statusColor: NSColor

        // 色分け: Fast Forward/Rewind は黄色、Play は緑、Rec は赤、Stop は灰色
        if statusText.hasPrefix("Fast Forward") || statusText.hasPrefix("Fast Rewind") {
            statusColor = Colors.fastWind
        } else if statusText.hasPrefix("Rec") {
            statusColor = Colors.recording
        } else if statusText.hasPrefix("Play") {
            statusColor = Colors.playing
        } else {
            statusColor = Colors.stopped
        }

        let statusAttrs: [NSAttributedString.Key: Any] = [
            .font: labelFont,
            .foregroundColor: statusColor,
        ]
        let statusStr = NSAttributedString(string: statusText, attributes: statusAttrs)
        statusStr.draw(at: NSPoint(x: x, y: y))

        // FPS (右端に表示)
        let fpsText: String
        if fps >= 100 {
            fpsText = String(format: NSLocalizedString("%.0f fps", comment: ""), fps)
        } else {
            fpsText = String(format: NSLocalizedString("%.1f fps", comment: ""), fps)
        }
        let fpsAttrs: [NSAttributedString.Key: Any] = [
            .font: labelFont,
            .foregroundColor: labelColor,
        ]
        let fpsStr = NSAttributedString(string: fpsText, attributes: fpsAttrs)
        let fpsX = bounds.width - fpsStr.size().width - 8
        fpsStr.draw(at: NSPoint(x: fpsX, y: y))
    }
}
