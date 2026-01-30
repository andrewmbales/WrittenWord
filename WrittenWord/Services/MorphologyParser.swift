//
//  MorphologyParser.swift
//  WrittenWord
//
//  Service for parsing morphology codes into human-readable explanations
//

import Foundation

struct MorphologyParser {

    /// Parsed morphology information
    struct ParsedMorphology {
        let partOfSpeech: String
        let fullDescription: String
        let grammaticalDetails: [GrammaticalDetail]
        let icon: String
        let color: String // Color name for visual coding
    }

    /// Individual grammatical detail with explanation
    struct GrammaticalDetail {
        let term: String
        let value: String
        let explanation: String
    }

    /// Parse a morphology code into human-readable form
    /// Supports both Greek (Robinson) and Hebrew morphology codes
    static func parse(_ morphology: String) -> ParsedMorphology {
        // Common format: "Noun - Dative Feminine Singular" or "V-AAI-3S"

        // Check if it's already human-readable
        if morphology.contains("-") && morphology.split(separator: "-").count <= 2 {
            return parseReadableFormat(morphology)
        }

        // Otherwise, parse compact codes (e.g., "V-AAI-3S")
        return parseCompactFormat(morphology)
    }

    /// Parse human-readable format like "Noun - Dative Feminine Singular"
    private static func parseReadableFormat(_ morphology: String) -> ParsedMorphology {
        let parts = morphology.split(separator: "-").map { $0.trimmingCharacters(in: .whitespaces) }

        guard let posString = parts.first else {
            return createUnknownMorphology(morphology)
        }

        let pos = posString.lowercased()
        var details: [GrammaticalDetail] = []

        // Determine part of speech
        if pos.contains("noun") {
            if parts.count > 1 {
                details = parseNounDetails(parts[1])
            }
            return ParsedMorphology(
                partOfSpeech: "Noun",
                fullDescription: buildNounDescription(details),
                grammaticalDetails: details,
                icon: "n.square.fill",
                color: "green"
            )
        } else if pos.contains("verb") {
            if parts.count > 1 {
                details = parseVerbDetails(parts[1])
            }
            return ParsedMorphology(
                partOfSpeech: "Verb",
                fullDescription: buildVerbDescription(details),
                grammaticalDetails: details,
                icon: "v.square.fill",
                color: "blue"
            )
        } else if pos.contains("adjective") {
            if parts.count > 1 {
                details = parseAdjectiveDetails(parts[1])
            }
            return ParsedMorphology(
                partOfSpeech: "Adjective",
                fullDescription: buildAdjectiveDescription(details),
                grammaticalDetails: details,
                icon: "a.square.fill",
                color: "orange"
            )
        } else if pos.contains("pronoun") {
            return ParsedMorphology(
                partOfSpeech: "Pronoun",
                fullDescription: "A word that substitutes for a noun",
                grammaticalDetails: [],
                icon: "p.square.fill",
                color: "purple"
            )
        } else if pos.contains("article") {
            return ParsedMorphology(
                partOfSpeech: "Article",
                fullDescription: "The definite article (the)",
                grammaticalDetails: [],
                icon: "textformat",
                color: "gray"
            )
        } else if pos.contains("preposition") {
            return ParsedMorphology(
                partOfSpeech: "Preposition",
                fullDescription: "A word expressing spatial or temporal relations",
                grammaticalDetails: [],
                icon: "arrow.triangle.turn.up.right.diamond.fill",
                color: "cyan"
            )
        } else if pos.contains("conjunction") {
            return ParsedMorphology(
                partOfSpeech: "Conjunction",
                fullDescription: "A connecting word (and, but, or)",
                grammaticalDetails: [],
                icon: "link",
                color: "indigo"
            )
        }

        return createUnknownMorphology(morphology)
    }

    /// Parse compact format like "V-AAI-3S" (Greek Robinson codes)
    private static func parseCompactFormat(_ morphology: String) -> ParsedMorphology {
        let parts = morphology.split(separator: "-").map { String($0) }

        guard let firstPart = parts.first else {
            return createUnknownMorphology(morphology)
        }

        // First character is usually the part of speech
        let posCode = String(firstPart.prefix(1))

        switch posCode {
        case "N":
            return parseNounCode(morphology, parts: parts)
        case "V":
            return parseVerbCode(morphology, parts: parts)
        case "A":
            return parseAdjectiveCode(morphology, parts: parts)
        case "P":
            return parsePronounCode(morphology, parts: parts)
        case "D":
            return parseArticleCode(morphology, parts: parts)
        case "C":
            return parseConjunctionCode(morphology)
        case "R":
            return parsePrepositionCode(morphology)
        default:
            return createUnknownMorphology(morphology)
        }
    }

    // MARK: - Noun Parsing

    private static func parseNounDetails(_ detailString: String) -> [GrammaticalDetail] {
        var details: [GrammaticalDetail] = []
        let lower = detailString.lowercased()

        // Case
        if lower.contains("nominative") {
            details.append(GrammaticalDetail(
                term: "Case",
                value: "Nominative",
                explanation: "Subject of the sentence or predicate nominative"
            ))
        } else if lower.contains("genitive") {
            details.append(GrammaticalDetail(
                term: "Case",
                value: "Genitive",
                explanation: "Possession or description (of, from)"
            ))
        } else if lower.contains("dative") {
            details.append(GrammaticalDetail(
                term: "Case",
                value: "Dative",
                explanation: "Indirect object (to, for, by)"
            ))
        } else if lower.contains("accusative") {
            details.append(GrammaticalDetail(
                term: "Case",
                value: "Accusative",
                explanation: "Direct object of the verb"
            ))
        } else if lower.contains("vocative") {
            details.append(GrammaticalDetail(
                term: "Case",
                value: "Vocative",
                explanation: "Direct address (O Lord, etc.)"
            ))
        }

        // Gender
        if lower.contains("masculine") {
            details.append(GrammaticalDetail(
                term: "Gender",
                value: "Masculine",
                explanation: "Grammatical masculine gender"
            ))
        } else if lower.contains("feminine") {
            details.append(GrammaticalDetail(
                term: "Gender",
                value: "Feminine",
                explanation: "Grammatical feminine gender"
            ))
        } else if lower.contains("neuter") {
            details.append(GrammaticalDetail(
                term: "Gender",
                value: "Neuter",
                explanation: "Grammatical neuter gender"
            ))
        }

        // Number
        if lower.contains("singular") {
            details.append(GrammaticalDetail(
                term: "Number",
                value: "Singular",
                explanation: "One item"
            ))
        } else if lower.contains("plural") {
            details.append(GrammaticalDetail(
                term: "Number",
                value: "Plural",
                explanation: "Multiple items"
            ))
        }

        return details
    }

    private static func parseNounCode(_ morphology: String, parts: [String]) -> ParsedMorphology {
        var details: [GrammaticalDetail] = []

        // Example: N-NSF = Noun-Nominative Singular Feminine
        if parts.count > 1 {
            let attributes = parts[1]
            if attributes.count >= 3 {
                let caseCode = String(attributes.prefix(1))
                let numberCode = String(attributes.dropFirst().prefix(1))
                let genderCode = String(attributes.dropFirst(2).prefix(1))

                // Parse case
                switch caseCode {
                case "N": details.append(GrammaticalDetail(term: "Case", value: "Nominative", explanation: "Subject of the sentence"))
                case "G": details.append(GrammaticalDetail(term: "Case", value: "Genitive", explanation: "Possession (of, from)"))
                case "D": details.append(GrammaticalDetail(term: "Case", value: "Dative", explanation: "Indirect object (to, for)"))
                case "A": details.append(GrammaticalDetail(term: "Case", value: "Accusative", explanation: "Direct object"))
                case "V": details.append(GrammaticalDetail(term: "Case", value: "Vocative", explanation: "Direct address"))
                default: break
                }

                // Parse number
                switch numberCode {
                case "S": details.append(GrammaticalDetail(term: "Number", value: "Singular", explanation: "One item"))
                case "P": details.append(GrammaticalDetail(term: "Number", value: "Plural", explanation: "Multiple items"))
                default: break
                }

                // Parse gender
                switch genderCode {
                case "M": details.append(GrammaticalDetail(term: "Gender", value: "Masculine", explanation: "Masculine gender"))
                case "F": details.append(GrammaticalDetail(term: "Gender", value: "Feminine", explanation: "Feminine gender"))
                case "N": details.append(GrammaticalDetail(term: "Gender", value: "Neuter", explanation: "Neuter gender"))
                default: break
                }
            }
        }

        return ParsedMorphology(
            partOfSpeech: "Noun",
            fullDescription: buildNounDescription(details),
            grammaticalDetails: details,
            icon: "n.square.fill",
            color: "green"
        )
    }

    private static func buildNounDescription(_ details: [GrammaticalDetail]) -> String {
        var parts: [String] = []

        if let gender = details.first(where: { $0.term == "Gender" }) {
            parts.append(gender.value.lowercased())
        }

        if let number = details.first(where: { $0.term == "Number" }) {
            parts.append(number.value.lowercased())
        }

        if let caseDetail = details.first(where: { $0.term == "Case" }) {
            parts.append("in the \(caseDetail.value.lowercased()) case")
        }

        if parts.isEmpty {
            return "A noun"
        }

        return "Noun: " + parts.joined(separator: ", ")
    }

    // MARK: - Verb Parsing

    private static func parseVerbDetails(_ detailString: String) -> [GrammaticalDetail] {
        var details: [GrammaticalDetail] = []
        let lower = detailString.lowercased()

        // Tense
        if lower.contains("present") {
            details.append(GrammaticalDetail(
                term: "Tense",
                value: "Present",
                explanation: "Action happening now or ongoing"
            ))
        } else if lower.contains("aorist") {
            details.append(GrammaticalDetail(
                term: "Tense",
                value: "Aorist",
                explanation: "Simple past action, viewed as a whole"
            ))
        } else if lower.contains("imperfect") {
            details.append(GrammaticalDetail(
                term: "Tense",
                value: "Imperfect",
                explanation: "Ongoing action in the past"
            ))
        } else if lower.contains("perfect") {
            details.append(GrammaticalDetail(
                term: "Tense",
                value: "Perfect",
                explanation: "Completed action with present results"
            ))
        } else if lower.contains("future") {
            details.append(GrammaticalDetail(
                term: "Tense",
                value: "Future",
                explanation: "Action that will happen"
            ))
        }

        // Voice
        if lower.contains("active") {
            details.append(GrammaticalDetail(
                term: "Voice",
                value: "Active",
                explanation: "Subject performs the action"
            ))
        } else if lower.contains("passive") {
            details.append(GrammaticalDetail(
                term: "Voice",
                value: "Passive",
                explanation: "Subject receives the action"
            ))
        } else if lower.contains("middle") {
            details.append(GrammaticalDetail(
                term: "Voice",
                value: "Middle",
                explanation: "Subject acts for own benefit"
            ))
        }

        // Mood
        if lower.contains("indicative") {
            details.append(GrammaticalDetail(
                term: "Mood",
                value: "Indicative",
                explanation: "Statement of fact"
            ))
        } else if lower.contains("imperative") {
            details.append(GrammaticalDetail(
                term: "Mood",
                value: "Imperative",
                explanation: "Command or request"
            ))
        } else if lower.contains("subjunctive") {
            details.append(GrammaticalDetail(
                term: "Mood",
                value: "Subjunctive",
                explanation: "Possibility or potential"
            ))
        } else if lower.contains("infinitive") {
            details.append(GrammaticalDetail(
                term: "Mood",
                value: "Infinitive",
                explanation: "Verbal noun (to do)"
            ))
        } else if lower.contains("participle") {
            details.append(GrammaticalDetail(
                term: "Mood",
                value: "Participle",
                explanation: "Verbal adjective (-ing)"
            ))
        }

        return details
    }

    private static func parseVerbCode(_ morphology: String, parts: [String]) -> ParsedMorphology {
        var details: [GrammaticalDetail] = []

        // Example: V-AAI-3S = Verb-Aorist Active Indicative-3rd person Singular
        if parts.count > 1 {
            let tenseVoiceMood = parts[1]
            if tenseVoiceMood.count >= 3 {
                let tenseCode = String(tenseVoiceMood.prefix(1))
                let voiceCode = String(tenseVoiceMood.dropFirst().prefix(1))
                let moodCode = String(tenseVoiceMood.dropFirst(2).prefix(1))

                // Parse tense
                switch tenseCode {
                case "P": details.append(GrammaticalDetail(term: "Tense", value: "Present", explanation: "Action happening now"))
                case "I": details.append(GrammaticalDetail(term: "Tense", value: "Imperfect", explanation: "Ongoing past action"))
                case "F": details.append(GrammaticalDetail(term: "Tense", value: "Future", explanation: "Future action"))
                case "A": details.append(GrammaticalDetail(term: "Tense", value: "Aorist", explanation: "Simple past action"))
                case "X": details.append(GrammaticalDetail(term: "Tense", value: "Perfect", explanation: "Completed with present results"))
                case "Y": details.append(GrammaticalDetail(term: "Tense", value: "Pluperfect", explanation: "Completed before another past action"))
                default: break
                }

                // Parse voice
                switch voiceCode {
                case "A": details.append(GrammaticalDetail(term: "Voice", value: "Active", explanation: "Subject does the action"))
                case "M": details.append(GrammaticalDetail(term: "Voice", value: "Middle", explanation: "Subject acts for self"))
                case "P": details.append(GrammaticalDetail(term: "Voice", value: "Passive", explanation: "Subject receives action"))
                default: break
                }

                // Parse mood
                switch moodCode {
                case "I": details.append(GrammaticalDetail(term: "Mood", value: "Indicative", explanation: "Statement of fact"))
                case "M": details.append(GrammaticalDetail(term: "Mood", value: "Imperative", explanation: "Command"))
                case "S": details.append(GrammaticalDetail(term: "Mood", value: "Subjunctive", explanation: "Possibility"))
                case "N": details.append(GrammaticalDetail(term: "Mood", value: "Infinitive", explanation: "Verbal noun"))
                case "P": details.append(GrammaticalDetail(term: "Mood", value: "Participle", explanation: "Verbal adjective"))
                default: break
                }
            }
        }

        // Parse person and number if available
        if parts.count > 2 {
            let personNumber = parts[2]
            if personNumber.count >= 2 {
                let personCode = String(personNumber.prefix(1))
                let numberCode = String(personNumber.dropFirst().prefix(1))

                switch personCode {
                case "1": details.append(GrammaticalDetail(term: "Person", value: "1st", explanation: "I, we"))
                case "2": details.append(GrammaticalDetail(term: "Person", value: "2nd", explanation: "You"))
                case "3": details.append(GrammaticalDetail(term: "Person", value: "3rd", explanation: "He, she, it, they"))
                default: break
                }

                switch numberCode {
                case "S": details.append(GrammaticalDetail(term: "Number", value: "Singular", explanation: "One person"))
                case "P": details.append(GrammaticalDetail(term: "Number", value: "Plural", explanation: "Multiple people"))
                default: break
                }
            }
        }

        return ParsedMorphology(
            partOfSpeech: "Verb",
            fullDescription: buildVerbDescription(details),
            grammaticalDetails: details,
            icon: "v.square.fill",
            color: "blue"
        )
    }

    private static func buildVerbDescription(_ details: [GrammaticalDetail]) -> String {
        var parts: [String] = []

        if let tense = details.first(where: { $0.term == "Tense" }) {
            parts.append(tense.value)
        }

        if let voice = details.first(where: { $0.term == "Voice" }) {
            parts.append(voice.value)
        }

        if let mood = details.first(where: { $0.term == "Mood" }) {
            parts.append(mood.value)
        }

        if let person = details.first(where: { $0.term == "Person" }) {
            if let number = details.first(where: { $0.term == "Number" }) {
                parts.append("\(person.value) person \(number.value.lowercased())")
            }
        }

        if parts.isEmpty {
            return "A verb"
        }

        return "Verb: " + parts.joined(separator: ", ")
    }

    // MARK: - Adjective Parsing

    private static func parseAdjectiveDetails(_ detailString: String) -> [GrammaticalDetail] {
        // Adjectives have similar details to nouns (case, gender, number)
        return parseNounDetails(detailString)
    }

    private static func parseAdjectiveCode(_ morphology: String, parts: [String]) -> ParsedMorphology {
        var details: [GrammaticalDetail] = []

        if parts.count > 1 {
            let attributes = parts[1]
            if attributes.count >= 3 {
                let caseCode = String(attributes.prefix(1))
                let numberCode = String(attributes.dropFirst().prefix(1))
                let genderCode = String(attributes.dropFirst(2).prefix(1))

                switch caseCode {
                case "N": details.append(GrammaticalDetail(term: "Case", value: "Nominative", explanation: "Describes the subject"))
                case "G": details.append(GrammaticalDetail(term: "Case", value: "Genitive", explanation: "Describes possession"))
                case "D": details.append(GrammaticalDetail(term: "Case", value: "Dative", explanation: "Describes indirect object"))
                case "A": details.append(GrammaticalDetail(term: "Case", value: "Accusative", explanation: "Describes direct object"))
                default: break
                }

                switch numberCode {
                case "S": details.append(GrammaticalDetail(term: "Number", value: "Singular", explanation: "One item"))
                case "P": details.append(GrammaticalDetail(term: "Number", value: "Plural", explanation: "Multiple items"))
                default: break
                }

                switch genderCode {
                case "M": details.append(GrammaticalDetail(term: "Gender", value: "Masculine", explanation: "Masculine gender"))
                case "F": details.append(GrammaticalDetail(term: "Gender", value: "Feminine", explanation: "Feminine gender"))
                case "N": details.append(GrammaticalDetail(term: "Gender", value: "Neuter", explanation: "Neuter gender"))
                default: break
                }
            }
        }

        return ParsedMorphology(
            partOfSpeech: "Adjective",
            fullDescription: buildAdjectiveDescription(details),
            grammaticalDetails: details,
            icon: "a.square.fill",
            color: "orange"
        )
    }

    private static func buildAdjectiveDescription(_ details: [GrammaticalDetail]) -> String {
        var parts: [String] = []

        if let gender = details.first(where: { $0.term == "Gender" }) {
            parts.append(gender.value.lowercased())
        }

        if let number = details.first(where: { $0.term == "Number" }) {
            parts.append(number.value.lowercased())
        }

        if let caseDetail = details.first(where: { $0.term == "Case" }) {
            parts.append("in the \(caseDetail.value.lowercased()) case")
        }

        if parts.isEmpty {
            return "An adjective (describing word)"
        }

        return "Adjective: " + parts.joined(separator: ", ")
    }

    // MARK: - Other Parts of Speech

    private static func parsePronounCode(_ morphology: String, parts: [String]) -> ParsedMorphology {
        return ParsedMorphology(
            partOfSpeech: "Pronoun",
            fullDescription: "A word that substitutes for a noun (he, she, it, they, etc.)",
            grammaticalDetails: [],
            icon: "p.square.fill",
            color: "purple"
        )
    }

    private static func parseArticleCode(_ morphology: String, parts: [String]) -> ParsedMorphology {
        return ParsedMorphology(
            partOfSpeech: "Article",
            fullDescription: "The definite article (the)",
            grammaticalDetails: [],
            icon: "textformat",
            color: "gray"
        )
    }

    private static func parseConjunctionCode(_ morphology: String) -> ParsedMorphology {
        return ParsedMorphology(
            partOfSpeech: "Conjunction",
            fullDescription: "A connecting word (and, but, or, for)",
            grammaticalDetails: [],
            icon: "link",
            color: "indigo"
        )
    }

    private static func parsePrepositionCode(_ morphology: String) -> ParsedMorphology {
        return ParsedMorphology(
            partOfSpeech: "Preposition",
            fullDescription: "A word expressing spatial or temporal relations (in, on, by, with)",
            grammaticalDetails: [],
            icon: "arrow.triangle.turn.up.right.diamond.fill",
            color: "cyan"
        )
    }

    // MARK: - Helper

    private static func createUnknownMorphology(_ original: String) -> ParsedMorphology {
        return ParsedMorphology(
            partOfSpeech: "Unknown",
            fullDescription: original,
            grammaticalDetails: [],
            icon: "questionmark.square.fill",
            color: "gray"
        )
    }
}
