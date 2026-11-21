import Foundation

/// Flag emoji for each team name used in the feed.
///
/// The feed gives names only, so country codes are listed here. Most flags are
/// built from two "regional indicator" characters; England and Scotland have no
/// ISO country code and use subdivision flags (a black flag plus tag characters).
enum TeamFlag {
    static let fallback = "🏳️"

    static func emoji(for team: String) -> String {
        if let code = countryCodes[team] { return regionalIndicators(code) }
        if let tag = subdivisionTags[team] { return subdivisionFlag(tag) }
        return fallback
    }

    private static let subdivisionTags = ["England": "gbeng", "Scotland": "gbsct"]

    private static let countryCodes: [String: String] = [
        "Algeria": "DZ", "Argentina": "AR", "Australia": "AU", "Austria": "AT",
        "Belgium": "BE", "Bosnia & Herzegovina": "BA", "Brazil": "BR", "Canada": "CA",
        "Cape Verde": "CV", "Colombia": "CO", "Croatia": "HR", "Curaçao": "CW",
        "Czech Republic": "CZ", "DR Congo": "CD", "Ecuador": "EC", "Egypt": "EG",
        "France": "FR", "Germany": "DE", "Ghana": "GH", "Haiti": "HT",
        "Iran": "IR", "Iraq": "IQ", "Ivory Coast": "CI", "Japan": "JP",
        "Jordan": "JO", "Mexico": "MX", "Morocco": "MA", "Netherlands": "NL",
        "New Zealand": "NZ", "Norway": "NO", "Panama": "PA", "Paraguay": "PY",
        "Portugal": "PT", "Qatar": "QA", "Saudi Arabia": "SA", "Senegal": "SN",
        "South Africa": "ZA", "South Korea": "KR", "Spain": "ES", "Sweden": "SE",
        "Switzerland": "CH", "Tunisia": "TN", "Turkey": "TR", "USA": "US",
        "Uruguay": "UY", "Uzbekistan": "UZ",
    ]

    /// "MX" -> 🇲🇽. Each letter maps to the matching regional indicator symbol.
    private static func regionalIndicators(_ code: String) -> String {
        var result = String()
        for scalar in code.unicodeScalars {
            if let indicator = UnicodeScalar(0x1F1A5 + scalar.value) {
                result.unicodeScalars.append(indicator)
            }
        }
        return result
    }

    /// "gbeng" -> 🏴 + tag letters g,b,e,n,g + cancel tag.
    private static func subdivisionFlag(_ tag: String) -> String {
        var result = String()
        result.unicodeScalars.append(UnicodeScalar(0x1F3F4)!)
        for scalar in tag.unicodeScalars {
            if let tagScalar = UnicodeScalar(0xE0000 + scalar.value) {
                result.unicodeScalars.append(tagScalar)
            }
        }
        result.unicodeScalars.append(UnicodeScalar(0xE007F)!)
        return result
    }
}
