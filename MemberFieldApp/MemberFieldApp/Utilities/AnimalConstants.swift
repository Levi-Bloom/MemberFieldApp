import Foundation

enum AnimalConstants {
    static let types: [String] = [
        "AFB-American Fullblood (100%)",
        "Non Member Transfer",
        "## Not Eligible",
        "Foundation Ewe (0% - 49.99%)",
        "F1 First Cross (50% - 74.99%)",
        "F2 Second Cross (75% - 87.4999%)",
        "F3 Third Cross (87.5% - 93.74999%)",
        "Generics",
        "F4 Fourth Cross (93.75% - 96.86999%)",
        "F5-American Purebred (97% - 99.99%)",
        "Notified",
        "Other Breed",
        "Pending F4",
        "Pending F5",
        "Non Pedigree",
        "UK Pedigree",
    ]

    static let defaultType = "Foundation Ewe (0% - 49.99%)"

    static func typeOptions(including current: String?) -> [String] {
        guard let current, !current.isEmpty, !types.contains(current) else {
            return types
        }
        return [current] + types
    }
}
