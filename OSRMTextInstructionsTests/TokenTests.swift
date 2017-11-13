import XCTest
@testable import OSRMTextInstructions

class TokenTests: XCTestCase {
    func testReplacingTokens() {
        XCTAssertEqual("Dead Beef", "Dead Beef".replacingTokens { _ in "" })
        XCTAssertEqual("Food", "F{ref}{ref}d".replacingTokens { _ in "o" })
        
        XCTAssertEqual("Take the left stairs to the 20th floor", "Take the {modifier} stairs to the {nth} floor".replacingTokens { (tokenType, variant) -> String in
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
        XCTAssertEqual("{👿:}", "{👿:}".replacingTokens { _ in "👼" })
        XCTAssertEqual("{👿:💣}", "{👿:💣}".replacingTokens { _ in "👼" })
        XCTAssertEqual("{", "{".replacingTokens { _ in "🕳" })
        XCTAssertEqual("{💣", "{💣".replacingTokens { _ in "🕳" })
        XCTAssertEqual("}", "}".replacingTokens { _ in "🕳" })
    }
    
    func testInflectingStrings() {
        if Bundle(for: OSRMInstructionFormatter.self).preferredLocalizations.contains(where: { $0.starts(with: "ru") }) {
            XCTAssertEqual("Бармалееву улицу", "Бармалеева улица".inflected(into: "accusative", version: "v5"))
        }
    }
}
