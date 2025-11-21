import UIKit

final class TabBarController: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabs()
        configureTabBarAppearance()
    }
    
    private func setupTabs() {
        let trackers = TrackersViewController()
        let trackersNav = UINavigationController(rootViewController: trackers)
        trackersNav.navigationBar.prefersLargeTitles = true
        trackers.tabBarItem = UITabBarItem(
            title: NSLocalizedString("trackers_title", comment: ""),
            image: UIImage(systemName: "record.circle"),
            selectedImage: UIImage(systemName: "record.circle.fill")
        )
        
        let statistics = StatisticsViewController()
        let statisticsNav = UINavigationController(rootViewController: statistics)
        statisticsNav.navigationBar.prefersLargeTitles = true
        statistics.tabBarItem = UITabBarItem(
            title: NSLocalizedString("statistics_title", comment: ""),
            image: UIImage(systemName: "hare.fill"),
            selectedImage: UIImage(systemName: "hare.fill")
        )
        
        viewControllers = [trackersNav, statisticsNav]
    }
    
    private func configureTabBarAppearance() {
        let selectedColor = UIColor.hex("#3772E7")
        let normalColor = UIColor.hex("#AEAFB4")
        let titleFont = UIFont.systemFont(ofSize: 10, weight: .medium)
        
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = Colors.base
        
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: selectedColor,
            .font: titleFont
        ]
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: normalColor,
            .font: titleFont
        ]
        
        tabBar.tintColor = selectedColor
        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance
    }
}
