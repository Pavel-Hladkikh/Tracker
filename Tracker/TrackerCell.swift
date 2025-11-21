import UIKit

protocol TrackerCellDelegate: AnyObject {
    func trackerCellDidToggle(_ cell: TrackerCell)
}

final class TrackerCell: UICollectionViewCell {
    
    static let reuseIdentifier = "TrackerCell"
    weak var delegate: TrackerCellDelegate?
    
    let cardContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 16
        view.layer.masksToBounds = true
        return view
    }()
    
    private let emojiBackgroundView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .white.withAlphaComponent(0.3)
        view.layer.cornerRadius = 12
        view.layer.masksToBounds = true
        return view
    }()
    
    private let emojiLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.text = "🙂"
        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.7
        label.baselineAdjustment = .alignCenters
        return label
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 2
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        label.textColor = .white
        return label
    }()
    
    private let toggleButton: UIButton = {
        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.cornerRadius = 17
        button.layer.masksToBounds = true
        button.backgroundColor = .clear
        button.tintColor = Colors.base
        button.imageView?.contentMode = .scaleAspectFit
        button.accessibilityLabel = NSLocalizedString("mark_done_action", comment: "")
        return button
    }()
    
    private let counterLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        let normalColor = Colors.baseInverse
        label.text = String.localizedStringWithFormat(NSLocalizedString("days_format", comment: ""),0)
        return label
    }()
    
    private var trackerIdentifier: UUID?
    private var trackerColor: UIColor = .systemGreen
    private let completedAlpha: CGFloat = 0.28
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .clear
        buildLayout()
        toggleButton.addTarget(self, action: #selector(toggleTapped), for: .touchUpInside)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func buildLayout() {
        contentView.addSubview(cardContainerView)
        cardContainerView.addSubview(emojiBackgroundView)
        cardContainerView.addSubview(emojiLabel)
        cardContainerView.addSubview(nameLabel)
        contentView.addSubview(counterLabel)
        contentView.addSubview(toggleButton)
        
        NSLayoutConstraint.activate([
            cardContainerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            cardContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            cardContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            cardContainerView.heightAnchor.constraint(equalToConstant: 90),
            
            emojiBackgroundView.topAnchor.constraint(equalTo: cardContainerView.topAnchor, constant: 12),
            emojiBackgroundView.leadingAnchor.constraint(equalTo: cardContainerView.leadingAnchor, constant: 12),
            emojiBackgroundView.widthAnchor.constraint(equalToConstant: 24),
            emojiBackgroundView.heightAnchor.constraint(equalToConstant: 24),
            
            emojiLabel.centerXAnchor.constraint(equalTo: emojiBackgroundView.centerXAnchor),
            emojiLabel.centerYAnchor.constraint(equalTo: emojiBackgroundView.centerYAnchor),
            emojiLabel.widthAnchor.constraint(equalToConstant: 16),
            emojiLabel.heightAnchor.constraint(equalToConstant: 22),
            
            nameLabel.leadingAnchor.constraint(equalTo: cardContainerView.leadingAnchor, constant: 12),
            nameLabel.trailingAnchor.constraint(equalTo: cardContainerView.trailingAnchor, constant: -12),
            nameLabel.bottomAnchor.constraint(equalTo: cardContainerView.bottomAnchor, constant: -12),
            
            counterLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            counterLabel.topAnchor.constraint(equalTo: cardContainerView.bottomAnchor, constant: 16),
            
            toggleButton.topAnchor.constraint(equalTo: cardContainerView.bottomAnchor, constant: 8),
            toggleButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            toggleButton.widthAnchor.constraint(equalToConstant: 34),
            toggleButton.heightAnchor.constraint(equalToConstant: 34)
        ])
    }
    
    @objc private func toggleTapped() {
        delegate?.trackerCellDidToggle(self)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        toggleButton.alpha = 1
        toggleButton.setImage(nil, for: .normal)
        toggleButton.backgroundColor = .clear
    }
    
    func configure(tracker: Tracker, isCompleted: Bool, totalCompletions: Int) {
        trackerIdentifier = tracker.id
        trackerColor = tracker.color
        
        cardContainerView.backgroundColor = trackerColor
        emojiLabel.text = tracker.emoji.isEmpty ? "🙂" : tracker.emoji
        nameLabel.text = tracker.name
        applyToggleAppearance(isCompleted: isCompleted)
        counterLabel.text = String.localizedStringWithFormat(NSLocalizedString("days_format", comment: ""), totalCompletions)
    }
    
    func currentTrackerId() -> UUID? {
        trackerIdentifier
    }
    
    private func applyToggleAppearance(isCompleted: Bool) {
        let cfg = UIImage.SymbolConfiguration(pointSize: 16, weight: .bold)
        let plus = UIImage(systemName: "plus")!.applyingSymbolConfiguration(cfg)!
            .withTintColor(Colors.base, renderingMode: .alwaysOriginal)
        let check = UIImage(systemName: "checkmark")!.applyingSymbolConfiguration(cfg)!
            .withTintColor(Colors.base, renderingMode: .alwaysOriginal)
        
        toggleButton.backgroundColor = isCompleted
        ? trackerColor.withAlphaComponent(completedAlpha)
        : trackerColor
        
        toggleButton.setImage(isCompleted ? check : plus, for: .normal)
        toggleButton.tintColor = Colors.base
        toggleButton.imageView?.tintColor = Colors.base
        toggleButton.accessibilityLabel = isCompleted
        ? NSLocalizedString("unmark_action", comment: "")
        : NSLocalizedString("mark_done_action", comment: "")
    }
}
