import Foundation
import Supabase
import UIKit

struct AnimalCertificatePayload: Sendable {
    let societyName: String
    let societyBreed: String
    let societyContactEmail: String?
    let societyAddress: String?
    let tagNumber: String
    let name: String
    let animalType: String?
    let registrationStatus: String
    let sex: String
    let dateOfBirth: String?
    let scrapieTag: String?
    let ownerName: String
    let breederName: String
    let sireLabel: String
    let damLabel: String
    let issuedAt: Date
}

private struct CertificateAnimalRow: Codable {
    let tagNumber: String
    let name: String
    let animalType: String?
    let registrationStatus: RegistrationStatus
    let sex: AnimalSex
    let dateOfBirth: String?
    let scrapieTag: String?
    let owner: CertificatePersonRow?
    let breeder: CertificatePersonRow?
    let sire: CertificateParentRow?
    let dam: CertificateParentRow?

    enum CodingKeys: String, CodingKey {
        case name, sex
        case tagNumber = "tag_number"
        case animalType = "animal_type"
        case registrationStatus = "registration_status"
        case dateOfBirth = "date_of_birth"
        case scrapieTag = "scrapie_tag"
        case owner, breeder, sire, dam
    }
}

private struct CertificatePersonRow: Codable {
    let firstName: String
    let lastName: String

    enum CodingKeys: String, CodingKey {
        case firstName = "first_name"
        case lastName = "last_name"
    }

    var fullName: String {
        "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
    }
}

private struct CertificateParentRow: Codable {
    let tagNumber: String
    let name: String

    enum CodingKeys: String, CodingKey {
        case name
        case tagNumber = "tag_number"
    }

    var label: String {
        "\(tagNumber) - \(name)"
    }
}

enum AnimalCertificateError: LocalizedError {
    case mailUnavailable
    case animalNotFound

    var errorDescription: String? {
        switch self {
        case .mailUnavailable:
            "Email is not available on this device. Add a mail account in Settings to email the certificate."
        case .animalNotFound:
            "This animal could not be found."
        }
    }
}

@MainActor
final class AnimalCertificateService {
    private var client: SupabaseClient { SupabaseManager.shared.client }

    func fetchPayload(animalID: UUID, society: Society) async throws -> AnimalCertificatePayload {
        let row: CertificateAnimalRow = try await client
            .from("animals")
            .select(
                """
                tag_number, name, animal_type, registration_status, sex, date_of_birth, scrapie_tag,
                owner:people!owner_id(first_name, last_name),
                breeder:people!breeder_id(first_name, last_name),
                sire:sire_id(tag_number, name),
                dam:dam_id(tag_number, name)
                """
            )
            .eq("id", value: animalID.uuidString)
            .eq("society_id", value: society.id.uuidString)
            .single()
            .execute()
            .value

        return AnimalCertificatePayload(
            societyName: society.name,
            societyBreed: society.breed,
            societyContactEmail: society.contactEmail,
            societyAddress: society.address,
            tagNumber: row.tagNumber,
            name: row.name,
            animalType: row.animalType,
            registrationStatus: registrationStatusLabel(row.registrationStatus),
            sex: row.sex.rawValue.capitalized,
            dateOfBirth: row.dateOfBirth,
            scrapieTag: row.scrapieTag,
            ownerName: row.owner?.fullName ?? "—",
            breederName: row.breeder?.fullName ?? "—",
            sireLabel: row.sire?.label ?? "—",
            damLabel: row.dam?.label ?? "—",
            issuedAt: Date()
        )
    }

    func generatePDF(payload: AnimalCertificatePayload) -> Data {
        AnimalCertificatePDFGenerator.generate(payload: payload)
    }

    func certificateFilename(for tagNumber: String) -> String {
        let safeTag = tagNumber.replacingOccurrences(
            of: "[^A-Za-z0-9.-]+",
            with: "-",
            options: .regularExpression
        )
        return "\(safeTag)-pedigree-certificate.pdf"
    }

    private func registrationStatusLabel(_ status: RegistrationStatus) -> String {
        switch status {
        case .registered: "Registered"
        case .pending: "Pending"
        case .unregistered: "Unregistered"
        case .rejected: "Rejected"
        }
    }
}

private enum AnimalCertificatePDFGenerator {
    private static let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
    private static let margin: CGFloat = 48

    static func generate(payload: AnimalCertificatePayload) -> Data {
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        return renderer.pdfData { context in
            context.beginPage()
            drawCertificate(payload, in: context.cgContext)
        }
    }

    private static func drawCertificate(_ payload: AnimalCertificatePayload, in context: CGContext) {
        var y = margin

        y = drawCentered("REGISTRATION CERTIFICATE", y: y, font: .systemFont(ofSize: 10, weight: .medium), color: .gray)
        y += 18
        y = drawCentered(payload.societyName, y: y, font: .systemFont(ofSize: 22, weight: .bold), color: .black)
        y += 28
        y = drawCentered(payload.societyBreed, y: y, font: .systemFont(ofSize: 12), color: .gray)
        y += 36

        let columnWidth = (pageRect.width - margin * 2) / 2 - 12
        let leftX = margin
        let rightX = margin + columnWidth + 24
        let sectionTop = y

        y = drawSectionTitle("ANIMAL", x: leftX, y: sectionTop)
        y = drawHeading(payload.name, x: leftX, y: y + 8)

        let animalRows: [(String, String)] = [
            ("Reg No", payload.tagNumber),
            ("Type", payload.animalType ?? "—"),
            ("Sex", payload.sex),
            ("Date of birth", MemberDuesCalculator.formatDate(payload.dateOfBirth)),
            ("Scrapie tag", payload.scrapieTag ?? "—"),
            ("Status", payload.registrationStatus),
        ]

        var rowY = y + 12
        for (label, value) in animalRows {
            rowY = drawLabelValue(label: label, value: value, x: leftX, y: rowY, width: columnWidth)
        }

        var ownershipY = drawSectionTitle("OWNERSHIP", x: rightX, y: sectionTop)
        ownershipY += 16

        let ownershipRows: [(String, String)] = [
            ("Owner", payload.ownerName),
            ("Breeder", payload.breederName),
            ("Sire", payload.sireLabel),
            ("Dam", payload.damLabel),
        ]

        for (label, value) in ownershipRows {
            ownershipY = drawLabelValue(label: label, value: value, x: rightX, y: ownershipY, width: columnWidth)
        }

        y = max(rowY, ownershipY) + 28
        y = drawHorizontalRule(y: y)
        y += 20

        let issuedDate = MemberDuesCalculator.formatDate(
            ISO8601DateFormatter().string(from: payload.issuedAt)
        )
        var footerLines = ["Issued \(issuedDate)"]
        if let email = payload.societyContactEmail, !email.isEmpty {
            footerLines.append(email)
        }
        if let address = payload.societyAddress, !address.isEmpty {
            footerLines.append(address)
        }
        footerLines.append(
            "This certificate is issued by \(payload.societyName) and reflects registry records at the time of issue."
        )

        for line in footerLines {
            y = drawCentered(line, y: y, font: .systemFont(ofSize: 9), color: .gray)
            y += 14
        }
    }

    @discardableResult
    private static func drawCentered(_ text: String, y: CGFloat, font: UIFont, color: UIColor) -> CGFloat {
        let attributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
        let size = (text as NSString).size(withAttributes: attributes)
        let x = (pageRect.width - size.width) / 2
        (text as NSString).draw(at: CGPoint(x: x, y: y), withAttributes: attributes)
        return y + size.height
    }

    @discardableResult
    private static func drawSectionTitle(_ text: String, x: CGFloat, y: CGFloat) -> CGFloat {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11, weight: .bold),
            .foregroundColor: UIColor.gray,
        ]
        (text as NSString).draw(at: CGPoint(x: x, y: y), withAttributes: attributes)
        return y + 16
    }

    @discardableResult
    private static func drawHeading(_ text: String, x: CGFloat, y: CGFloat) -> CGFloat {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 16, weight: .bold),
            .foregroundColor: UIColor.black,
        ]
        (text as NSString).draw(at: CGPoint(x: x, y: y), withAttributes: attributes)
        return y + 22
    }

    @discardableResult
    private static func drawLabelValue(label: String, value: String, x: CGFloat, y: CGFloat, width: CGFloat) -> CGFloat {
        let labelAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10),
            .foregroundColor: UIColor.gray,
        ]
        let valueAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10, weight: .semibold),
            .foregroundColor: UIColor.black,
        ]

        (label as NSString).draw(at: CGPoint(x: x, y: y), withAttributes: labelAttributes)

        let valueSize = (value as NSString).size(withAttributes: valueAttributes)
        let valueX = x + width - valueSize.width
        (value as NSString).draw(at: CGPoint(x: valueX, y: y + 14), withAttributes: valueAttributes)

        return y + 34
    }

    @discardableResult
    private static func drawHorizontalRule(y: CGFloat) -> CGFloat {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: margin, y: y))
        path.addLine(to: CGPoint(x: pageRect.width - margin, y: y))
        UIColor.systemGray4.setStroke()
        path.lineWidth = 1
        path.stroke()
        return y
    }
}
