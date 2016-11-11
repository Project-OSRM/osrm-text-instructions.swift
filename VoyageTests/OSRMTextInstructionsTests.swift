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

    func testFixtures() {
        do {
            let url = URL(fileURLWithPath: "/Users/johan/Code/mapbox/voyage/osrm-text-instructions/test/fixtures/v5/")
            let directoryContents = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: [])
            for type in directoryContents {
                let typeDirectoryContents = try FileManager.default.contentsOfDirectory(at: type, includingPropertiesForKeys: nil, options: [])

                for fixture in typeDirectoryContents {
                    // parse fixture
                    let json = getFixture(url: fixture)
                    if json == nil {
                        XCTAssert(false, "invalid json")
                        return
                    }

                    let step = RouteStep(json: json!["step"] as! [String: Any])

                    // compile instruction
                    let instruction = self.instructions.compile(step: step)

                    // check generated instruction against fixture
                    XCTAssertEqual(
                        json!["instruction"] as? String,
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
        if jsonStep["destinations"] != nil { step["destinations"] = jsonStep["destinations"] }
        if jsonStep["mode"] != nil { step["mode"] = jsonStep["mode"] }

        let jsonManeuver = jsonStep["maneuver"] as! [ String: Any ]
        maneuver["type"] = jsonManeuver["type"]
        if jsonManeuver["modifier"] != nil { maneuver["modifier"] = jsonManeuver["modifier"] }
        if jsonManeuver["bearing_after"] != nil { maneuver["bearing_after"] = jsonManeuver["bearing_after"] }
        if jsonManeuver["exit"] != nil { maneuver["exit"] = jsonManeuver["exit"] }

        // TODO: wait until rotary_name is enabled in RouteStep
        // if jsonManeuver["rotary_name"] != nil { maneuver["rotary_name"] = jsonManeuver["rotary_name"] }
        // TODO: wait until ref is enabled in RouteStep
        // if jsonManeuver["ref"] != nil { maneuver["ref"] = jsonManeuver["ref"] }

        step["maneuver"] = maneuver
        if (jsonStep["intersections"] != nil) {
            step["intersections"] = jsonStep["intersections"]
        }
        fixture["step"] = step
        fixture["instruction"] = json["instruction"] as! String

        return fixture
    }
}
