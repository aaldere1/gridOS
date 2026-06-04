import XCTest
@testable import GridOSKit

final class GridOSProductTests: XCTestCase {
    func testProductMetadataIsStable() {
        XCTAssertEqual(GridOSProduct.name, "gridOS")
        XCTAssertTrue(GridOSProduct.version.range(of: #"^\d+\.\d+\.\d+$"#, options: .regularExpression) != nil)
        XCTAssertFalse(GridOSProduct.build.isEmpty)
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
