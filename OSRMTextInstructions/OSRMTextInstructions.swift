import Foundation
import MapboxDirections

// Will automatically read localized Instructions.plist
let OSRMTextInstructionsStrings = NSDictionary(contentsOfFile: Bundle(for: OSRMInstructionFormatter.self).path(forResource: "Instructions", ofType: "plist")!)!

protocol Tokenized {
    associatedtype T
    
    /**
     Replaces `{tokens}` in the receiver using the given closure.
     */
    func replacingTokens(using interpolator: ((TokenType) -> T)) -> T
}

extension String: Tokenized {
    public var sentenceCased: String {
        return prefix(1).uppercased() + dropFirst()
    }
    
    public func replacingTokens(using interpolator: ((TokenType) -> String)) -> String {
        let scanner = Scanner(string: self)
        scanner.charactersToBeSkipped = nil
        var result = ""
        while !scanner.isAtEnd {
            var buffer: NSString?
            
            if scanner.scanUpTo("{", into: &buffer) {
                result += buffer! as String
            }
            guard scanner.scanString("{", into: nil) else {
                continue
            }
            
            var token: NSString?
            guard scanner.scanUpTo("}", into: &token) else {
                result += "{"
                continue
            }
            
            if scanner.scanString("}", into: nil) {
                if let tokenType = TokenType(description: token! as String) {
                    result += interpolator(tokenType)
                } else {
                    result += "{\(token!)}"
                }
            } else {
                result += "{\(token!)"
            }
        }
        
        // remove excess spaces
        result = result.replacingOccurrences(of: "\\s\\s", with: " ", options: .regularExpression)
        
        // capitalize
        let meta = OSRMTextInstructionsStrings["meta"] as! [String: Any]
        if meta["capitalizeFirstLetter"] as? Bool ?? false {
            result = result.sentenceCased
        }
        return result
    }
}

extension NSAttributedString: Tokenized {
    @objc public func replacingTokens(using interpolator: ((TokenType) -> NSAttributedString)) -> NSAttributedString {
        let scanner = Scanner(string: string)
        scanner.charactersToBeSkipped = nil
        let result = NSMutableAttributedString()
        while !scanner.isAtEnd {
            var buffer: NSString?
            
            if scanner.scanUpTo("{", into: &buffer) {
                result.append(NSAttributedString(string: buffer! as String))
            }
            guard scanner.scanString("{", into: nil) else {
                continue
            }
            
            var token: NSString?
            guard scanner.scanUpTo("}", into: &token) else {
                continue
            }
            
            if scanner.scanString("}", into: nil) {
                if let tokenType = TokenType(description: token! as String) {
                    result.append(interpolator(tokenType))
                }
            } else {
                result.append(NSAttributedString(string: token! as String))
            }
        }
        
        // remove excess spaces
        let wholeRange = NSRange(location: 0, length: result.mutableString.length)
        result.mutableString.replaceOccurrences(of: "\\s\\s", with: " ", options: .regularExpression, range: wholeRange)
        
        // capitalize
        let meta = OSRMTextInstructionsStrings["meta"] as! [String: Any]
        if meta["capitalizeFirstLetter"] as? Bool ?? false {
            result.replaceCharacters(in: NSRange(location: 0, length: 1), with: String(result.string.first!).uppercased())
        }
        return result as NSAttributedString
    }
}

@objc public class OSRMInstructionFormatter: Formatter {
    let version: String
    let instructions: [String: Any]
    
    let ordinalFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = .current
        if #available(iOS 9.0, OSX 10.11, *) {
            formatter.numberStyle = .ordinal
        }
        return formatter
    }()
    
    @objc public init(version: String) {
        self.version = version
        self.instructions = OSRMTextInstructionsStrings[version] as! [String: Any]
        
        super.init()
    }
    
    required public init?(coder decoder: NSCoder) {
        if let version = decoder.decodeObject(of: NSString.self, forKey: "version") as String? {
            self.version = version
        } else {
            return nil
        }
        
        if let instructions = decoder.decodeObject(of: [NSDictionary.self, NSArray.self, NSString.self], forKey: "instructions") as? [String: Any] {
            self.instructions = instructions
        } else {
            return nil
        }
        
        super.init(coder: decoder)
    }
    
    override public func encode(with coder: NSCoder) {
        super.encode(with: coder)
        
        coder.encode(version, forKey: "version")
        coder.encode(instructions, forKey: "instructions")
    }

    var constants: [String: Any] {
        return instructions["constants"] as! [String: Any]
    }
    
    /**
     Returns a format string with the given name.
     
     - returns: A format string suitable for `String.replacingTokens(using:)`.
     */
    @objc public func phrase(named name: PhraseName) -> String {
        let phrases = instructions["phrase"] as! [String: String]
        return phrases["\(name)"]!
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
        let directions = constants["direction"] as! [String: String]

        // Transform degrees to their translated compass direction
        switch degree {
        case 340...360, 0...20:
            return directions["north"]!
        case 20..<70:
            return directions["northeast"]!
        case 70...110:
            return directions["east"]!
        case 110..<160:
            return directions["southeast"]!
        case 160...200:
            return directions["south"]!
        case 200..<250:
            return directions["southwest"]!
        case 250...290:
            return directions["west"]!
        case 290..<340:
            return directions["northwest"]!
        default:
            return "";
        }
    }
    
    typealias InstructionsByToken = [String: String]
    typealias InstructionsByModifier = [String: InstructionsByToken]
    
    override public func string(for obj: Any?) -> String? {
        return string(for: obj, legIndex: nil, numberOfLegs: nil, roadClasses: nil, modifyValueByKey: nil)
    }
    
    /**
     Creates an instruction given a step and options.
     
     - parameter step: The step to format.
     - parameter legIndex: Current leg index the user is currently on.
     - parameter numberOfLegs: Total number of `RouteLeg` for the given `Route`.
     - parameter roadClasses: Option set representing the classes of road for the `RouteStep`.
     - parameter modifyValueByKey: Allows for mutating the instruction at given parts of the instruction.
     - returns: An instruction as a `String`.
     */
    public func string(for obj: Any?, legIndex: Int?, numberOfLegs: Int?, roadClasses: RoadClasses? = RoadClasses([]), modifyValueByKey: ((TokenType, String) -> String)?) -> String? {
        guard let obj = obj else {
            return nil
        }
        
        var modifyAttributedValueByKey: ((TokenType, NSAttributedString) -> NSAttributedString)?
        if let modifyValueByKey = modifyValueByKey {
            modifyAttributedValueByKey = { (key: TokenType, value: NSAttributedString) -> NSAttributedString in
                return NSAttributedString(string: modifyValueByKey(key, value.string))
            }
        }
        return attributedString(for: obj, legIndex: legIndex, numberOfLegs: numberOfLegs, roadClasses: roadClasses, modifyValueByKey: modifyAttributedValueByKey)?.string
    }
    
    /**
     Creates an instruction as an attributed string given a step and options.
     
     - parameter obj: The step to format.
     - parameter attrs: The default attributes to use for the returned attributed string.
     - parameter legIndex: Current leg index the user is currently on.
     - parameter numberOfLegs: Total number of `RouteLeg` for the given `Route`.
     - parameter roadClasses: Option set representing the classes of road for the `RouteStep`.
     - parameter modifyValueByKey: Allows for mutating the instruction at given parts of the instruction.
     - returns: An instruction as an `NSAttributedString`.
     */
    public func attributedString(for obj: Any, withDefaultAttributes attrs: [NSAttributedStringKey: Any]? = nil, legIndex: Int?, numberOfLegs: Int?, roadClasses: RoadClasses? = RoadClasses([]), modifyValueByKey: ((TokenType, NSAttributedString) -> NSAttributedString)?) -> NSAttributedString? {
        guard let step = obj as? RouteStep else {
            return nil
        }
        
        var type = step.maneuverType
        let modifier = step.maneuverDirection.description
        let mode = step.transportType

        if type != .depart && type != .arrive && modifier == .none {
            return nil
        }

        if instructions[type.description] == nil {
            // OSRM specification assumes turn types can be added without
            // major version changes. Unknown types are to be treated as
            // type `turn` by clients
            type = .turn
        }

        var instructionObject: InstructionsByToken
        var rotaryName = ""
        var wayName: NSAttributedString
        switch type {
        case .takeRotary, .takeRoundabout:
            // Special instruction types have an intermediate level keyed to “default”.
            let instructionsByModifier = instructions[type.description] as! [String: InstructionsByModifier]
            let defaultInstructions = instructionsByModifier["default"]!
            
            wayName = NSAttributedString(string: step.exitNames?.first ?? "", attributes: attrs)
            if let _rotaryName = step.names?.first, let _ = step.exitIndex, let obj = defaultInstructions["name_exit"] {
                instructionObject = obj
                rotaryName = _rotaryName
            } else if let _rotaryName = step.names?.first, let obj = defaultInstructions["name"] {
                instructionObject = obj
                rotaryName = _rotaryName
            } else if let _ = step.exitIndex, let obj = defaultInstructions["exit"] {
                instructionObject = obj
            } else {
                instructionObject = defaultInstructions["default"]!
            }
        default:
            var typeInstructions = instructions[type.description] as! InstructionsByModifier
            let modesInstructions = instructions["modes"] as? InstructionsByModifier
            if let modesInstructions = modesInstructions, let modesInstruction = modesInstructions[mode.description] {
                instructionObject = modesInstruction
            } else if let typeInstruction = typeInstructions[modifier] {
                instructionObject = typeInstruction
            } else {
                instructionObject = typeInstructions["default"]!
            }
            
            // Set wayName
            let name = step.names?.first
            let ref = step.codes?.first
            let isMotorway = roadClasses?.contains(.motorway) ?? false
            
            if let name = name, let ref = ref, name != ref, !isMotorway {
                let attributedName = NSAttributedString(string: name, attributes: attrs)
                let attributedRef = NSAttributedString(string: ref, attributes: attrs)
                let phrase = NSAttributedString(string: self.phrase(named: .nameWithCode), attributes: attrs)
                wayName = phrase.replacingTokens(using: { (tokenType) -> NSAttributedString in
                    switch tokenType {
                    case .wayName:
                        return modifyValueByKey?(.wayName, attributedName) ?? attributedName
                    case .code:
                        return modifyValueByKey?(.code, attributedRef) ?? attributedRef
                    default:
                        fatalError("Unexpected token type \(tokenType) in name-and-ref phrase")
                    }
                })
            } else if let ref = ref, isMotorway, let decimalRange = ref.rangeOfCharacter(from: .decimalDigits), !decimalRange.isEmpty {
                let attributedRef = NSAttributedString(string: ref, attributes: attrs)
                if let modifyValueByKey = modifyValueByKey {
                    wayName = modifyValueByKey(.code, attributedRef)
                } else {
                    wayName = attributedRef
                }
            } else if name == nil, let ref = ref {
                let attributedRef = NSAttributedString(string: ref, attributes: attrs)
                if let modifyValueByKey = modifyValueByKey {
                    wayName = modifyValueByKey(.code, attributedRef)
                } else {
                    wayName = attributedRef
                }
            } else if let name = name {
                let attributedName = NSAttributedString(string: name, attributes: attrs)
                if let modifyValueByKey = modifyValueByKey {
                    wayName = modifyValueByKey(.wayName, attributedName)
                } else {
                    wayName = attributedName
                }
            } else {
                wayName = NSAttributedString()
            }
        }

        // Special case handling
        var laneInstruction: String?
        switch type {
        case .useLane:
            var laneConfig: String?
            if let intersection = step.intersections?.first {
                laneConfig = self.laneConfig(intersection: intersection)
            }
            let laneInstructions = constants["lanes"] as! [String: String]
            laneInstruction = laneInstructions[laneConfig ?? ""]

            if laneInstruction == nil {
                // Lane configuration is not found, default to continue
                let useLaneConfiguration = instructions["use lane"] as! InstructionsByModifier
                instructionObject = useLaneConfiguration["no_lanes"]!
            }
        default:
            break
        }

        // Decide which instruction string to use
        // Destination takes precedence over name
        var instruction: String
        if let _ = step.destinations ?? step.destinationCodes, let _ = step.exitCodes?.first, let obj = instructionObject["exit_destination"] {
            instruction = obj
        } else if let _ = step.destinations ?? step.destinationCodes, let obj = instructionObject["destination"] {
            instruction = obj
        } else if let _ = step.exitCodes?.first, let obj = instructionObject["exit"] {
            instruction = obj
        } else if !wayName.string.isEmpty, let obj = instructionObject["name"] {
            instruction = obj
        } else {
            instruction = instructionObject["default"]!
        }

        // Prepare token replacements
        var nthWaypoint: String? = nil
        if let legIndex = legIndex, let numberOfLegs = numberOfLegs, legIndex != numberOfLegs - 1 {
            nthWaypoint = ordinalFormatter.string(from: (legIndex + 1) as NSNumber)
        }
        let exitCode = step.exitCodes?.first ?? ""
        let destination = [step.destinationCodes, step.destinations].flatMap { $0?.first }.joined(separator: ": ")
        var exitOrdinal: String = ""
        if let exitIndex = step.exitIndex, exitIndex <= 10 {
            exitOrdinal = ordinalFormatter.string(from: exitIndex as NSNumber)!
        }
        let modifierConstants = constants["modifier"] as! [String: String]
        let modifierConstant = modifierConstants[modifier == "none" ? "straight" : modifier]!
        var bearing: Int? = nil
        if step.finalHeading != nil { bearing = Int(step.finalHeading! as Double) }

        // Replace tokens
        let result = NSAttributedString(string: instruction, attributes: attrs).replacingTokens { (tokenType) -> NSAttributedString in
            var replacement: String
            switch tokenType {
            case .code: replacement = step.codes?.first ?? ""
            case .wayName: replacement = "" // ignored
            case .destination: replacement = destination
            case .exitCode: replacement = exitCode
            case .exitIndex: replacement = exitOrdinal
            case .rotaryName: replacement = rotaryName
            case .laneInstruction: replacement = laneInstruction ?? ""
            case .modifier: replacement = modifierConstant
            case .direction: replacement = directionFromDegree(degree: bearing)
            case .wayPoint: replacement = nthWaypoint ?? ""
            case .firstInstruction, .secondInstruction, .distance:
                fatalError("Unexpected token type \(tokenType) in individual instruction")
            }
            if tokenType == .wayName {
                return wayName // already modified above
            } else {
                let attributedReplacement = NSAttributedString(string: replacement, attributes: attrs)
                return modifyValueByKey?(tokenType, attributedReplacement) ?? attributedReplacement
            }
        }
        
        return result
    }
    
    override public func getObjectValue(_ obj: AutoreleasingUnsafeMutablePointer<AnyObject?>?, for string: String, errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>?) -> Bool {
        return false
    }
}
