import Foundation

extension Score {
    /// The score after all play: extra time if it was needed, otherwise full time.
    var played: ScoreLine { extraTime ?? fullTime }

    /// Short result text: "2–0", "1–0 aet", or "1–1 (3–4 pens)".
    var summary: String {
        var text = "\(played.home)–\(played.away)"
        if let penalties {
            text += " (\(penalties.home)–\(penalties.away) pens)"
        } else if extraTime != nil {
            text += " aet"
        }
        return text
    }
}

extension Score {
    /// Extra context shown under a result, or nil for a normal 90-minute match.
    var note: String? {
        if let penalties { return "\(penalties.home)–\(penalties.away) on penalties" }
        if extraTime != nil { return "After extra time" }
        return nil
    }
}

extension Int {
    /// 1 -> "1st", 2 -> "2nd", 3 -> "3rd", 4 -> "4th", 11 -> "11th".
    var ordinal: String {
        let suffix: String
        switch self % 100 {
        case 11, 12, 13: suffix = "th"
        default:
            switch self % 10 {
            case 1: suffix = "st"
            case 2: suffix = "nd"
            case 3: suffix = "rd"
            default: suffix = "th"
            }
        }
        return "\(self)\(suffix)"
    }
}

extension Stage {
    /// Label shown on a match: "Group A", "Quarter-final", and so on.
    var title: String {
        switch self {
        case .group(let name): return name
        case .roundOf32: return "Round of 32"
        case .roundOf16: return "Round of 16"
        case .quarterFinal: return "Quarter-final"
        case .semiFinal: return "Semi-final"
        case .thirdPlace: return "Third place"
        case .final: return "Final"
        }
    }
}
