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
    
    internal init(rotaryName: String?, name: String?, destinations: String?, mode: String?, maneuverModifier: String?, maneuverType: String, maneuverExit: Int?) {
        self.rotaryName = rotaryName
        self.name = name
        self.destinations = destinations
        self.mode = mode
        self.maneuverModifier = maneuverModifier
        self.maneuverType = maneuverType
        self.maneuverExit = maneuverExit
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
            maneuverExit: maneuver["exit"] as? Int
        )
    }

    // TODO
    //    internal convenience init(routeStep: RouteStep) {
    //        self.init()
    //    }
}

// Will automatically read correctly-localized Instructions.plist
let OSRMTextInstructionsStrings = NSDictionary(contentsOfFile: Bundle.main.path(forResource: "Instructions", ofType: "plist")!)!

class OSRMTextInstructions {
    let version: String
    let instructions: NSDictionary
    
    internal init(version: String) {
        self.version = version
        self.instructions = OSRMTextInstructionsStrings.object(forKey: self.version) as! NSDictionary
    }

    func compile(step: OSRMStep) -> String? {
        let modifier = step.maneuverModifier
        var type = step.maneuverType

        if (type != "depart" && type != "arrive" && modifier == nil) {
            // TODO: How to throw error here?
            return nil
        }

        if ((self.instructions.object(forKey: type) as? NSDictionary) == nil ){
            // OSRM specification assumes turn types can be added without
            // major version changes. Unknown types are to be treated as
            // type `turn` by clients
            type = "turn"
        }

        var instructionObject: NSDictionary
        let modesInstructions = self.instructions.object(forKey: "modes") as? NSDictionary
        let typeInstructions = self.instructions.object(forKey: type) as! NSDictionary
        if ((step.mode != nil) && modesInstructions?.object(forKey: step.mode!) != nil) {
            instructionObject = modesInstructions?.object(forKey: step.mode!) as! NSDictionary
        } else if ((modifier != nil) && typeInstructions.object(forKey: modifier!) != nil) {
            instructionObject = typeInstructions.object(forKey: modifier!) as! NSDictionary
        } else {
            instructionObject = typeInstructions.object(forKey: "default") as! NSDictionary
        }

        // Special case handling
        switch type {
        case "use lane":
            // TODO: Handle
            break
        case let x where x == "rotary" || x == "roundabout":
            if((step.rotaryName != nil) && ((step.maneuverExit != nil)) && (instructionObject.object(forKey: "name_exit") != nil)) {
                instructionObject = instructionObject.object(forKey: "name_exit") as! NSDictionary
            } else if ((step.rotaryName != nil) && (instructionObject.object(forKey: "name") != nil)) {
                instructionObject = instructionObject.object(forKey: "name") as! NSDictionary
            } else if ((step.maneuverExit != nil) && (instructionObject.object(forKey: "exit") != nil)) {
                instructionObject = instructionObject.object(forKey: "exit") as! NSDictionary
            } else {
                instructionObject = instructionObject.object(forKey: "default") as! NSDictionary
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
        if ((step.destinations != nil) && instructionObject.object(forKey: "destination") != nil) {
            instruction = instructionObject.object(forKey: "destination") as! String
        } else if ((wayName != "") && instructionObject.object(forKey: "name") != nil) {
            instruction = instructionObject.object(forKey: "name") as! String
        } else {
            instruction = instructionObject.object(forKey: "default") as! String
        }

        // Replace tokens
        // NOOP if they don't exist
        let nthWaypoint = "" // TODO, add correct waypoint counting
        let destination = (step.destinations ?? "").components(separatedBy: ",")[0]
        let exit = step.maneuverExit ?? 1 // TODO: ordinalize
        let modifierConstant =
            ((self.instructions.object(forKey: "constants") as! NSDictionary)
            .object(forKey: "modifier") as! NSDictionary)
            .object(forKey: modifier ?? "straight") as! String

        instruction = instruction
            .replacingOccurrences(of: "{way_name}", with: wayName)
            .replacingOccurrences(of: "{destination}", with: destination)
            .replacingOccurrences(of: "{exit_number}", with: String(exit))
            .replacingOccurrences(of: "{rotary_name}", with: step.rotaryName ?? "")
            .replacingOccurrences(of: "{lane_instruction}", with: "") // TODO: implement correct lane instructions
            .replacingOccurrences(of: "{modifier}", with: modifierConstant)
            .replacingOccurrences(of: "{direction}", with: "") // TODO: integrate actual direction
            .replacingOccurrences(of: "{nth}", with: nthWaypoint)
            .replacingOccurrences(of: "  ", with: " ") // remove excess spaces

        // TODO: capitalize

        return instruction

    }
}
