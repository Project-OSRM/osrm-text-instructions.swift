import Foundation

/**
 Name of a phrase.
 
 Use this type with `OSRMInstructionFormatter.phrase(named:)`.
 */
@objc(OSRMPhraseName)
public enum PhraseName: Int, CustomStringConvertible {
    case instructionWithDistance
    case twoInstructions
    case twoInstructionsWithDistance
    case nameWithCode
    
    public init?(description: String) {
        let name: PhraseName
        switch description {
        case "one in distance":
            name = .instructionWithDistance
        case "two linked":
            name = .twoInstructions
        case "two linked by distance":
            name = .twoInstructionsWithDistance
        case "name and ref":
            name = .nameWithCode
        default:
            return nil
        }
        self.init(rawValue: name.rawValue)
    }
    
    public var description: String {
        switch self {
        case .instructionWithDistance:
            return "one in distance"
        case .twoInstructions:
            return "two linked"
        case .twoInstructionsWithDistance:
            return "two linked by distance"
        case .nameWithCode:
            return "name and ref"
        }
    }
}
