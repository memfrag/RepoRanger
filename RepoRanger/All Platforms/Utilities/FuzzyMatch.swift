//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import Foundation

/// Returns a match score (lower is better) if `pattern` fuzzy-matches `text`,
/// or `nil` if not all pattern characters are found in order.
func fuzzyMatch(pattern: String, text: String) -> Int? {
    guard !pattern.isEmpty else { return 0 }

    let patternChars = Array(pattern.lowercased())
    let textChars = Array(text.lowercased())
    let originalChars = Array(text)

    var patternIndex = 0
    var score = 0
    var previousMatchIndex: Int?
    var firstMatchIndex: Int?

    for textIndex in textChars.indices {
        guard patternIndex < patternChars.count else { break }

        if textChars[textIndex] == patternChars[patternIndex] {
            if firstMatchIndex == nil {
                firstMatchIndex = textIndex
            }

            // Reward: match at the very start of the string
            if textIndex == 0 {
                score -= 10
            }

            // Reward: match at a word boundary
            if textIndex > 0 {
                let prev = originalChars[textIndex - 1]
                if prev == "/" || prev == "-" || prev == "_" || prev == "." {
                    score -= 5
                } else if prev.isLowercase && originalChars[textIndex].isUppercase {
                    // camelCase boundary
                    score -= 5
                }
            }

            if let prevMatch = previousMatchIndex {
                let gap = textIndex - prevMatch - 1
                if gap == 0 {
                    // Reward: consecutive match
                    score -= 3
                } else {
                    // Penalize: gap between matches
                    score += gap
                }
            }

            // Penalize: match deeper into the string
            score += textIndex / 5

            previousMatchIndex = textIndex
            patternIndex += 1
        }
    }

    guard patternIndex == patternChars.count else { return nil }

    // Reward: first pattern character matches first character of text
    if firstMatchIndex == 0 {
        score -= 15
    }

    return score
}
