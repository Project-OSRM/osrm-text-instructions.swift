import Foundation

@objc(OSRMTokenType)
public enum TokenType: Int, CustomStringConvertible {
    // For individual instructions
    case wayName
    case destination
    case rotaryName
    case exitCode
    case exitIndex
    case laneInstruction
    case modifier
    case direction
    case wayPoint
    case code
    
    // For phrases
    case firstInstruction
    case secondInstruction
    case distance
    
    public init?(description: String) {
        let type: TokenType
        switch description {
        case "way_name", "name":
            type = .wayName
        case "destination":
            type = .destination
        case "rotary_name":
            type = .rotaryName
        case "exit":
            type = .exitCode
        case "exit_number":
            type = .exitIndex
        case "lane_instruction":
            type = .laneInstruction
        case "modifier":
            type = .modifier
        case "direction":
            type = .direction
        case "nth":
            type = .wayPoint
        case "ref":
            type = .code
        case "instruction_one":
            type = .firstInstruction
        case "instruction_two":
            type = .secondInstruction
        case "distance":
            type = .distance
        default:
            return nil
        }
        self.init(rawValue: type.rawValue)
    }
    
    public var description: String {
        switch self {
        case .wayName:
            return "way_name"
        case .destination:
            return "destination"
        case .rotaryName:
            return "rotary_name"
        case .exitCode:
            return "exit"
        case .exitIndex:
            return "exit_number"
        case .laneInstruction:
            return "lane_instruction"
        case .modifier:
            return "modifier"
        case .direction:
            return "direction"
        case .wayPoint:
            return "nth"
        case .code:
            return "ref"
        case .firstInstruction:
            return "instruction_one"
        case .secondInstruction:
            return "instruction_two"
        case .distance:
            return "distance"
        }
    }
}
