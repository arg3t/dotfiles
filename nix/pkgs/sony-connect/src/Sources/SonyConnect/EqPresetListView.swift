import AppKit

// A vertical list of EQ-preset rows used as a custom menu-item view.
// Unlike native NSMenuItems, clicking a custom view does not dismiss the
// enclosing menu — so the user can audition presets without it closing.
final class EqPresetListView: NSView {
    var onSelect: ((UInt8) -> Void)?

    private var rows: [PresetRowView] = []
    private let rowHeight: CGFloat = 20

    init() {
        super.init(frame: NSRect(x: 0, y: 0, width: 230, height: rowHeight))
        autoresizingMask = [.width]
    }

    required init?(coder: NSCoder) { fatalError("not implemented") }

    func setPresets(_ presets: [HeadphonesController.EqPreset], current: UInt8?) {
        let ids = presets.map { $0.id }
        if ids != rows.map({ $0.presetId }) {
            rows.forEach { $0.removeFromSuperview() }
            rows = presets.map { preset in
                let row = PresetRowView(id: preset.id, title: preset.name)
                row.onClick = { [weak self] id in self?.onSelect?(id) }
                addSubview(row)
                return row
            }
            setFrameSize(NSSize(width: frame.width, height: CGFloat(rows.count) * rowHeight))
            needsLayout = true
        }
        for row in rows {
            row.isChecked = (row.presetId == current)
            row.needsDisplay = true
        }
    }

    override func layout() {
        super.layout()
        for (i, row) in rows.enumerated() {
            row.frame = NSRect(x: 0,
                               y: bounds.height - CGFloat(i + 1) * rowHeight,
                               width: bounds.width,
                               height: rowHeight)
        }
    }
}

private final class PresetRowView: NSView {
    let presetId: UInt8
    var onClick: ((UInt8) -> Void)?
    var isChecked = false

    private let title: String
    private var hovered = false
    private var trackingAreaRef: NSTrackingArea?

    init(id: UInt8, title: String) {
        self.presetId = id
        self.title = title
        super.init(frame: .zero)
        autoresizingMask = [.width]
    }

    required init?(coder: NSCoder) { fatalError("not implemented") }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let existing = trackingAreaRef { removeTrackingArea(existing) }
        let area = NSTrackingArea(rect: bounds,
                                  options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
                                  owner: self, userInfo: nil)
        addTrackingArea(area)
        trackingAreaRef = area
    }

    override func mouseEntered(with event: NSEvent) { hovered = true; needsDisplay = true }
    override func mouseExited(with event: NSEvent) { hovered = false; needsDisplay = true }

    override func mouseUp(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        if bounds.contains(point) { onClick?(presetId) }
    }

    override func draw(_ dirtyRect: NSRect) {
        let textColor: NSColor
        if hovered {
            NSColor.selectedContentBackgroundColor.setFill()
            bounds.fill()
            textColor = .selectedMenuItemTextColor
        } else {
            textColor = .labelColor
        }

        let font = NSFont.menuFont(ofSize: 0)
        let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: textColor]
        let textY = (bounds.height - font.ascender + font.descender) / 2

        if isChecked {
            ("✓" as NSString).draw(at: NSPoint(x: 8, y: textY), withAttributes: attrs)
        }
        (title as NSString).draw(at: NSPoint(x: 24, y: textY), withAttributes: attrs)
    }
}
