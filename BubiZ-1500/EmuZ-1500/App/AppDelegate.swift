//
//  AppDelegate.swift
//  BubiZ-1500
//
//  Created by 太田誠司 on 2026/02/13.
//

import Cocoa
import UniformTypeIdentifiers

enum ScreenFilterType: Int32 {
    case none = 0
    case rgb = 1
    case crt = 2
    case ntsc = 3
}

enum RecentMenuID: String {
    case tape = "recentTape"
    case quickDisk = "recentQD"
    case floppyDisk0 = "recentFD0"
    case floppyDisk1 = "recentFD1"
}

enum QDMenuID: String {
    case diskSet = "qdDiskSet"
}

@main
class AppDelegate: NSObject, NSApplicationDelegate, NSMenuItemValidation {

  private var mainWindow: EmulatorWindow?
  private let bridge = EmulatorBridge()

  // QD disk set management
  private(set) var diskSetFiles: [String] = []
  private(set) var diskSetIndex: Int = 0


  func applicationDidFinishLaunching(_ aNotification: Notification) {
    // Setup menu
    MainMenu.setupMainMenu(target: self)

    // Check required ROM files
    var missingFiles: NSArray?
    if !bridge.checkRequiredROMs(&missingFiles) {
      showROMErrorAlert(missingFiles: missingFiles as? [String] ?? [])
      NSApplication.shared.terminate(nil)
      return
    }

    // Start emulator
    bridge.startup()

    // Create main window with aspect ratio from config
    let aspectMode = bridge.windowAspectMode()
    let windowWidth: CGFloat = 640
    let windowHeight: CGFloat = aspectMode == 0 ? 400 : 480
    mainWindow = EmulatorWindow(bridge: bridge, width: windowWidth, height: windowHeight)
    mainWindow?.makeKeyAndOrderFront(nil)
  }

  func applicationWillTerminate(_ aNotification: Notification) {
    mainWindow?.stopEmulation()
    bridge.shutdown()
  }

  func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

  // MARK: - Control Actions

  @objc func resetAction(_ sender: Any?) {
    bridge.reset()
    mainWindow?.resetEmulationTiming()
  }

  @objc func setCpuPowerAction(_ sender: NSMenuItem) {
    bridge.setCpuPower(Int32(sender.tag))
    bridge.updateConfig()
  }

  @objc func toggleFullSpeedAction(_ sender: Any?) {
    bridge.setFullSpeed(!bridge.isFullSpeed())
  }

  @objc func toggleDriveVMInOpecodeAction(_ sender: Any?) {
    bridge.setDriveVMInOpecode(!bridge.isDriveVMInOpecodeEnabled())
  }

  @objc func toggleRomajiToKanaAction(_ sender: Any?) {
    bridge.setRomajiToKana(!bridge.isRomajiToKanaEnabled())
  }

  // MARK: - CMT Actions

  @objc func openTapeAction(_ sender: Any?) {
    let panel = NSOpenPanel()
    panel.allowedContentTypes = [
      UTType.wav,
      UTType(filenameExtension: "mzt"),
    ].compactMap { $0 }
    panel.title = NSLocalizedString("Open Tape Image", comment: "")
    panel.allowsMultipleSelection = false
    if panel.runModal() == .OK, let url = panel.url {
      bridge.lockVM()
      bridge.playTape(0, path: url.path)
      bridge.addRecentTapePath(0, path: url.path)
      bridge.unlockVM()
      mainWindow?.mediaInsertedTape(path: url.path)
    }
  }

  @objc func recTapeAction(_ sender: Any?) {
    let panel = NSSavePanel()
    panel.title = NSLocalizedString("Record Tape", comment: "")
    panel.allowedContentTypes = [UTType.wav]
    panel.nameFieldStringValue = "record.wav"
    panel.canCreateDirectories = true
    if panel.runModal() == .OK, let url = panel.url {
      bridge.lockVM()
      bridge.recTape(0, path: url.path)
      bridge.unlockVM()
    }
  }

  @objc func closeTapeAction(_ sender: Any?) {
    bridge.closeTape(0)
    mainWindow?.mediaEjectedTape()
  }

  @objc func pushPlayAction(_ sender: Any?) {
    bridge.pushPlay(0)
  }

  @objc func pushStopAction(_ sender: Any?) {
    bridge.pushStop(0)
  }

  @objc func pushFastForwardAction(_ sender: Any?) {
    bridge.pushFastForward(0)
  }

  @objc func pushFastRewindAction(_ sender: Any?) {
    bridge.pushFastRewind(0)
  }

  @objc func toggleWaveShaperAction(_ sender: Any?) {
    let current = bridge.isWaveShaperEnabled(0)
    bridge.setWaveShaper(0, enabled: !current)
  }

  // MARK: - FD Actions

  @objc func openFloppyDisk0Action(_ sender: Any?) {
    openFloppyDisk(drive: 0)
  }

  @objc func openFloppyDisk1Action(_ sender: Any?) {
    openFloppyDisk(drive: 1)
  }

  @objc func closeFloppyDisk0Action(_ sender: Any?) {
    bridge.lockVM()
    bridge.closeFloppyDisk(0)
    bridge.unlockVM()
    mainWindow?.mediaEjectedFloppyDisk(drive: 0)
  }

  @objc func closeFloppyDisk1Action(_ sender: Any?) {
    bridge.lockVM()
    bridge.closeFloppyDisk(1)
    bridge.unlockVM()
    mainWindow?.mediaEjectedFloppyDisk(drive: 1)
  }

  @objc func insertBlank2DFD0Action(_ sender: Any?) {
    insertBlankFloppyDisk(drive: 0, type: 0x00, typeName: "2D")
  }

  @objc func insertBlank2DFD1Action(_ sender: Any?) {
    insertBlankFloppyDisk(drive: 1, type: 0x00, typeName: "2D")
  }

  @objc func insertBlank2DDFD0Action(_ sender: Any?) {
    insertBlankFloppyDisk(drive: 0, type: 0x10, typeName: "2DD")
  }

  @objc func insertBlank2DDFD1Action(_ sender: Any?) {
    insertBlankFloppyDisk(drive: 1, type: 0x10, typeName: "2DD")
  }

  @objc func toggleWriteProtectFD0Action(_ sender: Any?) {
    bridge.setFloppyDiskProtected(0, enabled: !bridge.isFloppyDiskProtected(0))
  }

  @objc func toggleWriteProtectFD1Action(_ sender: Any?) {
    bridge.setFloppyDiskProtected(1, enabled: !bridge.isFloppyDiskProtected(1))
  }

  @objc func toggleCorrectTimingFD0Action(_ sender: Any?) {
    bridge.setCorrectDiskTiming(0, enabled: !bridge.isCorrectDiskTimingEnabled(0))
  }

  @objc func toggleCorrectTimingFD1Action(_ sender: Any?) {
    bridge.setCorrectDiskTiming(1, enabled: !bridge.isCorrectDiskTimingEnabled(1))
  }

  @objc func toggleIgnoreCRCFD0Action(_ sender: Any?) {
    bridge.setIgnoreDiskCRC(0, enabled: !bridge.isIgnoreDiskCRCEnabled(0))
  }

  @objc func toggleIgnoreCRCFD1Action(_ sender: Any?) {
    bridge.setIgnoreDiskCRC(1, enabled: !bridge.isIgnoreDiskCRCEnabled(1))
  }

  // MARK: - QD Actions

  @objc func openQuickDiskAction(_ sender: Any?) {
    let panel = NSOpenPanel()
    panel.title = NSLocalizedString("Open Quick Disk Image", comment: "")
    panel.allowsMultipleSelection = false
    if panel.runModal() == .OK, let url = panel.url {
      bridge.lockVM()
      bridge.openQuickDisk(0, path: url.path)
      bridge.addRecentQuickDiskPath(0, path: url.path)
      bridge.unlockVM()
      updateDiskSet(for: url.path)
      mainWindow?.mediaInsertedQuickDisk(path: url.path, diskInfo: currentDiskInfo())
    }
  }

  @objc func closeQuickDiskAction(_ sender: Any?) {
    bridge.lockVM()
    bridge.closeQuickDisk(0)
    bridge.unlockVM()
    diskSetFiles = []
    diskSetIndex = 0
    mainWindow?.mediaEjectedQuickDisk()
  }

  @objc func switchQuickDiskAction(_ sender: NSMenuItem) {
    guard let index = sender.representedObject as? Int else { return }
    switchToQuickDisk(at: index)
  }

  @objc func nextQuickDiskAction(_ sender: Any?) {
    guard diskSetFiles.count > 1 else { return }
    let nextIndex = (diskSetIndex + 1) % diskSetFiles.count
    switchToQuickDisk(at: nextIndex)
  }

  @objc func prevQuickDiskAction(_ sender: Any?) {
    guard diskSetFiles.count > 1 else { return }
    let prevIndex = (diskSetIndex - 1 + diskSetFiles.count) % diskSetFiles.count
    switchToQuickDisk(at: prevIndex)
  }

  private func switchToQuickDisk(at index: Int) {
    guard index >= 0, index < diskSetFiles.count, index != diskSetIndex else { return }
    let path = diskSetFiles[index]
    bridge.lockVM()
    bridge.closeQuickDisk(0)
    bridge.openQuickDisk(0, path: path)
    bridge.addRecentQuickDiskPath(0, path: path)
    bridge.unlockVM()
    diskSetIndex = index
    mainWindow?.mediaInsertedQuickDisk(path: path, diskInfo: currentDiskInfo())
  }

  private func updateDiskSet(for path: String) {
    let url = URL(fileURLWithPath: path)
    let directory = url.deletingLastPathComponent()
    let ext = url.pathExtension.lowercased()
    let baseName = url.deletingPathExtension().lastPathComponent

    // Extract prefix: remove trailing [-_] + single alphanumeric character
    guard let prefix = extractPrefix(from: baseName) else {
      diskSetFiles = []
      diskSetIndex = 0
      return
    }

    // Find all files in the same directory with the same extension and prefix
    let fm = FileManager.default
    guard let contents = try? fm.contentsOfDirectory(atPath: directory.path) else {
      diskSetFiles = []
      diskSetIndex = 0
      return
    }

    var matches: [String] = []
    for fileName in contents {
      let fileURL = directory.appendingPathComponent(fileName)
      guard fileURL.pathExtension.lowercased() == ext else { continue }
      let fileBase = fileURL.deletingPathExtension().lastPathComponent
      guard extractPrefix(from: fileBase) == prefix else { continue }
      matches.append(fileURL.path)
    }

    matches.sort { URL(fileURLWithPath: $0).lastPathComponent.localizedStandardCompare(URL(fileURLWithPath: $1).lastPathComponent) == .orderedAscending }

    if matches.count > 1 {
      diskSetFiles = matches
      diskSetIndex = matches.firstIndex(of: path) ?? 0
    } else {
      diskSetFiles = []
      diskSetIndex = 0
    }
  }

  private static let suffixPatterns: [String] = [
    "\\s*\\(Side[_ ]?[A-Za-z0-9]\\)$",   // (Side A), (Side_A)
    "\\s*\\(Disk[_ ]?[0-9]+\\)$",          // (Disk 1), (Disk 12)
    "\\s+Side[_ ][A-Za-z0-9]$",            // Side A (no parens)
    "[-_][A-Za-z0-9]$",                     // VOLGUARD-A, DevilLand_B
  ]

  private func extractPrefix(from baseName: String) -> String? {
    for pattern in Self.suffixPatterns {
      if let range = baseName.range(of: pattern, options: .regularExpression) {
        let prefix = String(baseName[baseName.startIndex..<range.lowerBound])
        if !prefix.isEmpty { return prefix }
      }
    }
    return nil
  }

  func currentDiskInfo() -> String? {
    guard diskSetFiles.count > 1 else { return nil }
    let fileName = URL(fileURLWithPath: diskSetFiles[diskSetIndex]).lastPathComponent
    return "\(fileName) (\(diskSetIndex + 1)/\(diskSetFiles.count))"
  }

  // MARK: - Device Actions

  @objc func toggleOptionSwitchAction(_ sender: NSMenuItem) {
    let current = bridge.optionSwitch()
    bridge.setOptionSwitch(current ^ (1 << sender.tag))
    bridge.updateConfig()
  }

  @objc func setJoystickTypeAction(_ sender: NSMenuItem) {
    bridge.setJoystickType(Int32(sender.tag))
  }

  @objc func setPrinterTypeAction(_ sender: NSMenuItem) {
    bridge.setPrinterType(Int32(sender.tag))
  }

  @objc func toggleScanlineAction(_ sender: Any?) {
    bridge.setScanline(!bridge.isScanlineEnabled())
  }

  // MARK: - Device Sound Actions

  @objc func toggleSoundNoiseFDDAction(_ sender: Any?) {
    bridge.setSoundNoiseFDD(!bridge.isSoundNoiseFDDEnabled())
  }

  @objc func toggleSoundNoiseCMTAction(_ sender: Any?) {
    bridge.setSoundNoiseCMT(!bridge.isSoundNoiseCMTEnabled())
  }

  @objc func toggleSoundTapeSignalAction(_ sender: Any?) {
    bridge.setSoundTapeSignal(!bridge.isSoundTapeSignalEnabled())
  }

  @objc func toggleSoundTapeVoiceAction(_ sender: Any?) {
    bridge.setSoundTapeVoice(!bridge.isSoundTapeVoiceEnabled())
  }

  @objc func toggleSpeakerSimulationAction(_ sender: Any?) {
    bridge.setSpeakerSimulation(!bridge.isSpeakerSimulationEnabled())
  }

  @objc func toggleReverbAction(_ sender: Any?) {
    bridge.setReverb(!bridge.isReverbEnabled())
  }

  @objc func toggleChorusAction(_ sender: Any?) {
    bridge.setChorus(!bridge.isChorusEnabled())
  }

  // MARK: - Host Actions

  @objc func setFilterTypeAction(_ sender: NSMenuItem) {
    guard let filterType = ScreenFilterType(rawValue: Int32(sender.tag)) else { return }
    bridge.setFilterType(filterType.rawValue)
  }

  @objc func cycleScreenFilterAction(_ sender: Any?) {
    // Cycle: None → CRT → NTSC → RGB → None
    let current = ScreenFilterType(rawValue: Int32(bridge.filterType())) ?? .none
    let next: ScreenFilterType
    switch current {
    case .none: next = .crt
    case .crt:  next = .ntsc
    case .ntsc: next = .rgb
    case .rgb:  next = .none
    }
    bridge.setFilterType(next.rawValue)
  }

  // MARK: - State Save/Load Actions

  @objc func saveStateSlotAction(_ sender: NSMenuItem) {
    let path = stateFilePath(slot: sender.tag)
    guard !path.isEmpty else { return }
    bridge.saveState(path)
  }

  @objc func loadStateSlotAction(_ sender: NSMenuItem) {
    let path = stateFilePath(slot: sender.tag)
    guard FileManager.default.fileExists(atPath: path) else { return }
    bridge.loadState(path)
  }

  private func stateFilePath(slot: Int) -> String {
    guard let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
      return ""
    }
    let appDir = appSupport.appendingPathComponent("BubiZ-1500")
    try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)
    return appDir.appendingPathComponent("mz1500.sta\(slot)").path
  }

  // MARK: - Window Size Actions

  @objc func setWindowScale1x(_ sender: Any?) { mainWindow?.setScale(1.0) }
  @objc func setWindowScale2x(_ sender: Any?) { mainWindow?.setScale(2.0) }
  @objc func setWindowScale3x(_ sender: Any?) { mainWindow?.setScale(3.0) }

  // MARK: - Window Aspect Actions

  @objc func setWindowAspect640x400(_ sender: Any?) {
    // Calculate current scale BEFORE changing aspect mode
    if let currentScale = mainWindow?.getCurrentScale() {
      bridge.setWindowAspectMode(0)
      bridge.updateConfig()
      mainWindow?.setScale(currentScale)
    }
  }

  @objc func setWindowAspect640x480(_ sender: Any?) {
    // Calculate current scale BEFORE changing aspect mode
    if let currentScale = mainWindow?.getCurrentScale() {
      bridge.setWindowAspectMode(1)
      bridge.updateConfig()
      mainWindow?.setScale(currentScale)
    }
  }

  // MARK: - Screenshot Actions

  @objc func captureScreenAction(_ sender: Any?) {
    guard let mainWindow else { return }

    let panel = NSSavePanel()
    panel.title = NSLocalizedString("Save Screenshot", comment: "")
    panel.allowedContentTypes = [.png]

    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
    let timestamp = dateFormatter.string(from: Date())
    panel.nameFieldStringValue = "\(timestamp).png"
    panel.canCreateDirectories = true

    if panel.runModal() == .OK, let url = panel.url {
      let success = mainWindow.saveScreenshot(to: url)
      if !success {
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("Screenshot save failed", comment: "")
        alert.informativeText = NSLocalizedString("An error occurred while saving the screen capture.", comment: "")
        alert.alertStyle = .warning
        alert.runModal()
      }
    }
  }

  // MARK: - Private Helpers

  private func openFloppyDisk(drive: Int) {
    let panel = NSOpenPanel()
    panel.title = String(format: NSLocalizedString("Open Floppy Disk Image (Drive %d)", comment: ""), drive)
    panel.allowsMultipleSelection = false
    if panel.runModal() == .OK, let url = panel.url {
      bridge.lockVM()
      bridge.openFloppyDisk(Int32(drive), path: url.path, bank: 0)
      bridge.addRecentFloppyDiskPath(Int32(drive), path: url.path)
      bridge.unlockVM()
      mainWindow?.mediaInsertedFloppyDisk(drive: drive, path: url.path)
    }
  }

  private func insertBlankFloppyDisk(drive: Int, type: Int, typeName: String) {
    let panel = NSSavePanel()
    panel.title = String(format: NSLocalizedString("Create Blank %@ Disk (Drive %d)", comment: ""), typeName, drive)
    panel.allowedContentTypes = [UTType(filenameExtension: "d88")].compactMap { $0 }
    panel.nameFieldStringValue = "blank.\(typeName.lowercased()).d88"
    panel.canCreateDirectories = true
    if panel.runModal() == .OK, let url = panel.url {
      bridge.lockVM()
      if bridge.createBlankFloppyDisk(url.path, type: Int32(type)) {
        bridge.openFloppyDisk(Int32(drive), path: url.path, bank: 0)
      }
      bridge.unlockVM()
      mainWindow?.mediaInsertedFloppyDisk(drive: drive, path: url.path)
    }
  }

  // MARK: - Menu Validation

  func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
    switch menuItem.action {
    // CMT
    case #selector(pushPlayAction):
      return bridge.isTapeInserted(0) || bridge.hasTapeFilePath()
    case #selector(closeTapeAction),
         #selector(pushStopAction),
         #selector(pushFastForwardAction),
         #selector(pushFastRewindAction):
      return bridge.isTapeInserted(0)
    case #selector(toggleWaveShaperAction):
      menuItem.state = bridge.isWaveShaperEnabled(0) ? .on : .off
      return true

    // FD eject
    case #selector(closeFloppyDisk0Action):
      return bridge.isFloppyDiskInserted(0)
    case #selector(closeFloppyDisk1Action):
      return bridge.isFloppyDiskInserted(1)

    // FD write protect
    case #selector(toggleWriteProtectFD0Action):
      menuItem.state = bridge.isFloppyDiskProtected(0) ? .on : .off
      return bridge.isFloppyDiskInserted(0)
    case #selector(toggleWriteProtectFD1Action):
      menuItem.state = bridge.isFloppyDiskProtected(1) ? .on : .off
      return bridge.isFloppyDiskInserted(1)

    // FD correct timing
    case #selector(toggleCorrectTimingFD0Action):
      menuItem.state = bridge.isCorrectDiskTimingEnabled(0) ? .on : .off
      return true
    case #selector(toggleCorrectTimingFD1Action):
      menuItem.state = bridge.isCorrectDiskTimingEnabled(1) ? .on : .off
      return true

    // FD ignore CRC
    case #selector(toggleIgnoreCRCFD0Action):
      menuItem.state = bridge.isIgnoreDiskCRCEnabled(0) ? .on : .off
      return true
    case #selector(toggleIgnoreCRCFD1Action):
      menuItem.state = bridge.isIgnoreDiskCRCEnabled(1) ? .on : .off
      return true

    // QD
    case #selector(closeQuickDiskAction):
      return bridge.isQuickDiskInserted(0)
    case #selector(nextQuickDiskAction), #selector(prevQuickDiskAction):
      return diskSetFiles.count > 1

    // CPU speed
    case #selector(setCpuPowerAction):
      menuItem.state = bridge.cpuPower() == menuItem.tag ? .on : .off
      return true
    case #selector(toggleFullSpeedAction):
      menuItem.state = bridge.isFullSpeed() ? .on : .off
      return true
    case #selector(toggleDriveVMInOpecodeAction):
      menuItem.state = bridge.isDriveVMInOpecodeEnabled() ? .on : .off
      return true

    // Romaji to Kana
    case #selector(toggleRomajiToKanaAction):
      menuItem.state = bridge.isRomajiToKanaEnabled() ? .on : .off
      return true

    // Option switch (bit toggle)
    case #selector(toggleOptionSwitchAction):
      let current = bridge.optionSwitch()
      menuItem.state = (current & (1 << menuItem.tag)) != 0 ? .on : .off
      return true

    // Joystick type
    case #selector(setJoystickTypeAction):
      menuItem.state = bridge.joystickType() == menuItem.tag ? .on : .off
      return true

    // Printer type
    case #selector(setPrinterTypeAction):
      if menuItem.tag == 2 { return false } // PC-PR201 not supported
      menuItem.state = bridge.printerType() == menuItem.tag ? .on : .off
      return true

    // Scanline
    case #selector(toggleScanlineAction):
      menuItem.state = bridge.isScanlineEnabled() ? .on : .off
      return true

    // Device sound
    case #selector(toggleSoundNoiseFDDAction):
      menuItem.state = bridge.isSoundNoiseFDDEnabled() ? .on : .off
      return true
    case #selector(toggleSoundNoiseCMTAction):
      menuItem.state = bridge.isSoundNoiseCMTEnabled() ? .on : .off
      return true
    case #selector(toggleSoundTapeSignalAction):
      menuItem.state = bridge.isSoundTapeSignalEnabled() ? .on : .off
      return true
    case #selector(toggleSoundTapeVoiceAction):
      menuItem.state = bridge.isSoundTapeVoiceEnabled() ? .on : .off
      return true
    case #selector(toggleSpeakerSimulationAction):
      menuItem.state = bridge.isSpeakerSimulationEnabled() ? .on : .off
      return true
    case #selector(toggleReverbAction):
      menuItem.state = bridge.isReverbEnabled() ? .on : .off
      return true
    case #selector(toggleChorusAction):
      menuItem.state = bridge.isChorusEnabled() ? .on : .off
      return true

    // Filter type
    case #selector(setFilterTypeAction):
      menuItem.state = bridge.filterType() == menuItem.tag ? .on : .off
      return true

    // Window aspect ratio
    case #selector(setWindowAspect640x400):
      let isFullScreen = mainWindow?.styleMask.contains(.fullScreen) == true
      menuItem.state = bridge.windowAspectMode() == 0 ? .on : .off
      return !isFullScreen
    case #selector(setWindowAspect640x480):
      let isFullScreen = mainWindow?.styleMask.contains(.fullScreen) == true
      menuItem.state = bridge.windowAspectMode() == 1 ? .on : .off
      return !isFullScreen

    // Window scale - show checkmark for current scale
    case #selector(setWindowScale1x):
      let isFullScreen = mainWindow?.styleMask.contains(.fullScreen) == true
      let scale = mainWindow?.getCurrentScale() ?? 1.0
      menuItem.state = abs(scale - 1.0) < 0.1 ? .on : .off
      return !isFullScreen
    case #selector(setWindowScale2x):
      let isFullScreen = mainWindow?.styleMask.contains(.fullScreen) == true
      let scale = mainWindow?.getCurrentScale() ?? 1.0
      menuItem.state = abs(scale - 2.0) < 0.1 ? .on : .off
      return !isFullScreen
    case #selector(setWindowScale3x):
      let isFullScreen = mainWindow?.styleMask.contains(.fullScreen) == true
      let scale = mainWindow?.getCurrentScale() ?? 1.0
      menuItem.state = abs(scale - 3.0) < 0.1 ? .on : .off
      return !isFullScreen

    default:
      return true
    }
  }

  // MARK: - Recent File Actions

  @objc func openRecentTape(_ sender: NSMenuItem) {
    guard let path = sender.representedObject as? String else { return }
    bridge.lockVM()
    bridge.playTape(0, path: path)
    bridge.addRecentTapePath(0, path: path)
    bridge.unlockVM()
    mainWindow?.mediaInsertedTape(path: path)
  }

  @objc func openRecentFloppyDisk0(_ sender: NSMenuItem) {
    guard let path = sender.representedObject as? String else { return }
    bridge.lockVM()
    bridge.openFloppyDisk(0, path: path, bank: 0)
    bridge.addRecentFloppyDiskPath(0, path: path)
    bridge.unlockVM()
    mainWindow?.mediaInsertedFloppyDisk(drive: 0, path: path)
  }

  @objc func openRecentFloppyDisk1(_ sender: NSMenuItem) {
    guard let path = sender.representedObject as? String else { return }
    bridge.lockVM()
    bridge.openFloppyDisk(1, path: path, bank: 0)
    bridge.addRecentFloppyDiskPath(1, path: path)
    bridge.unlockVM()
    mainWindow?.mediaInsertedFloppyDisk(drive: 1, path: path)
  }

  @objc func openRecentQuickDisk(_ sender: NSMenuItem) {
    guard let path = sender.representedObject as? String else { return }
    bridge.lockVM()
    bridge.openQuickDisk(0, path: path)
    bridge.addRecentQuickDiskPath(0, path: path)
    bridge.unlockVM()
    updateDiskSet(for: path)
    mainWindow?.mediaInsertedQuickDisk(path: path, diskInfo: currentDiskInfo())
  }

  private func showROMErrorAlert(missingFiles: [String]) {
    let alert = NSAlert()
    alert.messageText = NSLocalizedString("Required ROM files not found", comment: "")
    alert.alertStyle = .critical

    let romPath = bridge.romDirectoryPath()

    var infoText = NSLocalizedString("The following ROM files are required:\n\n", comment: "")
    for file in missingFiles {
      infoText += "• \(file)\n"
    }
    infoText += String(format: NSLocalizedString("\nLocation:\n%@\n\nPlease place the ROM files and restart.", comment: ""), romPath)

    alert.informativeText = infoText
    alert.addButton(withTitle: NSLocalizedString("Quit", comment: ""))
    alert.runModal()
  }

}

// MARK: - NSMenuDelegate

extension AppDelegate: NSMenuDelegate {
  func menuNeedsUpdate(_ menu: NSMenu) {
    guard let rawID = menu.identifier?.rawValue else { return }

    // Handle QD disk set menu
    if rawID == QDMenuID.diskSet.rawValue {
      updateDiskSetMenu(menu)
      return
    }

    guard let menuID = RecentMenuID(rawValue: rawID) else { return }
    menu.removeAllItems()

    let paths: [String]
    let action: Selector

    switch menuID {
    case .tape:
      paths = bridge.recentTapePaths(0) as [String]
      action = #selector(openRecentTape(_:))
    case .quickDisk:
      paths = bridge.recentQuickDiskPaths(0) as [String]
      action = #selector(openRecentQuickDisk(_:))
    case .floppyDisk0:
      paths = bridge.recentFloppyDiskPaths(0) as [String]
      action = #selector(openRecentFloppyDisk0(_:))
    case .floppyDisk1:
      paths = bridge.recentFloppyDiskPaths(1) as [String]
      action = #selector(openRecentFloppyDisk1(_:))
    }

    for path in paths {
      let item = NSMenuItem(title: path, action: action, keyEquivalent: "")
      item.target = self
      item.representedObject = path
      menu.addItem(item)
    }
  }

  private func updateDiskSetMenu(_ menu: NSMenu) {
    // Remove existing dynamic disk set items (tagged with identifier)
    let dynamicTag = 9000
    while let item = menu.items.first(where: { $0.tag >= dynamicTag }) {
      menu.removeItem(item)
    }

    guard diskSetFiles.count > 1 else { return }

    // Insert after "Eject" (index 1) — add separator + disk items
    var insertIndex = 2 // after Insert(0), Eject(1)
    let separator = NSMenuItem.separator()
    separator.tag = dynamicTag
    menu.insertItem(separator, at: insertIndex)
    insertIndex += 1

    for (index, path) in diskSetFiles.enumerated() {
      let fileName = URL(fileURLWithPath: path).lastPathComponent
      let item = NSMenuItem(title: fileName, action: #selector(switchQuickDiskAction(_:)), keyEquivalent: "")
      item.target = self
      item.tag = dynamicTag + 1 + index
      item.representedObject = index
      item.state = index == diskSetIndex ? .on : .off
      menu.insertItem(item, at: insertIndex)
      insertIndex += 1
    }
  }
}
