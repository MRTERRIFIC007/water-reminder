import CoreLocation
import Foundation

@Observable
final class WeatherManager: NSObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    private var location: CLLocation?
    private var locationContinuations: [CheckedContinuation<CLLocation?, Never>] = []

    var data = WeatherData()
    var isAuthorized = false

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func requestAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }

    /// Get location, waiting if needed, then fetch weather from Open-Meteo (free, no API key).
    func fetch() async {
        let loc = await resolveLocation()

        guard let loc else {
            print("Weather: no location available")
            return
        }

        let lat = loc.coordinate.latitude
        let lon = loc.coordinate.longitude
        let urlString = "https://api.open-meteo.com/v1/forecast?latitude=\(lat)&longitude=\(lon)&current=temperature_2m,relative_humidity_2m&daily=temperature_2m_max&timezone=auto&forecast_days=1"

        guard let url = URL(string: urlString) else {
            print("Weather: invalid URL")
            return
        }

        do {
            let (responseData, _) = try await URLSession.shared.data(from: url)
            let json = try JSONSerialization.jsonObject(with: responseData) as? [String: Any]

            if let current = json?["current"] as? [String: Any] {
                data.currentTemp = Int((current["temperature_2m"] as? Double) ?? 0)
                data.humidity = Int((current["relative_humidity_2m"] as? Double) ?? 0)
            }

            if let daily = json?["daily"] as? [String: Any],
               let maxTemps = daily["temperature_2m_max"] as? [Double],
               let highTemp = maxTemps.first {
                data.highTemp = Int(highTemp)
            }

            data.lastSync = Date()
        } catch {
            print("Weather fetch failed: \(error)")
        }
    }

    // MARK: - Location

    private func resolveLocation() async -> CLLocation? {
        // Use cached location if fresh (< 30 min old)
        if let loc = location,
           Date().timeIntervalSince(loc.timestamp) < 1800 {
            return loc
        }

        // Try system's last known location
        if let cached = locationManager.location,
           Date().timeIntervalSince(cached.timestamp) < 1800 {
            location = cached
            return cached
        }

        // Need a fresh location — request one and wait
        let status = locationManager.authorizationStatus
        guard status == .authorizedWhenInUse || status == .authorizedAlways else {
            print("Weather: location not authorized (status: \(status.rawValue))")
            return nil
        }

        return await withCheckedContinuation { continuation in
            locationContinuations.append(continuation)
            locationManager.requestLocation()
        }
    }

    private func resumeAllContinuations(with loc: CLLocation?) {
        let pending = locationContinuations
        locationContinuations.removeAll()
        for continuation in pending {
            continuation.resume(returning: loc)
        }
    }

    // MARK: - CLLocationManagerDelegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            isAuthorized = true
        default:
            isAuthorized = false
            resumeAllContinuations(with: nil)
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.first else { return }
        location = loc
        resumeAllContinuations(with: loc)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error)")
        resumeAllContinuations(with: nil)
    }
}
