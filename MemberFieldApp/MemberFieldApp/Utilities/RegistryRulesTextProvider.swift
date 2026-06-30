import Foundation
import PDFKit

enum RegistryRulesTextProvider {
    private static let resourceName = "RegistrationRules"

    /// Society names baked into the template PDF, longest matches first.
    private static let templateSocietyPhrases = [
        "AMERICAN OXFORD SHEEP ASSOCIATION, INC. RECORD.",
        "AMERICAN OXFORD SHEEP ASSOCIATION, INC.",
        "American Oxford Sheep Association Records",
        "American Oxford Sheep Association Record",
        "American Oxford Sheep Association, Inc.",
        "American Oxford Sheep Association.",
        "American Oxford Sheep Association",
        "American Association",
    ]

    private static let splitLinePatterns = [
        ("AMERICAN\nOXFORD SHEEP ASSOCIATION", "AMERICAN OXFORD SHEEP ASSOCIATION"),
        ("American\nOxford Sheep Association", "American Oxford Sheep Association"),
    ]

    static func personalizedRulesText(societyName: String) -> String {
        guard let rawText = extractPDFText(), !rawText.isEmpty else {
            return "The rules document is unavailable right now. Please try again later."
        }

        var text = rawText
        for (pattern, replacement) in splitLinePatterns {
            text = text.replacingOccurrences(of: pattern, with: replacement, options: .caseInsensitive)
        }

        for phrase in templateSocietyPhrases {
            text = replaceCaseInsensitive(in: text, phrase, with: societyName)
        }

        return formatForDisplay(text)
    }

    private static func extractPDFText() -> String? {
        guard let url = Bundle.main.url(forResource: resourceName, withExtension: "pdf"),
              let document = PDFDocument(url: url) else {
            return nil
        }

        return (0..<document.pageCount)
            .compactMap { document.page(at: $0)?.string?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: "\n\n")
    }

    private static func replaceCaseInsensitive(in text: String, _ target: String, with replacement: String) -> String {
        text.replacingOccurrences(of: target, with: replacement, options: .caseInsensitive)
    }

    private static func formatForDisplay(_ text: String) -> String {
        let lines = text.components(separatedBy: .newlines)
        var paragraphs: [String] = []
        var current = ""

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty {
                if !current.isEmpty {
                    paragraphs.append(current.trimmingCharacters(in: .whitespaces))
                    current = ""
                }
                continue
            }

            if current.isEmpty {
                current = trimmed
                continue
            }

            if shouldContinueParagraph(previous: current, next: trimmed) {
                current += " " + trimmed
            } else {
                paragraphs.append(current.trimmingCharacters(in: .whitespaces))
                current = trimmed
            }
        }

        if !current.isEmpty {
            paragraphs.append(current.trimmingCharacters(in: .whitespaces))
        }

        return paragraphs.joined(separator: "\n\n")
    }

    private static func shouldContinueParagraph(previous: String, next: String) -> Bool {
        if next.hasPrefix("(") { return true }
        if next.first?.isNumber == true, next.contains(".") { return false }
        if previous.hasSuffix("-") { return true }

        let previousEndsSentence = previous.hasSuffix(".")
            || previous.hasSuffix("!")
            || previous.hasSuffix("?")
            || previous.hasSuffix(":")
        if previousEndsSentence, next.first?.isUppercase == true {
            return false
        }

        return next.first?.isLowercase == true
    }
}
