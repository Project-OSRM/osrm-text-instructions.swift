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
    let instructions: NSDictionary
    
    internal init(version: String) {
        self.version = version
        self.instructions = OSRMTextInstructionsStrings[version] as! NSDictionary
    }

    func directionFromDegree(degree: Int?) -> String {
        let directions = (instructions["constants"] as! NSDictionary).object(forKey: "direction") as! [ String: String ]

        // Transform degrees to their translated compass direction
        if (degree == nil) {
            // step had no bearing_after degree, ignoring
            return "";
        } else if (degree! >= 0 && degree! <= 20) {
            return directions["north"]!
        } else if (degree! > 20 && degree! < 70) {
            return directions["northeast"]!
        } else if (degree! >= 70 && degree! < 110) {
            return directions["east"]!
        } else if (degree! >= 110 && degree! <= 160) {
            return directions["southeast"]!
        } else if (degree! > 160 && degree! <= 200) {
            return directions["south"]!
        } else if (degree! > 200 && degree! < 250) {
            return directions["southwest"]!
        } else if (degree! >= 250 && degree! <= 290) {
            return directions["west"]!
        } else if (degree! > 290 && degree! < 340) {
            return directions["northwest"]!
        } else if (degree! >= 340 && degree! <= 360) {
            return directions["north"]!
        } else {
            // invalid bearing
            return "";
        }
    }

    func compile(step: RouteStep) -> String? {
        var type = step.maneuverType
        let modifier = step.maneuverDirection?.description
        let mode = step.transportType

        if (type != .depart && type != .arrive && modifier == nil) {
            return nil
        }

        if (instructions[type?.description as Any] as? NSDictionary == nil) {
            // OSRM specification assumes turn types can be added without
            // major version changes. Unknown types are to be treated as
            // type `turn` by clients
            type = .turn
        }

        var instructionObject: NSDictionary
        let modesInstructions = instructions["modes"] as? NSDictionary
        let typeInstructions = instructions[type?.description as Any] as! NSDictionary
        if (mode != nil && modesInstructions != nil && modesInstructions![mode?.description as Any] != nil) {
            instructionObject = modesInstructions![mode?.description as Any] as! NSDictionary
        } else if (modifier != nil && typeInstructions[modifier!] != nil) {
            instructionObject = typeInstructions[modifier!] as! NSDictionary
        } else {
            instructionObject = typeInstructions["default"] as! NSDictionary
        }

        // Special case handling
        switch type?.description ?? "turn" {
        case "use lane":
            // TODO: Handle
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
        if (step.destinations != nil && instructionObject["destination"] != nil) {
            instruction = instructionObject["destination"] as! String
        } else if ((wayName != "") && instructionObject["name"] != nil) {
            instruction = instructionObject["name"] as! String
        } else {
            instruction = instructionObject["default"] as! String
        }

        // Replace tokens
        let nthWaypoint = "" // TODO, add correct waypoint counting
        let destination = (step.destinations ?? "").components(separatedBy: ",")[0]
        let exit = NumberFormatter.localizedString(from: (step.exitIndex ?? 1) as NSNumber, number: .ordinal)
        let modifierConstant =
            (((instructions["constants"]) as! NSDictionary)
            .object(forKey: "modifier") as! NSDictionary)
            .object(forKey: modifier ?? "straight") as! String
        var bearing: Int? = nil
        if (step.finalHeading != nil) { bearing = Int(step.finalHeading! as Double) }
        return instruction.components(separatedBy: " ").map({
                (s: String) -> String in
                    switch s {
                    case "{way_name}": return wayName
                    case "{destination}": return destination
                    case "{exit_number}": return exit
                    // TODO: Enable once rotary_name exposed in MBRouteStep
                    // case "{rotary_name}": return step.rotaryName ?? ""
                    case "{lane_instruction}": return "" // TODO: implement correct lane instructions
                    case "{modifier}": return modifierConstant
                    case "{direction}": return directionFromDegree(degree: bearing)
                    case "{nth}": return nthWaypoint // TODO: integrate waypoints
                    default: return s
                }
            })
            .joined(separator: " ")
            .replacingOccurrences(of: "  ", with: " ") // remove excess spaces
            // TODO: capitalize
    }
}
