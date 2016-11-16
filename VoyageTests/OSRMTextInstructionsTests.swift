//
//  OSRMTextInstructionsTests.swift
//  Voyage
//
//  Created by Johan Uhle on 07.11.16.
//  Copyright © 2016 Mapbox. All rights reserved.
//

import XCTest
import MapboxDirections

class OSRMTextInstructionsTests: XCTestCase {
    let instructions = OSRMTextInstructions(version: "v5")

    func testCapitalizeFirstLetter() {
        XCTAssertEqual("Capitalized String", instructions.capitalizeFirstLetter(string: ("capitalized String")))
        XCTAssertEqual("Capitalized String", instructions.capitalizeFirstLetter(string: ("Capitalized String")))
        XCTAssertEqual("S", instructions.capitalizeFirstLetter(string: ("s")))
        XCTAssertEqual("S", instructions.capitalizeFirstLetter(string: ("S")))
        XCTAssertEqual("", instructions.capitalizeFirstLetter(string: ("")))
    }

    func testFixtures() {
        do {
            let url = URL(fileURLWithPath: Bundle.main.path(forResource: "v5", ofType: nil, inDirectory: "osrm-text-instructions/test/fixtures/")!)
            let directoryContents = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: [])
            for type in directoryContents {
                let typeDirectoryContents = try FileManager.default.contentsOfDirectory(at: type, includingPropertiesForKeys: nil, options: [])
                for fixture in typeDirectoryContents {
                    // parse fixture
                    guard let json = getFixture(url: fixture) else {
                        XCTAssert(false, "invalid json")
                        return
                    }

                    let step = RouteStep(json: json["step"] as! [String: Any])

                    // compile instruction
                    let instruction = self.instructions.compile(step: step)

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
        fixture["instruction"] = json["instruction"] as! String

        return fixture
    }
}
