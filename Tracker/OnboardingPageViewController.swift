import UIKit

final class OnboardingPageViewController: UIViewController {
    private let pages: [OnboardingPage] = [
        OnboardingPage(backgroundImageName: "backOne", titleKey: "onboarding_title_1"),
        OnboardingPage(backgroundImageName: "backTwo", titleKey: "onboarding_title_2")
    ]
    
    private lazy var pageViewController: UIPageViewController = {
        let pvc = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)
        pvc.dataSource = self
        pvc.delegate = self
        return pvc
    }()
    
    private var contentControllers: [OnboardingContentViewController] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        setupPageViewController()
        preloadPages()
        if let first = contentControllers.first {
            pageViewController.setViewControllers([first], direction: .forward, animated: false)
        }
    }
    
    private func setupPageViewController() {
        addChild(pageViewController)
        pageViewController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pageViewController.view)
        pageViewController.didMove(toParent: self)
        
        NSLayoutConstraint.activate([
            pageViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            pageViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pageViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pageViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func preloadPages() {
        contentControllers = pages.enumerated().map { index, page in
            let vc = OnboardingContentViewController(page: page, index: index, totalPages: pages.count)
            vc.delegate = self
            vc.view.tag = index
            vc.loadViewIfNeeded()
            return vc
        }
    }
}

extension OnboardingPageViewController: UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    func pageViewController(_ pvc: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        let idx = viewController.view.tag
        let before = idx - 1
        guard before >= 0 else { return nil }
        return contentControllers[before]
    }
    
    func pageViewController(_ pvc: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        let idx = viewController.view.tag
        let after = idx + 1
        guard after < contentControllers.count else { return nil }
        return contentControllers[after]
    }
    
    func pageViewController(_ pvc: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        guard completed, let current = pvc.viewControllers?.first as? OnboardingContentViewController else { return }
        current.setCurrentPage(current.view.tag)
    }
}

extension OnboardingPageViewController: OnboardingContentDelegate {
    func onboardingDidTapAction(from index: Int) {
        UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
        dismiss(animated: true, completion: nil)
    }
}
