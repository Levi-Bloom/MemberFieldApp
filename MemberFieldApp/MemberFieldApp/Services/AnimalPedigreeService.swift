import Foundation
import Supabase
import UIKit

struct PedigreeAnimalRecord: Codable, Identifiable, Sendable {
    let id: UUID
    let name: String
    let tagNumber: String
    let scrapieTag: String?
    let farmTag: String?
    let description: String?
    let sireID: UUID?
    let damID: UUID?

    enum CodingKeys: String, CodingKey {
        case id, name, description
        case tagNumber = "tag_number"
        case scrapieTag = "scrapie_tag"
        case farmTag = "farm_tag"
        case sireID = "sire_id"
        case damID = "dam_id"
    }
}

struct PedigreeSnapshotResult: Sendable {
    let generations: [[PedigreeAnimalRecord?]]
    let hasPedigree: Bool
    let generationCount: Int
}

enum AnimalPedigreeError: LocalizedError {
    case animalNotFound
    case noPedigree

    var errorDescription: String? {
        switch self {
        case .animalNotFound:
            "This animal could not be found."
        case .noPedigree:
            "No pedigree available. Add a sire or dam to build a family tree."
        }
    }
}

@MainActor
final class AnimalPedigreeService {
    static let defaultGenerationCount = 5
    private static let generationOptions = [3, 5, 10]

    private var client: SupabaseClient { SupabaseManager.shared.client }

    static func normalizeGenerationCount(_ value: Int) -> Int {
        generationOptions.contains(value) ? value : defaultGenerationCount
    }

    static var generationChoices: [Int] {
        generationOptions
    }

    func fetchPedigree(
        animalID: UUID,
        societyID: UUID,
        generationCount: Int = defaultGenerationCount
    ) async throws -> PedigreeSnapshotResult {
        let normalizedCount = Self.normalizeGenerationCount(generationCount)

        let subject: PedigreeSubjectRow = try await client
            .from("animals")
            .select("sire_id, dam_id")
            .eq("id", value: animalID.uuidString)
            .eq("society_id", value: societyID.uuidString)
            .single()
            .execute()
            .value

        guard subject.sireID != nil || subject.damID != nil else {
            return PedigreeSnapshotResult(generations: [], hasPedigree: false, generationCount: normalizedCount)
        }

        var currentIDs: [UUID?] = [subject.sireID, subject.damID]
        var generations: [[PedigreeAnimalRecord?]] = []

        for _ in 0..<normalizedCount {
            let idsToFetch = Array(Set(currentIDs.compactMap { $0 }))
            var animalsByID: [UUID: PedigreeAnimalRecord] = [:]

            if !idsToFetch.isEmpty {
                let animals: [PedigreeAnimalRecord] = try await client
                    .from("animals")
                    .select("id, name, tag_number, scrapie_tag, farm_tag, description, sire_id, dam_id")
                    .in("id", values: idsToFetch.map(\.uuidString))
                    .eq("society_id", value: societyID.uuidString)
                    .execute()
                    .value

                for animal in animals {
                    animalsByID[animal.id] = animal
                }
            }

            let slots = currentIDs.map { id in
                id.flatMap { animalsByID[$0] }
            }
            generations.append(slots)
            currentIDs = slots.flatMap { animal in
                if let animal {
                    return [animal.sireID, animal.damID]
                }
                return [nil, nil]
            }
        }

        return PedigreeSnapshotResult(
            generations: generations,
            hasPedigree: true,
            generationCount: normalizedCount
        )
    }

    func generateSnapshotPDF(
        animal: Animal,
        societyName: String,
        result: PedigreeSnapshotResult
    ) -> Data {
        PedigreeSnapshotPDFGenerator.generate(
            animalName: animal.name,
            tagNumber: animal.tagNumber,
            societyName: societyName,
            result: result
        )
    }

    func snapshotFilename(for tagNumber: String) -> String {
        let safeTag = tagNumber.replacingOccurrences(
            of: "[^A-Za-z0-9.-]+",
            with: "-",
            options: .regularExpression
        )
        return "\(safeTag)-pedigree-snapshot.pdf"
    }
}

private struct PedigreeSubjectRow: Codable {
    let sireID: UUID?
    let damID: UUID?

    enum CodingKeys: String, CodingKey {
        case sireID = "sire_id"
        case damID = "dam_id"
    }
}

private enum PedigreeSnapshotPDFGenerator {
    private static let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
    private static let margin: CGFloat = 40

    static func generate(
        animalName: String,
        tagNumber: String,
        societyName: String,
        result: PedigreeSnapshotResult
    ) -> Data {
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        return renderer.pdfData { context in
            context.beginPage()
            var y = margin

            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 18, weight: .bold),
                .foregroundColor: UIColor.black,
            ]
            let subtitleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 11),
                .foregroundColor: UIColor.gray,
            ]

            ("Pedigree Snapshot" as NSString).draw(at: CGPoint(x: margin, y: y), withAttributes: titleAttributes)
            y += 24
            ("\(animalName) (\(tagNumber))" as NSString).draw(at: CGPoint(x: margin, y: y), withAttributes: subtitleAttributes)
            y += 16
            (societyName as NSString).draw(at: CGPoint(x: margin, y: y), withAttributes: subtitleAttributes)
            y += 28

            for (index, generation) in result.generations.enumerated() {
                let heading = "Generation \(index + 1)"
                (heading as NSString).draw(
                    at: CGPoint(x: margin, y: y),
                    withAttributes: [
                        .font: UIFont.systemFont(ofSize: 12, weight: .semibold),
                        .foregroundColor: UIColor.black,
                    ]
                )
                y += 18

                for (slotIndex, record) in generation.enumerated() {
                    if y > pageRect.height - margin - 40 {
                        context.beginPage()
                        y = margin
                    }

                    let role = slotIndex % 2 == 0 ? "Sire line" : "Dam line"
                    let line: String
                    if let record {
                        let details = [record.tagNumber, record.scrapieTag, record.farmTag]
                            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
                            .filter { !$0.isEmpty }
                            .joined(separator: " · ")
                        line = "\(role): \(record.name) (\(details))"
                    } else {
                        line = "\(role): No data available"
                    }

                    let rect = CGRect(x: margin, y: y, width: pageRect.width - margin * 2, height: 100)
                    (line as NSString).draw(
                        with: rect,
                        options: [.usesLineFragmentOrigin, .usesFontLeading],
                        attributes: [
                            .font: UIFont.systemFont(ofSize: 10),
                            .foregroundColor: UIColor.darkGray,
                        ],
                        context: nil
                    )
                    y += 28
                }

                y += 8
            }
        }
    }
}
