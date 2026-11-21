import Foundation

/// One team's record within its group.
struct Standing: Identifiable, Hashable {
    let team: String
    private(set) var played = 0
    private(set) var won = 0
    private(set) var drawn = 0
    private(set) var lost = 0
    private(set) var goalsFor = 0
    private(set) var goalsAgainst = 0

    var id: String { team }
    var goalDifference: Int { goalsFor - goalsAgainst }
    var points: Int { won * 3 + drawn }

    init(team: String) {
        self.team = team
    }

    /// Records one finished match from this team's point of view.
    mutating func record(goalsFor scored: Int, goalsAgainst conceded: Int) {
        played += 1
        goalsFor += scored
        goalsAgainst += conceded
        if scored > conceded {
            won += 1
        } else if scored == conceded {
            drawn += 1
        } else {
            lost += 1
        }
    }
}

/// A group's table, best team first.
struct GroupTable: Identifiable, Hashable {
    let name: String
    let standings: [Standing]

    var id: String { name }
}
