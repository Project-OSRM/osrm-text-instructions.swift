//
//  OSRMTextInstructions.swift
//  Voyage
//
//  Created by Johan Uhle on 01.11.16.
//  Copyright © 2016 Mapbox. All rights reserved.
//

import Foundation
import MapboxDirections

// Will automatically read localized Instructions.plist
let OSRMTextInstructionsStrings = NSDictionary(contentsOfFile: Bundle.main.path(forResource: "Instructions", ofType: "plist")!)!

class OSRMTextInstructions {
    let version: String
    let instructions: [ String: Any ]

    internal init(version: String) {
        self.version = version
        self.instructions = OSRMTextInstructionsStrings[version] as! [ String: Any ]
    }

    func capitalizeFirstLetter(string: String) -> String {
        return String(string.characters.prefix(1)).uppercased() + String(string.characters.dropFirst())
    }

    func laneConfig(intersection: Intersection) -> String? {
        guard let approachLanes = intersection.approachLanes else {
            return ""
        }

        guard let useableApproachLanes = intersection.usableApproachLanes else {
            return ""
        }

        // find lane configuration
        var config = Array(repeating: "x", count: approachLanes.count)
        for index in useableApproachLanes {
            config[index] = "o"
        }

        // reduce lane configurations to common cases
        var current = ""
        return config.reduce("", {
            (result: String?, lane: String) -> String? in
            if (lane != current) {
                current = lane
                return result! + lane
            } else {
                return result
            }
        })
    }

    func directionFromDegree(degree: Int?) -> String {
        guard let degree = degree else {
            // step had no bearing_after degree, ignoring
            return ""
        }

        // fetch locatized compass directions strings
        let directions = (instructions["constants"] as! NSDictionary)["direction"] as! [ String: String ]

        // Transform degrees to their translated compass direction
        switch degree {
        case 340..<360, 0..<20:
            return directions["north"]!
        case 20..<70:
            return directions["northeast"]!
        case 70..<110:
            return directions["east"]!
        case 110..<160:
            return directions["southeast"]!
        case 160..<200:
            return directions["south"]!
        case 200..<250:
            return directions["southwest"]!
        case 250..<290:
            return directions["west"]!
        case 290..<340:
            return directions["northwest"]!
        default:
            return "";
        }
    }

    func compile(step: RouteStep) -> String? {
        var type = step.maneuverType
        let modifier = step.maneuverDirection?.description
        let mode = step.transportType

        if type != .depart && type != .arrive && modifier == nil {
            return nil
        }

        if instructions[type?.description ?? ""] as? NSDictionary == nil {
            // OSRM specification assumes turn types can be added without
            // major version changes. Unknown types are to be treated as
            // type `turn` by clients
            type = .turn
        }

        var instructionObject: NSDictionary
        let modesInstructions = instructions["modes"] as? NSDictionary
        let typeInstructions = instructions[type?.description ?? ""] as! NSDictionary
        if mode != nil && modesInstructions != nil && modesInstructions![mode?.description as Any] != nil {
            instructionObject = modesInstructions![mode?.description as Any] as! NSDictionary
        } else if modifier != nil && typeInstructions[modifier!] != nil {
            instructionObject = typeInstructions[modifier!] as! NSDictionary
        } else {
            instructionObject = typeInstructions["default"] as! NSDictionary
        }

        // Special case handling
        var laneInstruction: String?
        switch type?.description ?? "turn" {
        case "use lane":
            var laneConfig: String? = ""
            if let intersection = step.intersections?.first {
                laneConfig = self.laneConfig(intersection: intersection)
            }
            laneInstruction = (((instructions["constants"]) as! NSDictionary)["lanes"] as! NSDictionary)[laneConfig ?? ""] as? String

            if laneInstruction == nil {
                // Lane configuration is not found, default to continue
                instructionObject = ((instructions["use lane"]) as! NSDictionary)["no_lanes"] as! NSDictionary
            }

            break
        case "rotary", "roundabout":
            // TODO: Enable once rotary_name exposed in RouteStep
            //            if step.rotaryName != nil && step.maneuverExit != nil, let nameExit = instructionObject["name_exit"] as? NSDictionary {
            //                instructionObject = nameExit
            //            } else if step.rotaryName != nil, let name = instructionObject["name"] as? NSDictionary {
            //                instructionObject = name
            if step.exitIndex != nil, let exit = instructionObject["exit"] as? NSDictionary {
                instructionObject = exit
            } else {
                instructionObject = instructionObject["default"] as! NSDictionary
            }
            break
        default:
            // NOOP
            break
        }

        // TODO: Decide way_name with special handling for name and ref
        var wayName = ""
        let name = step.name ?? ""
        wayName = name // TODO: Remove

        // Decide which instruction string to use
        // Destination takes precedence over name
        var instruction: String
        if step.destinations != nil && instructionObject["destination"] != nil {
            instruction = instructionObject["destination"] as! String
        } else if wayName != "" && instructionObject["name"] != nil {
            instruction = instructionObject["name"] as! String
        } else {
            instruction = instructionObject["default"] as! String
        }

        // Prepare token replacements
        let nthWaypoint = "" // TODO, add correct waypoint counting
        let destination = (step.destinations ?? "").components(separatedBy: ",")[0]
        var exit: String = ""
        if let exitIndex = step.exitIndex, exitIndex <= 10 {
            exit = NumberFormatter.localizedString(from: (exitIndex) as NSNumber, number: .ordinal)
        }
        let modifierConstant =
            (((instructions["constants"]) as! NSDictionary)["modifier"] as! NSDictionary)[modifier ?? "straight"] as! String
        var bearing: Int? = nil
        if step.finalHeading != nil { bearing = Int(step.finalHeading! as Double) }

        // Replace tokens
        let scanner = Scanner(string: instruction)
        scanner.charactersToBeSkipped = nil
        var result = ""
        while !scanner.isAtEnd {
            var buffer: NSString?

            if scanner.scanUpTo("{", into: &buffer) {
                result += buffer as! String
            }
            guard scanner.scanString("{", into: nil) else {
                continue
            }

            var token: NSString?
            guard scanner.scanUpTo("}", into: &token) else {
                continue
            }

            if scanner.scanString("}", into: nil) {
                switch token ?? "" {
                case "way_name": result += wayName
                case "destination": result += destination
                case "exit_number": result += exit
                // TODO: Enable once rotary_name exposed in MBRouteStep
                // case "rotary_name": result += step.rotaryName ?? ""
                case "lane_instruction": result += laneInstruction ?? ""
                case "modifier": result += modifierConstant
                case "direction": result += directionFromDegree(degree: bearing)
                case "nth": result += nthWaypoint // TODO: integrate
                default: break
                }
            } else {
                result += token as! String
            }
        }

        // remove excess spaces
        result = result.replacingOccurrences(of: "\\s\\s", with: " ", options: .regularExpression)

        // capitalize
        if (((OSRMTextInstructionsStrings["meta"] as! NSDictionary)["capitalizeFirstLetter"]) as! Bool) == true {
            result = capitalizeFirstLetter(string: result)
        }

        return result
    }
}
