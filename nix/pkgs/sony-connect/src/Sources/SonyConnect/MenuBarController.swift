import AppKit

final class MenuBarController: NSObject, NSMenuDelegate {
    private let statusItem: NSStatusItem
    private let controller = HeadphonesController()
    private let popupMenu = NSMenu()

    private let statusMenuItem = NSMenuItem(title: "Disconnected", action: nil, keyEquivalent: "")
    private let batteryMenuItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
    private let volumeMenuItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
    private let volumeSlider = NSSlider()
    private let volumeController = VolumeController(nameHints: SupportedDevices.nameHints)
    private let eqPresetMenuItem = NSMenuItem(title: "Equalizer: —", action: nil, keyEquivalent: "")
    private let eqPresetSubmenu = NSMenu(title: "Equalizer")
    private let eqPresetListItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
    private let eqPresetListView = EqPresetListView()
    private var eqSubmenuBuilt = false
    private let eqBandsMenuItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
    private let eqView = EqualizerView()
    private let ncParentMenuItem = NSMenuItem(title: "Noise Cancelling: —", action: nil, keyEquivalent: "")
    private let ncOnItem = NSMenuItem(title: "Noise Cancelling", action: nil, keyEquivalent: "")
    private let ncAmbientItem = NSMenuItem(title: "Ambient Sound", action: nil, keyEquivalent: "")
    private let ncOffItem = NSMenuItem(title: "Off", action: nil, keyEquivalent: "")
    private let ambientSettingsMenuItem = NSMenuItem(title: "Ambient Sound Settings", action: nil, keyEquivalent: "")
    private let ambientSettingsSubmenu = NSMenu(title: "Ambient Sound Settings")
    private let ambientLevelMenuItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
    private let ambientLevelSlider = ScrollableSlider()
    private let focusOnVoiceMenuItem = NSMenuItem(title: "Focus on Voice", action: nil, keyEquivalent: "")
    private let speakToChatMenuItem = NSMenuItem(title: "Speak-to-Chat: —", action: nil, keyEquivalent: "")
    private let autoOffMenuItem = NSMenuItem(title: "Auto Power Off", action: nil, keyEquivalent: "")
    private let autoOffSubmenu = NSMenu(title: "Auto Power Off")
    private let powerOffMenuItem = NSMenuItem(title: "Power Off Headphones", action: nil, keyEquivalent: "")
    private let reconnectMenuItem = NSMenuItem(title: "Reconnect", action: nil, keyEquivalent: "r")
    private let hideIconMenuItem = NSMenuItem(title: "Hide Icon When Disconnected", action: nil, keyEquivalent: "")
    private let openLogMenuItem = NSMenuItem(title: "Open Log…", action: nil, keyEquivalent: "")

    private static let hideIconDefaultsKey = "HideIconWhenDisconnected"
    private static var hideIconWhenDisconnected: Bool {
        get { UserDefaults.standard.bool(forKey: hideIconDefaultsKey) }
        set { UserDefaults.standard.set(newValue, forKey: hideIconDefaultsKey) }
    }

    override init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        // Without an autosaveName, macOS doesn't remember a dragged position
        // across the item disappearing and reappearing (isVisible toggling
        // below) — it just re-inserts wherever. This keys the position to a
        // stable name so a manual drag sticks across connect/disconnect.
        statusItem.autosaveName = "SonyConnectStatusItem"
        super.init()
        configureStatusButton()
        configureMenu()
        controller.onStateChange = { [weak self] state in
            DispatchQueue.main.async { self?.render(state: state) }
        }
        render(state: controller.state)
        // No eager connect — ConnectionPolicy will dial up when audio
        // starts playing or the user opens the menu.
    }

    // MARK: - Icon

    private func applyIcon() {
        guard let image = NSImage(systemSymbolName: "airpodsmax",
                                  accessibilityDescription: "SonyConnect") else {
            statusItem.button?.title = "🎧"
            return
        }
        image.isTemplate = true
        statusItem.button?.image = image
        statusItem.button?.title = ""
    }

    // MARK: - Setup

    private func configureStatusButton() {
        guard let button = statusItem.button else { return }
        button.target = self
        button.action = #selector(handleClick(_:))
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        applyIcon()
    }

    private func configureMenu() {
        popupMenu.delegate = self

        statusMenuItem.isEnabled = false
        popupMenu.addItem(statusMenuItem)

        batteryMenuItem.isEnabled = false
        batteryMenuItem.isHidden = true
        popupMenu.addItem(batteryMenuItem)

        configureVolumeItem()
        popupMenu.addItem(volumeMenuItem)

        eqPresetMenuItem.submenu = eqPresetSubmenu
        eqPresetMenuItem.isHidden = true
        popupMenu.addItem(eqPresetMenuItem)

        // The preset list and band sliders live inside the Equalizer
        // submenu (collapsed by default). Both are custom views so a click
        // doesn't dismiss the menu — presets can be auditioned in place.
        eqPresetListView.onSelect = { [weak self] id in self?.controller.setEqPreset(id) }
        eqPresetListItem.view = eqPresetListView
        eqView.onBandsChanged = { [weak self] bands in self?.controller.setEqBands(bands) }
        eqBandsMenuItem.view = eqView

        popupMenu.addItem(.separator())

        // Noise Cancelling submenu (three radio-style options)
        let ncSubmenu = NSMenu(title: "Noise Cancelling")
        for (item, tag) in [(ncOnItem, 0), (ncAmbientItem, 1), (ncOffItem, 2)] {
            item.target = self
            item.action = #selector(setNCFromMenu(_:))
            item.tag = tag
            ncSubmenu.addItem(item)
        }
        ncSubmenu.addItem(.separator())
        configureAmbientLevelItem()
        ambientSettingsSubmenu.addItem(ambientLevelMenuItem)
        ambientSettingsSubmenu.addItem(.separator())
        focusOnVoiceMenuItem.target = self
        focusOnVoiceMenuItem.action = #selector(toggleFocusOnVoice)
        ambientSettingsSubmenu.addItem(focusOnVoiceMenuItem)
        ambientSettingsMenuItem.submenu = ambientSettingsSubmenu
        ncSubmenu.addItem(ambientSettingsMenuItem)

        ncParentMenuItem.submenu = ncSubmenu
        popupMenu.addItem(ncParentMenuItem)

        speakToChatMenuItem.target = self
        speakToChatMenuItem.action = #selector(toggleSpeakToChat)
        popupMenu.addItem(speakToChatMenuItem)

        popupMenu.addItem(.separator())

        autoOffMenuItem.submenu = autoOffSubmenu
        popupMenu.addItem(autoOffMenuItem)

        powerOffMenuItem.target = self
        powerOffMenuItem.action = #selector(powerOff)
        popupMenu.addItem(powerOffMenuItem)

        popupMenu.addItem(.separator())

        reconnectMenuItem.target = self
        reconnectMenuItem.action = #selector(reconnect)
        popupMenu.addItem(reconnectMenuItem)

        hideIconMenuItem.target = self
        hideIconMenuItem.action = #selector(toggleHideIcon)
        popupMenu.addItem(hideIconMenuItem)

        openLogMenuItem.target = self
        openLogMenuItem.action = #selector(openLog)
        popupMenu.addItem(openLogMenuItem)

        popupMenu.addItem(.separator())
        popupMenu.addItem(NSMenuItem(title: "Quit SonyConnect",
                                     action: #selector(NSApplication.terminate(_:)),
                                     keyEquivalent: "q"))
    }

    private func configureVolumeItem() {
        let width: CGFloat = 230
        let height: CGFloat = 26
        let leftInset: CGFloat = 38
        let rightInset: CGFloat = 14
        let container = NSView(frame: NSRect(x: 0, y: 0, width: width, height: height))
        // NSMenu stretches a custom item view to the menu's content width
        // when its autoresizing mask is flexible-width.
        container.autoresizingMask = [.width]

        let icon = NSImageView(frame: NSRect(x: 14, y: 5, width: 16, height: 16))
        icon.image = NSImage(systemSymbolName: "speaker.wave.2.fill",
                             accessibilityDescription: "Volume")
        icon.contentTintColor = .secondaryLabelColor
        icon.autoresizingMask = [.maxXMargin]   // pinned to the left
        container.addSubview(icon)

        volumeSlider.frame = NSRect(x: leftInset, y: 3,
                                    width: width - leftInset - rightInset, height: 20)
        // Fixed left/right margins, flexible width → grows with the menu.
        volumeSlider.autoresizingMask = [.width]
        volumeSlider.minValue = 0
        volumeSlider.maxValue = 1
        volumeSlider.isContinuous = true
        volumeSlider.target = self
        volumeSlider.action = #selector(volumeChanged(_:))
        container.addSubview(volumeSlider)

        volumeMenuItem.view = container
        volumeMenuItem.isHidden = true
    }

    @objc private func volumeChanged(_ sender: NSSlider) {
        volumeController.setVolume(Float(sender.doubleValue))
    }

    private func configureAmbientLevelItem() {
        let width: CGFloat = 230
        let height: CGFloat = 40
        let leftInset: CGFloat = 38
        let rightInset: CGFloat = 14
        let container = NSView(frame: NSRect(x: 0, y: 0, width: width, height: height))
        container.autoresizingMask = [.width]

        let icon = NSImageView(frame: NSRect(x: 14, y: 19, width: 16, height: 16))
        icon.image = NSImage(systemSymbolName: "dot.radiowaves.left.and.right",
                             accessibilityDescription: "Ambient Sound Level")
        icon.contentTintColor = .secondaryLabelColor
        icon.autoresizingMask = [.maxXMargin]
        container.addSubview(icon)

        ambientLevelSlider.frame = NSRect(x: leftInset, y: 15,
                                          width: width - leftInset - rightInset, height: 24)
        ambientLevelSlider.autoresizingMask = [.width]
        ambientLevelSlider.minValue = 0
        ambientLevelSlider.maxValue = Double(HeadphonesController.maxAmbientLevel)
        ambientLevelSlider.isContinuous = false   // commit on mouse-up, don't flood RFCOMM
        // One tick per integer step so drags snap and the notches are
        // visible, matching the official app's stepped feel.
        ambientLevelSlider.numberOfTickMarks = Int(HeadphonesController.maxAmbientLevel) + 1
        ambientLevelSlider.allowsTickMarkValuesOnly = true
        ambientLevelSlider.tickMarkPosition = .below
        ambientLevelSlider.target = self
        ambientLevelSlider.action = #selector(ambientLevelChanged(_:))
        container.addSubview(ambientLevelSlider)

        let minLabel = NSTextField(labelWithString: "0")
        minLabel.font = .systemFont(ofSize: 9)
        minLabel.textColor = .secondaryLabelColor
        minLabel.frame = NSRect(x: leftInset, y: 2, width: 24, height: 11)
        container.addSubview(minLabel)

        let maxLabel = NSTextField(labelWithString: "\(Int(HeadphonesController.maxAmbientLevel))")
        maxLabel.font = .systemFont(ofSize: 9)
        maxLabel.textColor = .secondaryLabelColor
        maxLabel.alignment = .right
        maxLabel.frame = NSRect(x: width - rightInset - 24, y: 2, width: 24, height: 11)
        maxLabel.autoresizingMask = [.minXMargin]
        container.addSubview(maxLabel)

        ambientLevelMenuItem.view = container
    }

    @objc private func ambientLevelChanged(_ sender: NSSlider) {
        controller.setAmbientLevel(sender.integerValue)
    }

    @objc private func toggleFocusOnVoice() {
        controller.setAmbientFocusOnVoice(focusOnVoiceMenuItem.state != .on)
    }

    private func refreshVolumeItem(reachable: Bool) {
        if reachable, let vol = volumeController.currentVolume() {
            volumeSlider.floatValue = vol
            volumeMenuItem.isHidden = false
        } else {
            volumeMenuItem.isHidden = true
        }
    }

    // MARK: - Click routing

    @objc private func handleClick(_ sender: Any?) {
        showMenu()
    }

    private func showMenu() {
        statusItem.menu = popupMenu
        statusItem.button?.performClick(nil)
    }

    func menuWillOpen(_ menu: NSMenu) {
        // Counts as user activity — wakes the RFCOMM channel if the
        // policy had idle-disconnected it.
        controller.userActivity()
        // Pull the live output volume right before the menu is shown.
        refreshVolumeItem(reachable: controller.state.deviceReachable)
    }

    func menuDidClose(_ menu: NSMenu) {
        // Detach the menu so the next click is routed through our action
        // handler again (otherwise NSStatusItem auto-shows the menu on
        // every click).
        DispatchQueue.main.async { [weak self] in
            self?.statusItem.menu = nil
        }
    }

    // MARK: - State → UI

    private func render(state: HeadphonesController.State) {
        statusMenuItem.title = state.statusDescription
        updateAutoOffSubmenu(state: state)

        // Default: the icon stays put and dims while the headphones are
        // unreachable — Quit has to stay clickable since there's no Dock icon.
        // Hiding the icon entirely is opt-in (defaults write com.tanat.sonyconnect
        // HideIconWhenDisconnected -bool YES, or the toggle below): it looks
        // tidier, but while hidden the app is only reachable again by
        // reconnecting the headphones or flipping the default back.
        hideIconMenuItem.state = Self.hideIconWhenDisconnected ? .on : .off
        if Self.hideIconWhenDisconnected {
            statusItem.isVisible = state.deviceReachable
            statusItem.button?.appearsDisabled = false
        } else {
            statusItem.isVisible = true
            statusItem.button?.appearsDisabled = !state.deviceReachable
        }

        if let level = state.batteryLevel {
            let suffix = state.batteryCharging ? " (charging)" : ""
            batteryMenuItem.title = "Battery: \(level)%\(suffix)"
            statusItem.button?.title = "\(level)%"
            batteryMenuItem.isHidden = false
        } else {
            batteryMenuItem.isHidden = true
            statusItem.button?.title = ""
        }

        // Hide the volume slider when the headphones aren't reachable.
        // (The live value is pulled in menuWillOpen so we don't fight a
        // user mid-drag with a stray state update.)
        if !state.deviceReachable {
            volumeMenuItem.isHidden = true
        }

        // Equalizer (only once the device has reported its preset list)
        if state.isConnected && !state.eqPresets.isEmpty {
            updateEqSubmenu(presets: state.eqPresets, current: state.eqCurrentPresetId)
            let currentName = state.eqPresets.first { $0.id == state.eqCurrentPresetId }?.name ?? "—"
            eqPresetMenuItem.title = "Equalizer: \(currentName)"
            eqPresetMenuItem.isHidden = false
            eqView.setBands(state.eqBands)
        } else {
            eqPresetMenuItem.isHidden = true
        }

        if !state.isConnected {
            ncParentMenuItem.title = "Noise Cancelling: —"
            ncParentMenuItem.isEnabled = false
            ambientSettingsMenuItem.isEnabled = false
            focusOnVoiceMenuItem.isEnabled = false
            speakToChatMenuItem.title = "Speak-to-Chat: —"
            speakToChatMenuItem.state = .off
            speakToChatMenuItem.isEnabled = false
            powerOffMenuItem.isEnabled = false
            return
        }
        powerOffMenuItem.isEnabled = true


        // Noise Cancelling submenu
        ncParentMenuItem.isEnabled = true
        let ncLabel: String
        switch state.ncMode {
        case .some(.noiseCancelling): ncLabel = "ON"
        case .some(.ambient): ncLabel = "Ambient"
        case .some(.off): ncLabel = "Off"
        case .none: ncLabel = "…"
        }
        ncParentMenuItem.title = "Noise Cancelling: \(ncLabel)"
        ncOnItem.state = state.ncMode == .noiseCancelling ? .on : .off
        ncAmbientItem.state = state.ncMode == .ambient ? .on : .off
        ncOffItem.state = state.ncMode == .off ? .on : .off

        // Ambient Sound settings (level slider + Focus on Voice) only make
        // sense while Ambient mode is actually active on the device.
        let ambientActive = state.ncMode == .ambient
        ambientSettingsMenuItem.isEnabled = ambientActive
        ambientLevelSlider.integerValue = state.ambientLevel
        focusOnVoiceMenuItem.isEnabled = ambientActive
        focusOnVoiceMenuItem.state = state.ambientFocusOnVoice ? .on : .off

        // Speak-to-Chat
        speakToChatMenuItem.isEnabled = state.speakToChatEnabled != nil
        switch state.speakToChatEnabled {
        case .some(true):
            speakToChatMenuItem.title = "Speak-to-Chat: ON"
            speakToChatMenuItem.state = .on
        case .some(false):
            speakToChatMenuItem.title = "Speak-to-Chat: OFF"
            speakToChatMenuItem.state = .off
        case .none:
            speakToChatMenuItem.title = "Speak-to-Chat: …"
            speakToChatMenuItem.state = .off
        }
    }

    // MARK: - Menu actions


    @objc private func setNCFromMenu(_ sender: NSMenuItem) {
        let mode: HeadphonesController.NCMode
        switch sender.tag {
        case 0: mode = .noiseCancelling
        case 1: mode = .ambient
        default: mode = .off
        }
        controller.setNCMode(mode)
    }

    @objc private func toggleSpeakToChat() {
        controller.toggleSpeakToChat()
    }

    private func updateEqSubmenu(presets: [HeadphonesController.EqPreset], current: UInt8?) {
        if !eqSubmenuBuilt {
            eqSubmenuBuilt = true
            eqPresetSubmenu.removeAllItems()
            eqPresetSubmenu.addItem(eqPresetListItem)   // custom preset rows
            eqPresetSubmenu.addItem(.separator())
            eqPresetSubmenu.addItem(eqBandsMenuItem)    // custom band sliders
        }
        eqPresetListView.setPresets(presets, current: current)
    }

    // Rebuilt on demand: "When taken off" only exists on v2, so the option
    // list depends on the connected device.
    private func updateAutoOffSubmenu(state: HeadphonesController.State) {
        let options = AutoPowerOffOption.selectable
        if autoOffSubmenu.items.count != options.count {
            autoOffSubmenu.removeAllItems()
            for option in options {
                let item = NSMenuItem(title: option.title,
                                      action: #selector(setAutoOffFromMenu(_:)),
                                      keyEquivalent: "")
                item.target = self
                item.tag = option.rawValue
                autoOffSubmenu.addItem(item)
            }
        }
        for item in autoOffSubmenu.items {
            item.state = item.tag == state.autoOffOption.rawValue ? .on : .off
        }
        autoOffMenuItem.title = state.autoOffOption == .off
            ? "Auto Power Off: Off"
            : "Auto Power Off: \(state.autoOffOption.title)"
    }

    @objc private func setAutoOffFromMenu(_ sender: NSMenuItem) {
        guard let option = AutoPowerOffOption(rawValue: sender.tag) else { return }
        controller.autoOffOption = option
    }

    @objc private func powerOff() {
        controller.powerOff()
    }

    @objc private func reconnect() {
        controller.connect()
    }

    @objc private func toggleHideIcon() {
        Self.hideIconWhenDisconnected.toggle()
        render(state: controller.state)
    }

    @objc private func openLog() {
        NSWorkspace.shared.activateFileViewerSelecting([FileLogger.shared.url])
    }
}
