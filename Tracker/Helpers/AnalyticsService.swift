import AppMetricaCore
import Foundation

enum AnalyticsService {
    private static let apiKey = "6f3b2a1c-8d4e-4f5a-9b7c-1a2b3c4d5e6f"

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
