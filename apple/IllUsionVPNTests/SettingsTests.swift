import XCTest
@testable import IllUsionVPN

final class SettingsTests: XCTestCase {
    func testDefaultsAreSecureByDefault() {
        let settings = AppSettings.default
        XCTAssertTrue(settings.killSwitch, "Kill Switch должен быть включён по умолчанию")
        XCTAssertTrue(settings.blockAdsAndTrackers)
        XCTAssertFalse(settings.multihopEnabled)
        XCTAssertEqual(settings.preferredProtocolMTU, 1420)
    }

    func testSettingsCodableRoundtrip() throws {
        var settings = AppSettings.default
        settings.multihopEnabled = true
        settings.customDNS = "1.1.1.1"
        settings.splitTunnelExcludedApps = ["com.example.app"]

        let data = try JSONEncoder().encode(settings)
        let decoded = try JSONDecoder().decode(AppSettings.self, from: data)

        XCTAssertEqual(decoded, settings)
        XCTAssertTrue(decoded.multihopEnabled)
        XCTAssertEqual(decoded.customDNS, "1.1.1.1")
        XCTAssertEqual(decoded.splitTunnelExcludedApps, ["com.example.app"])
    }
}
