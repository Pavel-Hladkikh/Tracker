import UIKit
import CoreData

final class StatisticsViewController: UIViewController {
    
    private let titleLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.text = NSLocalizedString("statistics_title", comment: "Статистика")
        l.font = UIFont.systemFont(ofSize: 34, weight: .bold)
        l.textColor = Colors.baseInverse
        return l
    }()
    
    private let cardView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = Colors.base
        v.layer.cornerRadius = 16
        v.layer.masksToBounds = true
        return v
    }()
    
    private let valueLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = UIFont.systemFont(ofSize: 34, weight: .bold)
        l.textColor = Colors.baseInverse
        l.text = "0"
        return l
    }()
    
    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        l.textColor = Colors.baseInverse
        l.text = NSLocalizedString("statistics_completed_subtitle",
                                   comment: "Трекеров завершено")
        return l
    }()
    
    private let gradientLayer: CAGradientLayer = {
        let gr = CAGradientLayer()
        gr.colors = [
            UIColor.hex("#FD4C49").cgColor,
            UIColor.hex("#FF881E").cgColor,
            UIColor.hex("#007BFA").cgColor
        ]
        gr.startPoint = CGPoint(x: 0, y: 0.5)
        gr.endPoint = CGPoint(x: 1, y: 0.5)
        return gr
    }()
    
    private let gradientMask = CAShapeLayer()
    
    private let emptyImageView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFit
        iv.image = UIImage(named: "stat")
        return iv
    }()
    
    private let emptyLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.textAlignment = .center
        l.numberOfLines = 0
        l.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        l.textColor = Colors.baseInverse
        l.text = NSLocalizedString("statistics_empty_title",
                                   comment: "Анализировать пока нечего")
        return l
    }()
    
    private var completedCount: Int = 0 {
        didSet { updateState() }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Colors.base
        setupLayout()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadStatistics()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        layoutGradient()
    }
    
    private func setupLayout() {
        view.addSubview(titleLabel)
        view.addSubview(cardView)
        view.addSubview(emptyImageView)
        view.addSubview(emptyLabel)
        
        cardView.layer.addSublayer(gradientLayer)
        gradientLayer.mask = gradientMask
        
        cardView.addSubview(valueLabel)
        cardView.addSubview(subtitleLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 88),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -16),
            
            cardView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 77),
            cardView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            cardView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            cardView.heightAnchor.constraint(equalToConstant: 90),
            
            valueLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 12),
            valueLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 12),
            valueLabel.trailingAnchor.constraint(lessThanOrEqualTo: cardView.trailingAnchor, constant: -12),
            
            subtitleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 12),
            subtitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: cardView.trailingAnchor, constant: -12),
            subtitleLabel.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -12),
            
            emptyImageView.widthAnchor.constraint(equalToConstant: 80),
            emptyImageView.heightAnchor.constraint(equalToConstant: 80),
            emptyImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyImageView.topAnchor.constraint(equalTo: view.topAnchor, constant: 375),
            
            emptyLabel.topAnchor.constraint(equalTo: emptyImageView.bottomAnchor, constant: 8),
            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    private func layoutGradient() {
        gradientLayer.frame = cardView.bounds
        
        let path = UIBezierPath(
            roundedRect: cardView.bounds.insetBy(dx: 0.5, dy: 0.5),
            cornerRadius: 16
        ).cgPath
        
        gradientMask.path = path
        gradientMask.lineWidth = 1
        gradientMask.fillColor = UIColor.clear.cgColor
        gradientMask.strokeColor = Colors.baseInverse.cgColor
    }
    
    private func reloadStatistics() {
        let context = CoreDataStack.shared.context
        let request: NSFetchRequest<TrackerRecordCoreData> = TrackerRecordCoreData.fetchRequest()
        let count = (try? context.count(for: request)) ?? 0
        completedCount = count
    }
    
    private func updateState() {
        valueLabel.text = "\(completedCount)"
        
        let hasData = completedCount > 0
        
        cardView.isHidden = !hasData
        valueLabel.isHidden = !hasData
        subtitleLabel.isHidden = !hasData
        
        emptyImageView.isHidden = hasData
        emptyLabel.isHidden = hasData
    }
}
