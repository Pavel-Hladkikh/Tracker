import Foundation
import AppMetricaCore

enum AnalyticsEventType: String {
    case open
    case close
    case click
}

enum AnalyticsScreen: String {
    case main = "Main"
}

enum AnalyticsItem: String {
    case addTrack = "add_track"
    case track = "track"
    case filter = "filter"
    case edit = "edit"
    case delete = "delete"
}

final class AnalyticsService {
    
    static let shared = AnalyticsService()
    private init() {}
    
    func track(
        event: AnalyticsEventType,
        screen: AnalyticsScreen,
        item: AnalyticsItem? = nil
    ) {
        var params: [String: Any] = [
            "event": event.rawValue,
            "screen": screen.rawValue
        ]
        
        if let item = item {
            params["item"] = item.rawValue
        }
        
        print("Analytics -> event: \(event.rawValue), screen: \(screen.rawValue), item: \(item?.rawValue ?? "nil")")
        
        AppMetrica.reportEvent(
            name: "ui_event",
            parameters: params,
            onFailure: { error in
                print("Analytics error: \(error.localizedDescription)")
            }
        )
    }
}
