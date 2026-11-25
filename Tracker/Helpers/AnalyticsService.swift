import AppMetricaCore
import Foundation

enum AnalyticsService {
    enum MainEvent {
        case open
        case close
        case click(MainItem)
    }

    enum MainItem: String {
        case addTrack = "add_track"
        case track
        case filter
        case edit
        case delete
    }

    private static let apiKey = "6f3b2a1c-8d4e-4f5a-9b7c-1a2b3c4d5e6f"

    static func report(_ event: MainEvent) {
        switch event {
        case .open:
            report(event: "open", screen: "Main")
        case .close:
            report(event: "close", screen: "Main")
        case .click(let item):
            report(event: "click", screen: "Main", item: item.rawValue)
        }
    }

    static func activate() {
        guard let configuration = AppMetricaConfiguration(apiKey: apiKey) else { return }
        configuration.locationTracking = false
        configuration.advertisingIdentifierTrackingEnabled = false
        AppMetrica.activate(with: configuration)
    }

    static func report(event: String, screen: String, item: String? = nil) {
        var parameters: [AnyHashable: Any] = [
            "event": event,
            "screen": screen
        ]
        if let item {
            parameters["item"] = item
        }
        print("analytics \(parameters)")
        guard AppMetrica.isActivated else { return }
        AppMetrica.reportEvent(name: event, parameters: parameters) { error in
            print("analytics error \(error.localizedDescription)")
        }
    }
}
