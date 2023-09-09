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

    func testFixtures() throws {
        #if SWIFT_PACKAGE
        let bundle = Bundle.module
        #else
        let bundle = Bundle(for: OSRMTextInstructionsTests.self)
        #endif

        let url = bundle.url(forResource: "v5", withExtension: nil, subdirectory: "osrm-text-instructions/test/fixtures/")!
        
        var directoryContents: [URL] = []
        XCTAssertNoThrow(directoryContents = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: []))
        for type in directoryContents {
            var typeDirectoryContents: [URL] = []
            XCTAssertNoThrow(typeDirectoryContents = try FileManager.default.contentsOfDirectory(at: type, includingPropertiesForKeys: nil, options: []))
            for fixture in typeDirectoryContents {
                if type.lastPathComponent == "phrase" {
                    var rawJSON = Data()
                    XCTAssertNoThrow(rawJSON = try Data(contentsOf: fixture, options: []))
                    
                    var json: [String: Any] = [:]
                    XCTAssertNoThrow(json = try JSONSerialization.jsonObject(with: rawJSON, options: []) as! [String: Any])
                    
                    let phraseInFileName = fixture.deletingPathExtension().lastPathComponent.replacingOccurrences(of: "_", with: " ")
                    let phraseName = PhraseName(description: phraseInFileName)
                    XCTAssertNotNil(phraseName)
                    var phrase: String?
                    if let phraseName = phraseName {
                        phrase = instructions.phrase(named: phraseName)
                    }
                    XCTAssertNotNil(phrase)
                    let fixtureOptions = json["options"] as! [String: String]
                    
                    let expectedValue = (json["phrases"] as! [String: String])["en"]
                    let actualValue = phrase?.replacingTokens(using: { (tokenType) -> String in
                        var replacement: String?
                        switch tokenType {
                        case .firstInstruction:
                            replacement = fixtureOptions["instruction_one"]
                        case .secondInstruction:
                            replacement = fixtureOptions["instruction_two"]
                        case .distance:
                            replacement = fixtureOptions["distance"]
                        default:
                            XCTFail("Unexpected token type \(tokenType) in phrase \(phraseInFileName)")
                        }
                        XCTAssertNotNil(replacement, "Missing fixture option for \(tokenType)")
                        return replacement ?? ""
                    })
                    XCTAssertEqual(expectedValue, actualValue, fixture.path)
                } else {
                    // parse fixture
                    let json = getFixture(url: fixture)
                    let options = json["options"] as? [String: Any]

                    let encodedJSON = try JSONSerialization.data(withJSONObject: json["step"]!)
                    let step = try JSONDecoder().decode(RouteStep.self, from: encodedJSON)
                    
                    var roadClasses: RoadClasses? = nil
                    if let classes = options?["classes"] as? [String] {
                        roadClasses = RoadClasses(descriptions: classes)
                    }
                    
                    // compile instruction
                    let instruction = instructions.string(for: step, legIndex: options?["legIndex"] as? Int, numberOfLegs: options?["legCount"] as? Int, roadClasses: roadClasses, modifyValueByKey: nil)
                    
                    // check generated instruction against fixture
                    XCTAssertEqual(
                        json["instruction"] as? String,
                        instruction,
                        fixture.path
                    )
                }
            }
        }
    }

    func getFixture(url: URL) -> [String: Any] {
        var rawJSON = Data()
        XCTAssertNoThrow(rawJSON = try Data(contentsOf: url, options: []))

        var json: [String: Any] = [:]
        XCTAssertNoThrow(json = try JSONSerialization.jsonObject(with: rawJSON, options: []) as! [String: Any])

        // provide default values for properties that RouteStep
        // needs, but that our not in the fixtures
        var fixture: [String: Any] = [:]
        var maneuver: [String: Any] = [
            "location": [ 1.0, 1.0 ],
            "distance": 0,
        ]
        var step: [String: Any] = [
            "mode": "driving",
            "driving_side": "right",
            "distance": 0,
            "duration": 0,
        ]

        let jsonStep = json["step"] as! [ String: Any ]
        step["name"] = jsonStep["name"]
        if let ref = jsonStep["ref"] {
            step["ref"] = ref
        }
        if let exits = jsonStep["exits"] {
            step["exits"] = exits
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
        if let distance = jsonStep["distance"] {
            step["distance"] = distance
        }
        if let duration = jsonStep["duration"] {
            step["duration"] = duration
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
