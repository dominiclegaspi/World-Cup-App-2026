import Foundation

/// Turns the feed's local kickoff time into an absolute `Date`.
///
/// The feed gives a date ("2026-06-11") and a time with a UTC offset
/// ("13:00 UTC-6"). Keeping the offset means the same instant can later be
/// shown in the viewer's own time zone.
enum KickoffParser {
    static func parse(date: String, time: String) -> Date? {
        let dateParts = date.split(separator: "-").compactMap { Int($0) }
        let timeParts = time.split(separator: " ")

        guard dateParts.count == 3,
              timeParts.count == 2,
              timeParts[1].hasPrefix("UTC"),
              let clock = hoursAndMinutes(String(timeParts[0])),
              let offset = secondsFromGMT(String(timeParts[1].dropFirst(3))),
              let timeZone = TimeZone(secondsFromGMT: offset)
        else { return nil }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone

        let components = DateComponents(
            year: dateParts[0], month: dateParts[1], day: dateParts[2],
            hour: clock.hours, minute: clock.minutes
        )
        return calendar.date(from: components)
    }

    /// "13:00" -> (13, 0)
    private static func hoursAndMinutes(_ text: String) -> (hours: Int, minutes: Int)? {
        let pieces = text.split(separator: ":")
        let numbers = pieces.compactMap { Int($0) }
        guard pieces.count == 2, numbers.count == 2 else { return nil }
        return (numbers[0], numbers[1])
    }

    /// "-6" -> -21600, "+5:30" -> 19800, "" -> 0 (plain "UTC")
    private static func secondsFromGMT(_ text: String) -> Int? {
        guard let sign = text.first else { return 0 }
        guard sign == "+" || sign == "-" else { return nil }

        let pieces = text.dropFirst().split(separator: ":")
        let numbers = pieces.compactMap { Int($0) }
        guard numbers.count == pieces.count, (1...2).contains(numbers.count) else { return nil }

        let seconds = numbers[0] * 3600 + (numbers.count == 2 ? numbers[1] * 60 : 0)
        return sign == "-" ? -seconds : seconds
    }
}
