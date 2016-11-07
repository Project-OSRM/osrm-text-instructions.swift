//
//  OSRMTextInstructions.swift
//  Voyage
//
//  Created by Johan Uhle on 01.11.16.
//  Copyright © 2016 Mapbox. All rights reserved.
//

import Foundation
import MapboxDirections

class OSRMStep {
    public let rotaryName: String?
    public let name: String?
    public let destinations: String?
    public let mode: String?
    public let maneuverModifier: String?
    public let maneuverType: String
    public let maneuverExit: Int?
    public let maneuverBearingAfter: Int?
    
    internal init(rotaryName: String?, name: String?, destinations: String?, mode: String?, maneuverModifier: String?, maneuverType: String, maneuverExit: Int?, maneuverBearingAfter: Int?) {
        self.rotaryName = rotaryName
        self.name = name
        self.destinations = destinations
        self.mode = mode
        self.maneuverModifier = maneuverModifier
        self.maneuverType = maneuverType
        self.maneuverExit = maneuverExit
        self.maneuverBearingAfter = maneuverBearingAfter
    }

    internal convenience init(json: [ String: AnyObject ]) {
        let maneuver = json["maneuver"] as! [ String: AnyObject ]

        self.init(
            rotaryName: json["rotary_name"] as? String,
            name: json["name"] as? String,
            destinations: json["destinations"] as? String,
            mode: json["mode"] as? String,
            maneuverModifier: maneuver["modifier"] as? String,
            maneuverType: maneuver["type"] as! String,
            maneuverExit: maneuver["exit"] as? Int,
            maneuverBearingAfter: maneuver["bearing_after"] as? Int
        )
    }
}

// Will automatically read correctly-localized Instructions.plist
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

    func compile(step: OSRMStep) -> String? {
        let modifier = step.maneuverModifier
        var type = step.maneuverType

        if (type != "depart" && type != "arrive" && modifier == nil) {
            return nil
        }

        if (instructions[type] as? NSDictionary == nil) {
            // OSRM specification assumes turn types can be added without
            // major version changes. Unknown types are to be treated as
            // type `turn` by clients
            type = "turn"
        }

        var instructionObject: NSDictionary
        let modesInstructions = instructions["modes"] as? NSDictionary
        let typeInstructions = instructions[type] as! NSDictionary
        if (step.mode != nil && modesInstructions != nil && modesInstructions![step.mode!] != nil) {
            instructionObject = modesInstructions![step.mode!] as! NSDictionary
        } else if (modifier != nil && typeInstructions[modifier!] != nil) {
            instructionObject = typeInstructions[modifier!] as! NSDictionary
        } else {
            instructionObject = typeInstructions["default"] as! NSDictionary
        }

        // Special case handling
        switch type {
        case "use lane":
            // TODO: Handle
            break
        case "rotary", "roundabout":
            if step.rotaryName != nil && step.maneuverExit != nil, let nameExit = instructionObject["name_exit"] as? NSDictionary {
                instructionObject = nameExit
            } else if step.rotaryName != nil, let name = instructionObject["name"] as? NSDictionary {
                instructionObject = name
            } else if step.maneuverExit != nil, let exit = instructionObject["exit"] as? NSDictionary {
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
        let exit = NumberFormatter.localizedString(from: (step.maneuverExit ?? 1) as NSNumber, number: .ordinal)
        let modifierConstant =
            (((instructions["constants"]) as! NSDictionary)
            .object(forKey: "modifier") as! NSDictionary)
            .object(forKey: modifier ?? "straight") as! String
        return instruction.components(separatedBy: " ").map({
                (s: String) -> String in
                    switch s {
                    case "{way_name}": return wayName
                    case "{destination}": return destination
                    case "{exit_number}": return exit
                    case "{rotary_name}": return step.rotaryName ?? ""
                    case "{lane_instruction}": return "" // TODO: implement correct lane instructions
                    case "{modifier}": return modifierConstant
                    case "{direction}": return directionFromDegree(degree: step.maneuverBearingAfter)
                    case "{nth}": return nthWaypoint // TODO: integrate waypoints
                    default: return s
                }
            })
            .joined(separator: " ")
            .replacingOccurrences(of: "  ", with: " ") // remove excess spaces
            // TODO: capitalize
    }
}
