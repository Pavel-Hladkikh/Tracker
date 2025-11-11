import UIKit
final class CategoryCell: UITableViewCell {
    
    static let reuseIdentifier = "CategoryCell"
    
    private let titleLabel = UILabel()
    private let checkmarkView: UIImageView = {
        let img = UIImageView(image: UIImage(systemName: "checkmark"))
        img.tintColor = UIColor.systemBlue
        img.isHidden = true
        img.translatesAutoresizingMaskIntoConstraints = false
        return img
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        backgroundColor = .clear
        contentView.backgroundColor = UIColor.hex("#E6E8EB", alpha: 0.3)
        contentView.layer.masksToBounds = true
        
        titleLabel.font = .systemFont(ofSize: 17)
        titleLabel.textColor = UIColor.hex("#1A1B22")
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(titleLabel)
        contentView.addSubview(checkmarkView)
        
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            checkmarkView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            checkmarkView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(title: String, isSelected: Bool) {
        titleLabel.text = title
        checkmarkView.isHidden = !isSelected
    }
    
    func updateCorners(for row: Int, totalRows: Int) {
        let radius: CGFloat = 16
        var mask: CACornerMask = []
        
        if totalRows == 1 {
            mask = [.layerMinXMinYCorner, .layerMaxXMinYCorner,
                    .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        } else if row == 0 {
            mask = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        } else if row == totalRows - 1 {
            mask = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        } else {
            mask = []
        }
        
        contentView.layer.cornerRadius = mask.isEmpty ? 0 : radius
        contentView.layer.maskedCorners = mask
    }
}
