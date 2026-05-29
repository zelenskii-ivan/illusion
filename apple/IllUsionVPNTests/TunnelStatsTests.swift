import XCTest
@testable import IllUsionVPN

final class TunnelStatsTests: XCTestCase {
    func testParseSumsRxAndTxAcrossPeers() {
        let runtime = """
        public_key=abc
        rx_bytes=1024
        tx_bytes=2048
        public_key=def
        rx_bytes=1024
        tx_bytes=0
        """
        let stats = TunnelStats.parse(runtime)
        XCTAssertEqual(stats.rxBytes, 2048)
        XCTAssertEqual(stats.txBytes, 2048)
    }

    func testFormatHumanReadable() {
        XCTAssertEqual(TunnelStats.format(512), "512 B")
        XCTAssertEqual(TunnelStats.format(2048), "2.0 KB")
        XCTAssertEqual(TunnelStats.format(5 * 1024 * 1024), "5.0 MB")
    }

    func testEmptyRuntimeProducesZeroStats() {
        let stats = TunnelStats.parse("")
        XCTAssertEqual(stats.rxBytes, 0)
        XCTAssertEqual(stats.txBytes, 0)
    }
}
