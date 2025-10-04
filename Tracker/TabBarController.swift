import UIKit

extension UIColor {
    convenience init?(hexString: String, alpha: CGFloat = 1.0) {
        var cleaned = hexString.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if cleaned.hasPrefix("#") { cleaned.removeFirst() }
        guard cleaned.count == 6, let value = UInt32(cleaned, radix: 16) else { return nil }
        let r = CGFloat((value & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((value & 0x00FF00) >>  8) / 255.0
        let b = CGFloat((value & 0x0000FF)      ) / 255.0
        self.init(red: r, green: g, blue: b, alpha: alpha)
    }
    static func hex(_ hex: String, alpha: CGFloat = 1.0, fallback: UIColor = .clear) -> UIColor {
        UIColor(hexString: hex, alpha: alpha) ?? fallback
    }
}

final class TabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        configureTabBarAppearance()
        setupTabs()
    }

    private func setupTabs() {
        let trackers = TrackersViewController()
        let trackersNav = UINavigationController(rootViewController: trackers)
        trackersNav.navigationBar.prefersLargeTitles = true  
        trackers.title = "Трекеры"
        trackers.tabBarItem = UITabBarItem(
            title: "Трекеры",
            image: UIImage(systemName: "record.circle"),
            selectedImage: UIImage(systemName: "record.circle.fill")
        )

        let statistics = StatisticsViewController()
        let statisticsNav = UINavigationController(rootViewController: statistics)
        statisticsNav.navigationBar.prefersLargeTitles = true
        statistics.title = "Статистика"
        statistics.tabBarItem = UITabBarItem(
            title: "Статистика",
            image: UIImage(systemName: "hare.fill"),
            selectedImage: UIImage(systemName: "hare.fill")
        )

        viewControllers = [trackersNav, statisticsNav]
    }

    private func configureTabBarAppearance() {
        let selectedColor = UIColor.hex("#3772E7")
        let normalColor   = UIColor.hex("#AEAFB4")
        let titleFont = UIFont.systemFont(ofSize: 10, weight: .medium)

        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .white

        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: selectedColor, .font: titleFont]
        appearance.stackedLayoutAppearance.normal.titleTextAttributes   = [.foregroundColor: normalColor,   .font: titleFont]
        appearance.inlineLayoutAppearance.selected.titleTextAttributes  = appearance.stackedLayoutAppearance.selected.titleTextAttributes
        appearance.inlineLayoutAppearance.normal.titleTextAttributes    = appearance.stackedLayoutAppearance.normal.titleTextAttributes
        appearance.compactInlineLayoutAppearance.selected.titleTextAttributes = appearance.stackedLayoutAppearance.selected.titleTextAttributes
        appearance.compactInlineLayoutAppearance.normal.titleTextAttributes   = appearance.stackedLayoutAppearance.normal.titleTextAttributes

        tabBar.tintColor = selectedColor
        tabBar.unselectedItemTintColor = normalColor
        tabBar.standardAppearance = appearance
        if #available(iOS 15.0, *) {
            tabBar.scrollEdgeAppearance = appearance
        }
    }
}




