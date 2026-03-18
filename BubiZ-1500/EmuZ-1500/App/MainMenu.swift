import Cocoa

private func L(_ key: String) -> String {
    NSLocalizedString(key, comment: "")
}

private struct MenuEntry {
    let title: String
    let tag: Int
}

private struct PrinterEntry {
    let title: String
    let tag: Int
    let isEnabled: Bool
}

enum MainMenu {
    static func setupMainMenu(target: AppDelegate) {
        let mainMenu = NSMenu()

        // App menu
        let appMenuItem = NSMenuItem()
        mainMenu.addItem(appMenuItem)
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: L("About EmuZ-1500"), action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: L("Quit EmuZ-1500"), action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appMenuItem.submenu = appMenu

        mainMenu.addItem(buildControlMenu(target: target))
        mainMenu.addItem(buildCMTMenu(target: target))
        mainMenu.addItem(buildQDMenu(target: target))
        mainMenu.addItem(buildDeviceMenu(target: target))
        mainMenu.addItem(buildHostMenu(target: target))

        // Window menu
        let windowMenuItem = NSMenuItem()
        let windowMenu = NSMenu(title: L("Window"))
        let fullScreenItem = NSMenuItem(title: L("Enter Full Screen"), action: #selector(NSWindow.toggleFullScreen(_:)), keyEquivalent: "f")
        fullScreenItem.keyEquivalentModifierMask = [.control, .command]
        windowMenu.addItem(fullScreenItem)
        windowMenu.addItem(NSMenuItem.separator())
        windowMenu.addItem(withTitle: L("Minimize"), action: #selector(NSWindow.miniaturize(_:)), keyEquivalent: "m")
        windowMenuItem.submenu = windowMenu
        mainMenu.addItem(windowMenuItem)
        NSApp.mainMenu = mainMenu
    }

    // MARK: - Control Menu

    private static func buildControlMenu(target: AppDelegate) -> NSMenuItem {
        let menuItem = NSMenuItem()
        let menu = NSMenu(title: L("Control"))

        addItem(menu, L("Reset"), #selector(AppDelegate.resetAction(_:)), target, keyEquivalent: "r")

        menu.addItem(NSMenuItem.separator())

        // CPU speed (hardware labels - not localized)
        let cpuSpeeds = ["CPU x1", "CPU x2", "CPU x4"]
        for (index, title) in cpuSpeeds.enumerated() {
            let item = addItem(menu, title, #selector(AppDelegate.setCpuPowerAction(_:)), target)
            item.tag = index
        }
        let fullSpeedItem = addItem(menu, L("Full Speed"), #selector(AppDelegate.toggleFullSpeedAction(_:)), target, keyEquivalent: "f")
        fullSpeedItem.keyEquivalentModifierMask = [.command, .shift]
        addItem(menu, L("Drive VM in M1/R/W Cycle"), #selector(AppDelegate.toggleDriveVMInOpecodeAction(_:)), target)

        menu.addItem(NSMenuItem.separator())

        // Paste / AutoKey (disabled - not implemented)
        addDisabledItem(menu, L("Paste"))
        addDisabledItem(menu, L("Stop"))
        addItem(menu, L("Romaji to Kana"), #selector(AppDelegate.toggleRomajiToKanaAction(_:)), target)

        menu.addItem(NSMenuItem.separator())

        // Save State submenu
        let saveStateItem = NSMenuItem(title: L("Save State"), action: nil, keyEquivalent: "")
        let saveStateMenu = NSMenu()
        for slot in 0...9 {
            let title = String(format: L("State %d"), slot)
            let item = addItem(saveStateMenu, title, #selector(AppDelegate.saveStateSlotAction(_:)), target, keyEquivalent: "\(slot)")
            item.keyEquivalentModifierMask = [.command, .shift]
            item.tag = slot
        }
        saveStateItem.submenu = saveStateMenu
        menu.addItem(saveStateItem)

        // Load State submenu
        let loadStateItem = NSMenuItem(title: L("Load State"), action: nil, keyEquivalent: "")
        let loadStateMenu = NSMenu()
        for slot in 0...9 {
            let title = String(format: L("State %d"), slot)
            let item = addItem(loadStateMenu, title, #selector(AppDelegate.loadStateSlotAction(_:)), target, keyEquivalent: "\(slot)")
            item.keyEquivalentModifierMask = [.command]
            item.tag = slot
        }
        loadStateItem.submenu = loadStateMenu
        menu.addItem(loadStateItem)

        menu.addItem(NSMenuItem.separator())

        // Debug (disabled - not implemented)
        addDisabledItem(menu, L("Debug Main CPU"))
        addDisabledItem(menu, L("Close Debugger"))

        menuItem.submenu = menu
        return menuItem
    }

    // MARK: - CMT Menu

    private static func buildCMTMenu(target: AppDelegate) -> NSMenuItem {
        let menuItem = NSMenuItem()
        let menu = NSMenu(title: L("CMT"))

        let playItem = addItem(menu, L("Play"), #selector(AppDelegate.openTapeAction(_:)), target, keyEquivalent: "o")
        playItem.keyEquivalentModifierMask = [.command, .shift]
        let recItem = addItem(menu, L("Rec"), #selector(AppDelegate.recTapeAction(_:)), target, keyEquivalent: "r")
        recItem.keyEquivalentModifierMask = [.command, .shift]
        let ejectTapeItem = addItem(menu, L("Eject"), #selector(AppDelegate.closeTapeAction(_:)), target, keyEquivalent: "j")
        ejectTapeItem.keyEquivalentModifierMask = [.command, .shift]

        menu.addItem(NSMenuItem.separator())

        let playBtnItem = addItem(menu, L("Play Button"), #selector(AppDelegate.pushPlayAction(_:)), target,
                                  keyEquivalent: String(Character(UnicodeScalar(NSF6FunctionKey)!)))
        playBtnItem.keyEquivalentModifierMask = []
        let stopBtnItem = addItem(menu, L("Stop Button"), #selector(AppDelegate.pushStopAction(_:)), target,
                                  keyEquivalent: String(Character(UnicodeScalar(NSF7FunctionKey)!)))
        stopBtnItem.keyEquivalentModifierMask = []
        let ffItem = addItem(menu, L("Fast Forward"), #selector(AppDelegate.pushFastForwardAction(_:)), target,
                             keyEquivalent: String(Character(UnicodeScalar(NSF8FunctionKey)!)))
        ffItem.keyEquivalentModifierMask = []
        let rewItem = addItem(menu, L("Fast Rewind"), #selector(AppDelegate.pushFastRewindAction(_:)), target,
                              keyEquivalent: String(Character(UnicodeScalar(NSF9FunctionKey)!)))
        rewItem.keyEquivalentModifierMask = []

        menu.addItem(NSMenuItem.separator())

        let waveShaperItem = addItem(menu, L("Waveform Shaper"), #selector(AppDelegate.toggleWaveShaperAction(_:)), target, keyEquivalent: "w")
        waveShaperItem.keyEquivalentModifierMask = [.command, .shift]

        menu.addItem(NSMenuItem.separator())
        let recentTapeItem = NSMenuItem(title: L("Recent"), action: nil, keyEquivalent: "")
        let recentTapeMenu = NSMenu()
        recentTapeMenu.delegate = target
        recentTapeMenu.identifier = NSUserInterfaceItemIdentifier(RecentMenuID.tape.rawValue)
        recentTapeItem.submenu = recentTapeMenu
        menu.addItem(recentTapeItem)

        menuItem.submenu = menu
        return menuItem
    }

    // MARK: - QD Menu

    private static func buildQDMenu(target: AppDelegate) -> NSMenuItem {
        let menuItem = NSMenuItem()
        let menu = NSMenu(title: L("QD"))
        menu.delegate = target
        menu.identifier = NSUserInterfaceItemIdentifier(QDMenuID.diskSet.rawValue)

        let insertQDItem = addItem(menu, L("Insert"), #selector(AppDelegate.openQuickDiskAction(_:)), target, keyEquivalent: "i")
        insertQDItem.keyEquivalentModifierMask = [.command, .shift]
        let ejectQDItem = addItem(menu, L("Eject"), #selector(AppDelegate.closeQuickDiskAction(_:)), target, keyEquivalent: "e")
        ejectQDItem.keyEquivalentModifierMask = [.command, .shift]

        // Disk set section placeholder - dynamically populated via menuNeedsUpdate
        // Separator + disk set items are added dynamically

        menu.addItem(NSMenuItem.separator())

        let nextDiskItem = addItem(menu, L("Next Disk"), #selector(AppDelegate.nextQuickDiskAction(_:)), target, keyEquivalent: "]")
        nextDiskItem.keyEquivalentModifierMask = [.command, .shift]
        let prevDiskItem = addItem(menu, L("Previous Disk"), #selector(AppDelegate.prevQuickDiskAction(_:)), target, keyEquivalent: "[")
        prevDiskItem.keyEquivalentModifierMask = [.command, .shift]

        menu.addItem(NSMenuItem.separator())
        let recentQDItem = NSMenuItem(title: L("Recent"), action: nil, keyEquivalent: "")
        let recentQDMenu = NSMenu()
        recentQDMenu.delegate = target
        recentQDMenu.identifier = NSUserInterfaceItemIdentifier(RecentMenuID.quickDisk.rawValue)
        recentQDItem.submenu = recentQDMenu
        menu.addItem(recentQDItem)

        menuItem.submenu = menu
        return menuItem
    }

    // MARK: - Device Menu

    private static func buildDeviceMenu(target: AppDelegate) -> NSMenuItem {
        let menuItem = NSMenuItem()
        let menu = NSMenu(title: L("Device"))

        // Option submenu
        let optionItem = NSMenuItem(title: L("Option"), action: nil, keyEquivalent: "")
        let optionMenu = NSMenu()
        // Hardware names - not localized
        let optionEntries: [MenuEntry] = [
            MenuEntry(title: "MZ-1E05 (FD I/F)", tag: 8),
            MenuEntry(title: "MZ-1R12 (CMOS RAM)", tag: 10),
            MenuEntry(title: "MZ-1R18 (RAM File)", tag: 11),
            MenuEntry(title: "MZ-1R23 (Kanji ROM)", tag: 12),
            MenuEntry(title: "MZ-1R24 (Dict. ROM)", tag: 13),
            MenuEntry(title: "PIO-3034 (EMM)", tag: 14),
        ]
        for entry in optionEntries {
            let item = addItem(optionMenu, entry.title, #selector(AppDelegate.toggleOptionSwitchAction(_:)), target)
            item.tag = entry.tag
        }
        optionItem.submenu = optionMenu
        menu.addItem(optionItem)

        // Joystick submenu
        let joystickItem = NSMenuItem(title: L("Joystick"), action: nil, keyEquivalent: "")
        let joystickMenu = NSMenu()
        // Hardware names - not localized
        let joystickEntries = ["MZ-1X03", "Tsukumo JOY-700", "AM7J adapter"]
        for (index, title) in joystickEntries.enumerated() {
            let item = addItem(joystickMenu, title, #selector(AppDelegate.setJoystickTypeAction(_:)), target)
            item.tag = index
        }
        joystickItem.submenu = joystickMenu
        menu.addItem(joystickItem)

        // Sound submenu
        let soundItem = NSMenuItem(title: L("Sound"), action: nil, keyEquivalent: "")
        let soundMenu = NSMenu()

        // Hardware names - not localized
        let cmu800Item = addItem(soundMenu, "CMU-800", #selector(AppDelegate.toggleOptionSwitchAction(_:)), target)
        cmu800Item.tag = 0

        let tempoEntries: [MenuEntry] = [
            MenuEntry(title: "CMU-800 Tempo +10", tag: 1),
            MenuEntry(title: "CMU-800 Tempo -10", tag: 2),
            MenuEntry(title: "CMU-800 Tempo +5", tag: 3),
            MenuEntry(title: "CMU-800 Tempo -5", tag: 4),
            MenuEntry(title: "CMU-800 Tempo +1", tag: 5),
            MenuEntry(title: "CMU-800 Tempo -1", tag: 6),
            MenuEntry(title: "CMU-800 Tempo 160", tag: 7),
        ]
        for entry in tempoEntries {
            let item = addItem(soundMenu, entry.title, #selector(AppDelegate.toggleOptionSwitchAction(_:)), target)
            item.tag = entry.tag
        }

        soundMenu.addItem(NSMenuItem.separator())

        addItem(soundMenu, L("Play FDD Noise"), #selector(AppDelegate.toggleSoundNoiseFDDAction(_:)), target)
        addItem(soundMenu, L("Play CMT Noise"), #selector(AppDelegate.toggleSoundNoiseCMTAction(_:)), target)
        addItem(soundMenu, L("Play CMT Signal"), #selector(AppDelegate.toggleSoundTapeSignalAction(_:)), target)
        addItem(soundMenu, L("Play CMT Voice"), #selector(AppDelegate.toggleSoundTapeVoiceAction(_:)), target)

        soundItem.submenu = soundMenu
        menu.addItem(soundItem)

        // Display submenu
        let displayItem = NSMenuItem(title: L("Display"), action: nil, keyEquivalent: "")
        let displayMenu = NSMenu()
        addItem(displayMenu, L("Scanline"), #selector(AppDelegate.toggleScanlineAction(_:)), target)
        displayItem.submenu = displayMenu
        menu.addItem(displayItem)

        // Printer submenu
        let printerItem = NSMenuItem(title: L("Printer"), action: nil, keyEquivalent: "")
        let printerMenu = NSMenu()
        let printerEntries: [PrinterEntry] = [
            PrinterEntry(title: L("Write Printer to File"), tag: 0, isEnabled: true),
            PrinterEntry(title: "MZ-1P17", tag: 1, isEnabled: true),
            PrinterEntry(title: "PC-PR201", tag: 2, isEnabled: false),
            PrinterEntry(title: L("None"), tag: 3, isEnabled: true),
        ]
        for entry in printerEntries {
            let item = addItem(printerMenu, entry.title, #selector(AppDelegate.setPrinterTypeAction(_:)), target)
            item.tag = entry.tag
            item.isEnabled = entry.isEnabled
        }
        printerItem.submenu = printerMenu
        menu.addItem(printerItem)

        menuItem.submenu = menu
        return menuItem
    }

    // MARK: - Host Menu

    private static func buildHostMenu(target: AppDelegate) -> NSMenuItem {
        let menuItem = NSMenuItem()
        let menu = NSMenu(title: L("Host"))

        let captureItem = addItem(menu, L("Capture Screen"), #selector(AppDelegate.captureScreenAction(_:)), target,
                                  keyEquivalent: String(Character(UnicodeScalar(NSF12FunctionKey)!)))
        captureItem.keyEquivalentModifierMask = []

        menu.addItem(NSMenuItem.separator())

        // Screen submenu
        let screenItem = NSMenuItem(title: L("Screen"), action: nil, keyEquivalent: "")
        let screenMenu = NSMenu()

        // Aspect ratio section
        _ = addItem(screenMenu, L("Window Aspect Ratio 640\u{00d7}400"), #selector(AppDelegate.setWindowAspect640x400(_:)), target)
        _ = addItem(screenMenu, L("Window Aspect Ratio 640\u{00d7}480"), #selector(AppDelegate.setWindowAspect640x480(_:)), target)

        screenMenu.addItem(NSMenuItem.separator())

        // Scale section (not localized - "Window x1" is universal)
        let scale1x = addItem(screenMenu, "Window x1", #selector(AppDelegate.setWindowScale1x(_:)), target, keyEquivalent: "1")
        scale1x.keyEquivalentModifierMask = [.command, .option]

        let scale2x = addItem(screenMenu, "Window x2", #selector(AppDelegate.setWindowScale2x(_:)), target, keyEquivalent: "2")
        scale2x.keyEquivalentModifierMask = [.command, .option]

        let scale3x = addItem(screenMenu, "Window x3", #selector(AppDelegate.setWindowScale3x(_:)), target, keyEquivalent: "3")
        scale3x.keyEquivalentModifierMask = [.command, .option]

        screenMenu.addItem(NSMenuItem.separator())

        screenItem.submenu = screenMenu
        menu.addItem(screenItem)

        // Screen Filter submenu
        let filterItem = NSMenuItem(title: L("Screen Filter"), action: nil, keyEquivalent: "")
        let filterMenu = NSMenu()
        let filterEntries: [(String, ScreenFilterType)] = [
            (L("Old School"), .crt),
            (L("NTSC Composite"), .ntsc),
            (L("RGB Filter"), .rgb),
            (L("None"), .none),
        ]
        for (title, filterType) in filterEntries {
            let item = addItem(filterMenu, title, #selector(AppDelegate.setFilterTypeAction(_:)), target)
            item.tag = Int(filterType.rawValue)
        }
        filterItem.submenu = filterMenu
        menu.addItem(filterItem)

        let cycleFilterItem = addItem(menu, L("Cycle Screen Filter"), #selector(AppDelegate.cycleScreenFilterAction(_:)), target,
                                      keyEquivalent: String(Character(UnicodeScalar(NSF10FunctionKey)!)))
        cycleFilterItem.keyEquivalentModifierMask = []

        // Sound Filter submenu
        let soundFilterItem = NSMenuItem(title: L("Sound Filter"), action: nil, keyEquivalent: "")
        let soundFilterMenu = NSMenu()
        addItem(soundFilterMenu, L("Old School"), #selector(AppDelegate.toggleSpeakerSimulationAction(_:)), target)
        addItem(soundFilterMenu, L("Reverb"), #selector(AppDelegate.toggleReverbAction(_:)), target)
        addItem(soundFilterMenu, L("Chorus"), #selector(AppDelegate.toggleChorusAction(_:)), target)
        soundFilterItem.submenu = soundFilterMenu
        menu.addItem(soundFilterItem)

        menuItem.submenu = menu
        return menuItem
    }

    // MARK: - Helpers

    @discardableResult
    private static func addItem(_ menu: NSMenu, _ title: String, _ action: Selector, _ target: AppDelegate, keyEquivalent: String = "") -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: keyEquivalent)
        item.target = target
        menu.addItem(item)
        return item
    }

    private static func addDisabledItem(_ menu: NSMenu, _ title: String) {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.isEnabled = false
        menu.addItem(item)
    }
}
