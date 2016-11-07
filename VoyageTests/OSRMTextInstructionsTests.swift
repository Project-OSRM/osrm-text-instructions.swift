//
//  OSRMTextInstructionsTests.swift
//  Voyage
//
//  Created by Johan Uhle on 07.11.16.
//  Copyright © 2016 Mapbox. All rights reserved.
//

import XCTest

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
                    let json = getFixture(url: fixture) as! [ String: AnyObject ]
                    let step = OSRMStep(json: json["step"] as! [ String: AnyObject ])

                    // compile instruction
                    let instructions = self.instructions.compile(step: step)

                    // check generated instruction against fixture
                    // TODO: Remove unnecessary type filter
                    if (true || step.maneuverType == "turn") {
                        XCTAssertEqual(
                            json["instruction"] as? String,
                            instructions,
                            fixture.path
                        )
                    }
                }
            }
        } catch let error as NSError {
            print(error.localizedDescription)
            XCTAssert(false)
        }
    }

    func getFixture(url: URL) -> Any {
        var json = Data()
        do {
            json = try Data(contentsOf: url, options: [])
        } catch {
            XCTAssert(false)
        }
        var routeJSON: Any!
        do {
            routeJSON = try JSONSerialization.jsonObject(with: json, options: [])
        } catch {
            XCTAssert(false)
        }
        return routeJSON
    }
}
