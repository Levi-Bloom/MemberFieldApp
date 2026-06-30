import SwiftUI

struct ContactSocietyView: View {
    let session: SessionContext
    private var society: Society { session.society }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Reach out to \(society.name) for membership questions, registry support, and society updates.")
                    .font(.subheadline)

                VStack(alignment: .leading, spacing: 0) {
                    Text(society.name).font(.title3.bold())
                    if let strapline = society.strapline {
                        Text(strapline).font(.footnote)
                    }

                    if hasContactInfo {
                        if let email = society.contactEmail {
                            contactRow(icon: "envelope.fill", label: "Email") {
                                Link(email, destination: URL(string: "mailto:\(email)")!)
                            }
                        }
                        if let phone = MemberDuesCalculator.formatPhone(society.contactPhone) {
                            contactRow(icon: "phone.fill", label: "Phone") {
                                if let raw = society.contactPhone, let url = URL(string: "tel:\(raw)") {
                                    Link(phone, destination: url)
                                } else {
                                    Text(phone)
                                }
                            }
                        }
                        if let address = formattedAddress {
                            contactRow(icon: "mappin.and.ellipse", label: "Address") {
                                Text(address)
                            }
                        }
                        if let website = society.website, let url = URL(string: website.hasPrefix("http") ? website : "https://\(website)") {
                            contactRow(icon: "globe", label: "Website") {
                                Link(website.replacingOccurrences(of: "https://", with: "").replacingOccurrences(of: "http://", with: ""), destination: url)
                            }
                        }
                    } else {
                        Text("Contact details have not been published yet. Check back soon or reach out through your society administrator.")
                            .font(.footnote)
                            .padding(.top, 12)
                    }
                }
                .padding()
                .background(.background, in: RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(.quaternary))
            }
            .padding()
        }
        .navigationTitle("Contact Society")
    }

    private var hasContactInfo: Bool {
        society.contactEmail != nil || society.contactPhone != nil || formattedAddress != nil || society.website != nil
    }

    private var formattedAddress: String? {
        let parts = [society.address, society.postcode].compactMap { $0?.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        return parts.isEmpty ? nil : parts.joined(separator: ", ")
    }

    private func contactRow<Content: View>(icon: String, label: String, @ViewBuilder content: () -> Content) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.green)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 4) {
                Text(label).font(.caption)
                content()
                    .font(.subheadline)
            }
            Spacer()
        }
        .padding(.vertical, 10)
    }
}
