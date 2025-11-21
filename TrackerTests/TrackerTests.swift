import XCTest
import SnapshotTesting
@testable import Tracker

final class TrackerScreenshotTests: XCTestCase {
    
    
    private func makeTabController() -> TabBarController {
        let tab = TabBarController()
        tab.loadViewIfNeeded()
        
        if let nav = tab.viewControllers?.first as? UINavigationController {
            nav.topViewController?.loadViewIfNeeded()
            nav.topViewController?.view.layoutIfNeeded()
        }
        
        return tab
    }
    
    func testTrackersListOnWhiteTheme() {
        let tab = makeTabController()
        tab.overrideUserInterfaceStyle = .light
        
        assertSnapshot(
            of: tab,
            as: .image(traits: .init(userInterfaceStyle: .light))
        )
    }
    
    func testTrackersListOnDarkTheme() {
        let tab = makeTabController()
        tab.overrideUserInterfaceStyle = .dark
        
        assertSnapshot(
            of: tab,
            as: .image(traits: .init(userInterfaceStyle: .dark))
        )
    }
}
