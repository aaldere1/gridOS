import XCTest
@testable import GridOSKit

final class GridOSProductTests: XCTestCase {
    func testProductMetadataIsStable() {
        XCTAssertEqual(GridOSProduct.name, "gridOS")
        XCTAssertEqual(GridOSProduct.version, "1.0.3")
        XCTAssertFalse(GridOSProduct.productionPromise.isEmpty)
    }

    func testFoundationModuleStatusCarriesStableIdentity() {
        let status = FoundationModuleStatus(
            id: "example",
            title: "Example",
            state: .scaffolded,
            detail: "Example detail."
        )

        XCTAssertEqual(status.id, "example")
        XCTAssertEqual(status.state, .scaffolded)
    }
}
