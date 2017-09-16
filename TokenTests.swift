import XCTest
import OSRMTextInstructions

class TokenTests: XCTestCase {
    func testReplacingTokens() {
        XCTAssertEqual("Dead Beef", "Dead Beef".replacingTokens { _ in "" })
        XCTAssertEqual("Food", "F{ref}{ref}d".replacingTokens { _ in "o" })
        
        XCTAssertEqual("Take the left stairs to the 20th floor", "Take the {modifier} stairs to the {nth} floor".replacingTokens { (tokenType) -> String in
            switch tokenType {
            case .modifier:
                return "left"
            case .wayPoint:
                return "20th"
            default:
                XCTAssert(false)
                return "wrong"
            }
        })
        
        XCTAssertEqual("{👿}", "{👿}".replacingTokens { _ in "👼" })
        XCTAssertEqual("{", "{".replacingTokens { _ in "🕳" })
        XCTAssertEqual("{💣", "{💣".replacingTokens { _ in "🕳" })
        XCTAssertEqual("}", "}".replacingTokens { _ in "🕳" })
    }
}
