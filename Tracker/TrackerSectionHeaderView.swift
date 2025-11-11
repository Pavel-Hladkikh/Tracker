import UIKit

final class TrackerSectionHeaderView: UICollectionReusableView {
    
    static let reuseIdentifier = "TrackerSectionHeaderView"
    
    private enum Layout {
        static let titleLeading: CGFloat = 28
        static let titleTrailing: CGFloat = 16
        static let topPadding: CGFloat = 4
        static let bottomPadding: CGFloat = 0
    }
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 19, weight: .bold)
        label.textColor = .label
        label.numberOfLines = 1
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Layout.titleLeading),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Layout.titleTrailing),
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: Layout.topPadding),
            titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Layout.bottomPadding)
        ])
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    func setTitle(_ text: String) {
        titleLabel.text = text
    }
    
    
    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes)
    -> UICollectionViewLayoutAttributes {
        setNeedsLayout()
        layoutIfNeeded()
        let target = CGSize(width: layoutAttributes.size.width,
                            height: UIView.layoutFittingCompressedSize.height)
        let size = systemLayoutSizeFitting(
            target,
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        layoutAttributes.size.height = ceil(size.height)
        return layoutAttributes
    }
}
