import Foundation

/// A single World Cup match, decoded from the openfootball `worldcup.json` format.
///
/// The wire format is awkward to use directly (kickoff split across two strings,
/// scores as `[Int]` arrays, the stage encoded across `round` and `group`), so
/// decoding converts it into types the rest of the app can rely on.
struct Match: Identifiable, Hashable {
    let id: String
    let stage: Stage
    let kickoff: Date
    let homeTeam: String
    let awayTeam: String
    let score: Score
    let homeGoals: [Goal]
    let awayGoals: [Goal]
    let venue: String
}

// MARK: - Stage

enum Stage: Hashable {
    case group(String)
    case roundOf32
    case roundOf16
    case quarterFinal
    case semiFinal
    case thirdPlace
    case final

    /// Group matches carry a `group` value; knockout matches are identified by `round`.
    /// Returns nil for a round name we don't recognise, so bad data fails loudly.
    init?(round: String, group: String?) {
        if let group {
            self = .group(group)
            return
        }
        switch round {
        case "Round of 32": self = .roundOf32
        case "Round of 16": self = .roundOf16
        case "Quarter-final": self = .quarterFinal
        case "Semi-final": self = .semiFinal
        case "Match for third place": self = .thirdPlace
        case "Final": self = .final
        default: return nil
        }
    }
}

// MARK: - Score

/// Goals for the home and away side.
struct ScoreLine: Hashable, Decodable {
    let home: Int
    let away: Int

    init(home: Int, away: Int) {
        self.home = home
        self.away = away
    }

    /// The feed encodes a score as a two-element array: `[home, away]`.
    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        guard container.count == 2 else {
            throw DecodingError.dataCorrupted(.init(
                codingPath: decoder.codingPath,
                debugDescription: "Expected a [home, away] pair"
            ))
        }
        home = try container.decode(Int.self)
        away = try container.decode(Int.self)
    }
}

struct Score: Hashable, Decodable {
    let fullTime: ScoreLine
    let halfTime: ScoreLine
    /// Score after extra time, present only if the match went to extra time.
    let extraTime: ScoreLine?
    /// Penalty shootout score, present only if the match was decided on penalties.
    let penalties: ScoreLine?

    init(fullTime: ScoreLine, halfTime: ScoreLine, extraTime: ScoreLine? = nil, penalties: ScoreLine? = nil) {
        self.fullTime = fullTime
        self.halfTime = halfTime
        self.extraTime = extraTime
        self.penalties = penalties
    }

    private enum CodingKeys: String, CodingKey {
        case fullTime = "ft"
        case halfTime = "ht"
        case extraTime = "et"
        case penalties = "p"
    }
}

// MARK: - Goal

struct Goal: Hashable, Decodable {
    let scorer: String
    /// Kept as text because stoppage time is written like "90+6".
    let minute: String
    let isPenalty: Bool
    let isOwnGoal: Bool

    init(scorer: String, minute: String, isPenalty: Bool = false, isOwnGoal: Bool = false) {
        self.scorer = scorer
        self.minute = minute
        self.isPenalty = isPenalty
        self.isOwnGoal = isOwnGoal
    }

    private enum CodingKeys: String, CodingKey {
        case scorer = "name"
        case minute
        case penalty
        case ownGoal = "owngoal"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        scorer = try container.decode(String.self, forKey: .scorer)
        minute = try container.decode(String.self, forKey: .minute)
        isPenalty = try container.decodeIfPresent(Bool.self, forKey: .penalty) ?? false
        isOwnGoal = try container.decodeIfPresent(Bool.self, forKey: .ownGoal) ?? false
    }
}

// MARK: - Decoding

extension Match: Decodable {
    private enum CodingKeys: String, CodingKey {
        case number = "num"
        case round, group, date, time
        case team1, team2
        case score
        case goals1, goals2
        case ground
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let round = try container.decode(String.self, forKey: .round)
        let group = try container.decodeIfPresent(String.self, forKey: .group)
        guard let stage = Stage(round: round, group: group) else {
            throw DecodingError.dataCorruptedError(
                forKey: .round, in: container,
                debugDescription: "Unknown round \"\(round)\""
            )
        }

        let date = try container.decode(String.self, forKey: .date)
        let time = try container.decode(String.self, forKey: .time)
        guard let kickoff = KickoffParser.parse(date: date, time: time) else {
            throw DecodingError.dataCorruptedError(
                forKey: .time, in: container,
                debugDescription: "Could not parse kickoff \"\(date) \(time)\""
            )
        }

        let home = try container.decode(String.self, forKey: .team1)
        let away = try container.decode(String.self, forKey: .team2)

        // Only knockout matches have a match number, so group matches get a
        // stable id built from the fixture itself.
        let number = try container.decodeIfPresent(Int.self, forKey: .number)

        self.id = number.map { "match-\($0)" } ?? "\(date)-\(home)-\(away)"
        self.stage = stage
        self.kickoff = kickoff
        self.homeTeam = home
        self.awayTeam = away
        self.score = try container.decode(Score.self, forKey: .score)
        // Goal lists are omitted entirely for some goalless matches.
        self.homeGoals = try container.decodeIfPresent([Goal].self, forKey: .goals1) ?? []
        self.awayGoals = try container.decodeIfPresent([Goal].self, forKey: .goals2) ?? []
        self.venue = try container.decode(String.self, forKey: .ground)
    }
}
