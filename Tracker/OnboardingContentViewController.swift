import UIKit

protocol OnboardingContentDelegate: AnyObject {
    func onboardingDidTapAction(from index: Int)
}

final class OnboardingContentViewController: UIViewController {
    private let page: OnboardingPage
    private let pageIndex: Int
    private let totalPages: Int
    weak var delegate: OnboardingContentDelegate?
    
    private let backgroundImageView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        return iv
    }()
    
    let titleLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.numberOfLines = 2
        l.textAlignment = .center
        l.textColor = UIColor.hex("#1A1B22")
        l.lineBreakMode = .byWordWrapping
        l.adjustsFontSizeToFitWidth = true
        l.minimumScaleFactor = 0.85
        return l
    }()
    
    private let dotsStack: UIStackView = {
        let sv = UIStackView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.axis = .horizontal
        sv.alignment = .center
        sv.distribution = .equalSpacing
        return sv
    }()
    
    private var dotViews: [UIView] = []
    
    private let actionButton: UIButton = {
        let b = UIButton(type: .system)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.setTitle(NSLocalizedString("onboarding_button", comment: ""), for: .normal)
        b.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        b.setTitleColor(.white, for: .normal)
        b.backgroundColor = UIColor.hex("#1A1B22")
        b.layer.cornerRadius = 20
        b.layer.masksToBounds = true
        return b
    }()
    
    private let designScreenHeight: CGFloat = 812.0
    private let designTitleToBottom: CGFloat = 304.0 
    private let designTitleToDots: CGFloat = 130.0
    private let designDotsToButton: CGFloat = 24.0
    private let designFontSize: CGFloat = 32.0
    
    private var scaledTitleToBottom: CGFloat = 0
    private var scaledTitleToDots: CGFloat = 0
    private var scaledDotsToButton: CGFloat = 0
    private var scaledFontSize: CGFloat = 0
    
    
    private var titleBottomConstraint: NSLayoutConstraint!
    private var titleHeightConstraint: NSLayoutConstraint!
    
    init(page: OnboardingPage, index: Int, totalPages: Int) {
        self.page = page
        self.pageIndex = index
        self.totalPages = totalPages
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let scale = UIScreen.main.bounds.height / designScreenHeight
        scaledTitleToBottom = designTitleToBottom * scale
        scaledTitleToDots = designTitleToDots * scale
        scaledDotsToButton = designDotsToButton * scale
        scaledFontSize = designFontSize * scale
        
        setupViews()
        applyContent()
        configureDots()
        actionButton.addTarget(self, action: #selector(actionTapped), for: .touchUpInside)
    }
    
    private func setupViews() {
        view.addSubview(backgroundImageView)
        view.addSubview(titleLabel)
        view.addSubview(dotsStack)
        view.addSubview(actionButton)
        
        
        let computedLineHeight = ceil(UIFont.systemFont(ofSize: scaledFontSize, weight: .bold).lineHeight)
        let titleFixedHeight = ceil(computedLineHeight * 2.0)
        
        NSLayoutConstraint.activate([
            backgroundImageView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            dotsStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            actionButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            actionButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            actionButton.heightAnchor.constraint(equalToConstant: 60)
        ])
        
        titleHeightConstraint = titleLabel.heightAnchor.constraint(equalToConstant: titleFixedHeight)
        titleHeightConstraint.isActive = true
        
        titleBottomConstraint = titleLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -scaledTitleToBottom)
        titleBottomConstraint.isActive = true
        
        let dotsTop = dotsStack.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: scaledTitleToDots)
        dotsTop.isActive = true
        
        let buttonTop = actionButton.topAnchor.constraint(equalTo: dotsStack.bottomAnchor, constant: scaledDotsToButton)
        buttonTop.isActive = true
    }
    
    private func applyContent() {
        backgroundImageView.image = UIImage(named: page.backgroundImageName)
        
        var text = NSLocalizedString(page.titleKey, comment: "")
        if pageIndex == 1, let range = text.range(of: "не ") {
            text.replaceSubrange(range, with: "\nне ")
        }
        titleLabel.text = text
        titleLabel.font = UIFont.systemFont(ofSize: scaledFontSize, weight: .bold)
    }
    
    private func configureDots() {
        dotViews.forEach { $0.removeFromSuperview() }
        dotViews.removeAll()
        
        let dotSize: CGFloat = 8.0
        let spacing: CGFloat = 6.0
        
        for i in 0..<totalPages {
            let dot = UIView()
            dot.translatesAutoresizingMaskIntoConstraints = false
            dot.layer.cornerRadius = dotSize / 2.0
            dot.backgroundColor = (i == pageIndex) ? UIColor.hex("#1A1B22") : UIColor.hex("#AEAFB4")
            dot.widthAnchor.constraint(equalToConstant: dotSize).isActive = true
            dot.heightAnchor.constraint(equalToConstant: dotSize).isActive = true
            dotViews.append(dot)
            dotsStack.addArrangedSubview(dot)
            
            if i < totalPages - 1 {
                let spacer = UIView()
                spacer.translatesAutoresizingMaskIntoConstraints = false
                spacer.widthAnchor.constraint(equalToConstant: spacing).isActive = true
                dotsStack.addArrangedSubview(spacer)
            }
        }
    }
    
    func setCurrentPage(_ value: Int) {
        guard value >= 0, value < dotViews.count else { return }
        for (i, v) in dotViews.enumerated() {
            v.backgroundColor = (i == value) ? UIColor.hex("#1A1B22") : UIColor.hex("#AEAFB4")
        }
    }
    
    @objc private func actionTapped() {
        delegate?.onboardingDidTapAction(from: pageIndex)
    }
    
    func setTitleBottomDistance(_ distance: CGFloat) {
        titleBottomConstraint.constant = -distance
        view.layoutIfNeeded()
    }
}
