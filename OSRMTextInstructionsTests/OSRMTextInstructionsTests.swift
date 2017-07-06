import XCTest
import MapboxDirections
@testable import OSRMTextInstructions

class OSRMTextInstructionsTests: XCTestCase {
    let instructions = OSRMInstructionFormatter(version: "v5")
    
    override func setUp() {
        super.setUp()
        
        // Force an English locale to match the fixture language rather than the test machine’s language.
        instructions.ordinalFormatter.locale = Locale(identifier: "en-US")
    }

    func testSentenceCasing() {
        XCTAssertEqual("Capitalized String", "capitalized String".sentenceCased)
        XCTAssertEqual("Capitalized String", "Capitalized String".sentenceCased)
        XCTAssertEqual("S", "s".sentenceCased)
        XCTAssertEqual("S", "S".sentenceCased)
        XCTAssertEqual("", "".sentenceCased)
    }

    func testFixtures() {
        do {
            let bundle = Bundle(for: OSRMTextInstructionsTests.self)
            let url = bundle.url(forResource: "v5", withExtension: nil, subdirectory: "osrm-text-instructions/test/fixtures/")!
            
            let directoryContents = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: [])
            for type in directoryContents {
                let typeDirectoryContents = try FileManager.default.contentsOfDirectory(at: type, includingPropertiesForKeys: nil, options: [])
                for fixture in typeDirectoryContents {
                    // parse fixture
                    guard let json = getFixture(url: fixture) else {
                        XCTAssert(false, "invalid json")
                        return
                    }
                    let options = json["options"] as? [String: Int]

                    let step = RouteStep(json: json["step"] as! [String: Any])

                    // compile instruction
                    let instruction = instructions.string(for: step, legIndex: options?["legIndex"], numberOfLegs: options?["legCount"], modifyValueByKey: nil)

                    // check generated instruction against fixture
                    XCTAssertEqual(
                        json["instruction"] as? String,
                        instruction,
                        fixture.path
                    )
                }
            }
        } catch let error as NSError {
            print(error.localizedDescription)
            XCTAssert(false)
        }
    }

    func getFixture(url: URL) -> NSMutableDictionary? {
        var rawJSON = Data()
        do {
            rawJSON = try Data(contentsOf: url, options: [])
        } catch {
            XCTAssert(false)
        }

        let json: NSDictionary
        do {
            json = try JSONSerialization.jsonObject(with: rawJSON, options: []) as! NSDictionary
        } catch {
            XCTAssert(false)
            return nil
        }

        // provide default values for properties that RouteStep
        // needs, but that our not in the fixtures
        let fixture: NSMutableDictionary = [:]
        let maneuver: NSMutableDictionary = [
            "location": [ 1.0, 1.0 ]
        ]
        let step: NSMutableDictionary = [
            "mode": "driving"
        ]

        let jsonStep = json["step"] as! [ String: Any ]
        step["name"] = jsonStep["name"]
        if let ref = jsonStep["ref"] {
            step["ref"] = ref
        }
        if let destinations = jsonStep["destinations"] {
            step["destinations"] = destinations
        }
        if let mode = jsonStep["mode"] {
            step["mode"] = mode
        }
        if let rotaryName = jsonStep["rotary_name"] {
            step["rotary_name"] = rotaryName
        }

        let jsonManeuver = jsonStep["maneuver"] as! [ String: Any ]
        maneuver["type"] = jsonManeuver["type"]
        if let modifier = jsonManeuver["modifier"] {
            maneuver["modifier"] = modifier
        }
        if let bearingAfter = jsonManeuver["bearing_after"] {
            maneuver["bearing_after"] = bearingAfter
        }
        if let exit = jsonManeuver["exit"] {
            maneuver["exit"] = exit
        }

        step["maneuver"] = maneuver
        if let intersections = jsonStep["intersections"] {
            step["intersections"] = intersections
        }
        fixture["step"] = step
        fixture["instruction"] = (json["instructions"] as! [ String: Any ])["en"] as! String

        fixture["options"] = json["options"]
        return fixture
    }
}
