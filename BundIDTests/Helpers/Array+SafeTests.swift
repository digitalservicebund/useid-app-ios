import XCTest

@testable import BundID

final class Array_SafeTests: XCTestCase {

    func testOutOfBoundsAccess() throws {
        XCTAssertNil([1, 2, 3][safe: 4])
    }

    func testAccess() throws {
        XCTAssertEqual(["a", "b", "c"][safe: 1], "b")
    }
}
