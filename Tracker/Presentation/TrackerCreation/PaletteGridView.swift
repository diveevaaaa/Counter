import UIKit

final class PaletteGridView: UIView {
    enum Style {
        case emoji
        case color
    }

    var onSelect: ((Int) -> Void)?

    private let style: Style
    private let columns = 6
    private let spacing: CGFloat = 5
    private var selectedIndex: Int?
    private var buttons: [UIButton] = []
    private var colorDots: [UIView] = []
    private var heightConstraint: NSLayoutConstraint?

    init(style: Style) {
        self.style = style
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        let count = style == .emoji ? TrackerPalette.emojis.count : TrackerPalette.colors.count
        for index in 0..<count {
            let button = UIButton(type: .custom)
            button.tag = index
            button.addTarget(self, action: #selector(tapped(_:)), for: .touchUpInside)
            if style == .emoji {
                button.setTitle(TrackerPalette.emojis[index], for: .normal)
                button.titleLabel?.font = .systemFont(ofSize: 32)
            } else {
                let dot = UIView()
                dot.backgroundColor = TrackerPalette.colors[index]
                dot.isUserInteractionEnabled = false
                button.addSubview(dot)
                colorDots.append(dot)
            }
            addSubview(button)
            buttons.append(button)
        }
        let constraint = heightAnchor.constraint(equalToConstant: 160)
        constraint.isActive = true
        heightConstraint = constraint
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func select(index: Int) {
        selectedIndex = index
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard bounds.width > 0 else { return }
        let rows = Int(ceil(Double(buttons.count) / Double(columns)))
        let cell = floor((bounds.width - spacing * CGFloat(columns - 1)) / CGFloat(columns))
        guard cell > 0 else { return }
        for (index, button) in buttons.enumerated() {
            let row = index / columns
            let column = index % columns
            button.frame = CGRect(
                x: CGFloat(column) * (cell + spacing),
                y: CGFloat(row) * (cell + spacing),
                width: cell,
                height: cell
            )
            button.layer.cornerRadius = cell / 2
            button.clipsToBounds = true
            let isSelected = index == selectedIndex
            switch style {
            case .emoji:
                button.backgroundColor = isSelected ? .ypBackground : .clear
            case .color:
                let color = TrackerPalette.colors[index]
                button.backgroundColor = .clear
                button.layer.borderWidth = isSelected ? 3 : 0
                button.layer.borderColor = color.withAlphaComponent(0.3).cgColor
                let dotSide = max(cell - 12, 1)
                let dot = colorDots[index]
                dot.frame = CGRect(x: (cell - dotSide) / 2, y: (cell - dotSide) / 2, width: dotSide, height: dotSide)
                dot.layer.cornerRadius = dotSide / 2
            }
        }
        let height = CGFloat(rows) * cell + CGFloat(max(rows - 1, 0)) * spacing
        if let heightConstraint, abs(heightConstraint.constant - height) > 0.5 {
            heightConstraint.constant = height
        }
    }

    @objc private func tapped(_ sender: UIButton) {
        selectedIndex = sender.tag
        setNeedsLayout()
        onSelect?(sender.tag)
    }
}
