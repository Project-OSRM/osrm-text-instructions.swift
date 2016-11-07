//
//  OSRMTextInstructions.swift
//  Voyage
//
//  Created by Johan Uhle on 01.11.16.
//  Copyright © 2016 Mapbox. All rights reserved.
//

import Foundation
import MapboxDirections

class Maneuver {
    public let modifier: String?
    public let type: String
    public let exit: Int?
    
    internal init(modifier: String?, type: String, exit: Int?) {
        self.modifier = modifier
        self.type = type
        self.exit = exit
    }
    
    internal convenience init(json: [ String: AnyObject ]) {
        self.init(
            modifier: json["modifier"] as? String,
            type: json["type"] as! String,
            exit: json["exit"] as? Int
        )
    }
}

class Step {
    public let maneuver: Maneuver
    public let rotary_name: String?
    public let name: String?
    public let destinations: String?
    public let mode: String?
    
    internal init(maneuver: Maneuver, rotary_name: String?, name: String?, destinations: String?, mode: String?) {
        self.maneuver = maneuver
        self.rotary_name = rotary_name
        self.name = name
        self.destinations = destinations
        self.mode = mode
    }
    
    internal convenience init(json: [ String: AnyObject ]) {
        self.init(
            maneuver: Maneuver(json: json["maneuver"] as! [ String: AnyObject ]),
            rotary_name: json["type"] as? String,
            name: json["name"] as? String,
            destinations: json["destinations"] as? String,
            mode: json["mode"] as? String
        )
    }
    
    // TODO
    //    internal convenience init(routeStep: RouteStep) {
    //        self.init()
    //    }
}

class OSRMTextInstructions {
    let instructions: NSDictionary
    let version: String
    
    internal init(version: String, instructions: NSDictionary) {
        self.version = version
        self.instructions = instructions.object(forKey: version) as! NSDictionary
    }
    
    internal convenience init(version: String, language: String) {
        // TODO: lazy load?
        let mainBundle = Bundle(for: type(of: self))
        let plist =  NSDictionary(contentsOfFile: mainBundle.path(forResource: "instructions/" + language + ".json", ofType: "plist")!)
        
        self.init(version: version, instructions: plist!)
    }
    
    func compile(step: Step) -> String? {
        let modifier = step.maneuver.modifier
        var type = step.maneuver.type

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
            if((step.rotary_name != nil) && ((step.maneuver.exit != nil)) && (instructionObject.object(forKey: "name_exit") != nil)) {
                instructionObject = instructionObject.object(forKey: "name_exit") as! NSDictionary
            } else if ((step.rotary_name != nil) && (instructionObject.object(forKey: "name") != nil)) {
                instructionObject = instructionObject.object(forKey: "name") as! NSDictionary
            } else if ((step.maneuver.exit != nil) && (instructionObject.object(forKey: "exit") != nil)) {
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
        let exit = step.maneuver.exit ?? 1 // TODO: ordinalize
        let modifierConstant =
            ((self.instructions.object(forKey: "constants") as! NSDictionary)
            .object(forKey: "modifier") as! NSDictionary)
            .object(forKey: modifier ?? "straight") as! String

        instruction = instruction
            .replacingOccurrences(of: "{way_name}", with: wayName)
            .replacingOccurrences(of: "{destination}", with: destination)
            .replacingOccurrences(of: "{exit_number}", with: String(exit))
            .replacingOccurrences(of: "{rotary_name}", with: step.rotary_name ?? "")
            .replacingOccurrences(of: "{lane_instruction}", with: "") // TODO: implement correct lane instructions
            .replacingOccurrences(of: "{modifier}", with: modifierConstant)
            .replacingOccurrences(of: "{direction}", with: "") // TODO: integrate actual direction
            .replacingOccurrences(of: "{nth}", with: nthWaypoint)
            .replacingOccurrences(of: "  ", with: " ") // remove excess spaces

        // TODO: capitalize

        return instruction

    }
}
