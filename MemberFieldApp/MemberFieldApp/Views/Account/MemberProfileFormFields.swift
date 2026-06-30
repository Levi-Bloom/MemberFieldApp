import SwiftUI

struct MemberProfileFormFields: View {
    @Binding var form: MemberProfileInput
    var requirePrefix: Bool

    var body: some View {
        Section("Name") {
            TextField("First name", text: $form.firstName)
            TextField("Last name", text: $form.lastName)
            TextField(requirePrefix ? "Prefix (required)" : "Prefix", text: Binding(
                get: { form.prefix ?? "" },
                set: { form.prefix = $0 }
            ))
        }

        Section("Contact") {
            TextField("Phone", text: $form.phone)
                .keyboardType(.phonePad)
            TextField("Website", text: Binding(
                get: { form.website ?? "" },
                set: { form.website = $0 }
            ))
                .keyboardType(.URL)
                .autocapitalization(.none)
        }

        Section("Address") {
            TextField("Address", text: $form.address, axis: .vertical)
            TextField("Postcode", text: Binding(
                get: { form.postcode ?? "" },
                set: { form.postcode = $0 }
            ))
            TextField("Country", text: $form.country)
            TextField("City", text: Binding(
                get: { form.city ?? "" },
                set: { form.city = $0 }
            ))
            TextField("State", text: Binding(
                get: { form.state ?? "" },
                set: { form.state = $0 }
            ))
            TextField("Region", text: Binding(
                get: { form.region ?? "" },
                set: { form.region = $0 }
            ))
            TextField("Sub-region", text: Binding(
                get: { form.subRegion ?? "" },
                set: { form.subRegion = $0 }
            ))
        }

        Section("Farm & herd") {
            TextField("Farm name", text: Binding(
                get: { form.farmName ?? "" },
                set: { form.farmName = $0 }
            ))
            TextField("Ministry tag", text: Binding(
                get: { form.ministryTag ?? "" },
                set: { form.ministryTag = $0 }
            ))
        }
    }
}
