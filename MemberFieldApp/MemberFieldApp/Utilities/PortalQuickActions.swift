import Foundation

enum PortalQuickActions {
    static let all: [PortalQuickAction] = [
        PortalQuickAction(id: "my-animals", label: "My Animals", systemImage: "pawprint.fill", destination: .myAnimals),
        PortalQuickAction(id: "births", label: "Births / New Registrations", systemImage: "plus.circle.fill", destination: .newRegistration),
        PortalQuickAction(id: "transfer", label: "Transfer", systemImage: "arrow.left.arrow.right", destination: .transfer),
        PortalQuickAction(id: "castrates", label: "Castrates", systemImage: "scissors", destination: .castrate),
        PortalQuickAction(id: "deaths", label: "Deaths", systemImage: "xmark.circle", destination: .death),
        PortalQuickAction(id: "sale-hire-ai", label: "Flag For Sale / Hire", systemImage: "tag.fill", destination: .saleHireAI),
        PortalQuickAction(id: "check-mate", label: "Check Mate", systemImage: "dna", destination: .checkMate),
    ]
}
