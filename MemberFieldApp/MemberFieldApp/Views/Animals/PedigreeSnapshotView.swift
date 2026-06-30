import SwiftUI

struct AnimalPedigreeSectionView: View {
    let session: SessionContext
    let animal: Animal

    @State private var generationCount = AnimalPedigreeService.defaultGenerationCount
    @State private var snapshotResult: PedigreeSnapshotResult?
    @State private var isLoading = true
    @State private var errorMessage: String?

    private let pedigreeService = AnimalPedigreeService()

    private var treeHeight: CGFloat {
        let slotCount = pow(2.0, Double(snapshotResult?.generations.count ?? generationCount))
        return min(1200, max(512, slotCount * 18))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if isLoading {
                ProgressView("Loading pedigree…")
                    .frame(maxWidth: .infinity, minHeight: 120)
            } else if let errorMessage {
                Text(errorMessage)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else if let snapshotResult, !snapshotResult.hasPedigree || snapshotResult.generations.isEmpty {
                Text("No pedigree available. Add a sire or dam to build a family tree for this animal.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else if let snapshotResult {
                generationPicker

                ScrollView([.horizontal, .vertical], showsIndicators: true) {
                    PedigreeChartView(generations: snapshotResult.generations, treeHeight: treeHeight)
                }
                .frame(minHeight: min(treeHeight, 360))
            }
        }
        .task(id: generationCount) {
            await loadPedigree()
        }
    }

    private var generationPicker: some View {
        HStack(spacing: 8) {
            Text("Generations")
                .font(.caption)
                .foregroundStyle(.secondary)
            ForEach(AnimalPedigreeService.generationChoices, id: \.self) { option in
                Button {
                    generationCount = option
                } label: {
                    Text("\(option)")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            generationCount == option ? AppTheme.brandMuted : Color(.secondarySystemBackground),
                            in: Capsule()
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func loadPedigree() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            snapshotResult = try await pedigreeService.fetchPedigree(
                animalID: animal.id,
                societyID: session.society.id,
                generationCount: generationCount
            )
        } catch {
            snapshotResult = nil
            errorMessage = error.localizedDescription
        }
    }
}

struct PedigreeChartView: View {
    let generations: [[PedigreeAnimalRecord?]]
    let treeHeight: CGFloat

    private let columnWidth: CGFloat = 200

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            ForEach(Array(generations.enumerated()), id: \.offset) { index, generation in
                if index > 0 {
                    PedigreeConnectorGutter(parentCount: generations[index - 1].count, treeHeight: treeHeight)
                }

                VStack(spacing: 0) {
                    ForEach(Array(generation.enumerated()), id: \.offset) { slotIndex, record in
                        PedigreeCellView(record: record, isSireLine: slotIndex.isMultiple(of: 2))
                            .frame(height: treeHeight / CGFloat(max(generation.count, 1)))
                    }
                }
                .frame(width: columnWidth)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color(.separator), lineWidth: 1)
                }
            }
        }
        .frame(minHeight: treeHeight)
    }
}

private struct PedigreeCellView: View {
    let record: PedigreeAnimalRecord?
    let isSireLine: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let record {
                Text(record.name)
                    .font(.caption.weight(.semibold))
                if !record.tagNumber.isEmpty {
                    Text(record.tagNumber)
                        .font(.caption2)
                }
                if let scrapieTag = record.scrapieTag, !scrapieTag.isEmpty {
                    Text(scrapieTag)
                        .font(.caption2)
                }
                if let farmTag = record.farmTag, !farmTag.isEmpty {
                    Text(farmTag)
                        .font(.caption2)
                }
                if let description = record.description, !description.isEmpty {
                    Text(description)
                        .font(.caption2)
                        .lineLimit(2)
                }
            } else {
                Text("No data available")
                    .font(.caption2)
            }
        }
        .foregroundStyle(AppTheme.primaryText)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(isSireLine ? Color(.secondarySystemBackground) : Color(.systemBackground))
        .overlay(alignment: .bottom) {
            Divider()
        }
    }
}

private struct PedigreeConnectorGutter: View {
    let parentCount: Int
    let treeHeight: CGFloat

    private let gutterWidth: CGFloat = 24

    var body: some View {
        Canvas { context, size in
            let childCount = parentCount * 2
            var path = Path()

            for index in 0..<parentCount {
                let yParent = ((CGFloat(index) + 0.5) / CGFloat(parentCount)) * treeHeight
                let yChildSire = ((CGFloat(index * 2) + 0.5) / CGFloat(childCount)) * treeHeight
                let yChildDam = ((CGFloat(index * 2 + 1)) + 0.5) / CGFloat(childCount) * treeHeight
                let midX = gutterWidth / 2

                path.move(to: CGPoint(x: 0, y: yParent))
                path.addLine(to: CGPoint(x: midX, y: yParent))
                path.move(to: CGPoint(x: midX, y: yChildSire))
                path.addLine(to: CGPoint(x: midX, y: yChildDam))
                path.move(to: CGPoint(x: midX, y: yChildSire))
                path.addLine(to: CGPoint(x: gutterWidth, y: yChildSire))
                path.move(to: CGPoint(x: midX, y: yChildDam))
                path.addLine(to: CGPoint(x: gutterWidth, y: yChildDam))
            }

            context.stroke(path, with: .color(Color(.separator)), lineWidth: 1)
        }
        .frame(width: gutterWidth, height: treeHeight)
    }
}
