import EMathicaThemeKit
import EMathicaDocumentKit
import SwiftUI

struct RecentProjectsGridView: View {
    let projects: [RecentProject]
    let moduleTitleForProjectModuleID: (String) -> String
    let isSelectionMode: Bool
    let selectedProjectIDs: Set<UUID>
    let previewURLForProjectID: (UUID) -> URL?
    let preferredColumnCount: Int?
    let cardSpacing: CGFloat
    let adaptiveMinWidth: CGFloat?
    let adaptiveMaxWidth: CGFloat?
    let cardHeight: CGFloat?
    let thumbnailHeight: CGFloat?
    let onProjectTap: (RecentProject) -> Void
    let onProjectRenameTap: (RecentProject) -> Void

    init(
        projects: [RecentProject],
        moduleTitleForProjectModuleID: @escaping (String) -> String,
        isSelectionMode: Bool,
        selectedProjectIDs: Set<UUID>,
        previewURLForProjectID: @escaping (UUID) -> URL?,
        preferredColumnCount: Int?,
        cardSpacing: CGFloat,
        adaptiveMinWidth: CGFloat?,
        adaptiveMaxWidth: CGFloat?,
        cardHeight: CGFloat?,
        thumbnailHeight: CGFloat?,
        onProjectTap: @escaping (RecentProject) -> Void,
        onProjectRenameTap: @escaping (RecentProject) -> Void
    ) {
        self.projects = projects
        self.moduleTitleForProjectModuleID = moduleTitleForProjectModuleID
        self.isSelectionMode = isSelectionMode
        self.selectedProjectIDs = selectedProjectIDs
        self.previewURLForProjectID = previewURLForProjectID
        self.preferredColumnCount = preferredColumnCount
        self.cardSpacing = cardSpacing
        self.adaptiveMinWidth = adaptiveMinWidth
        self.adaptiveMaxWidth = adaptiveMaxWidth
        self.cardHeight = cardHeight
        self.thumbnailHeight = thumbnailHeight
        self.onProjectTap = onProjectTap
        self.onProjectRenameTap = onProjectRenameTap
    }

    var body: some View {
        let items = projects

        LazyVGrid(columns: resolvedColumns, alignment: .leading, spacing: cardSpacing) {
            ForEach(items) { p in
                let moduleTitle = moduleTitleForProjectModuleID(p.moduleID)
                let accent = accentToken(for: p.moduleID).resolvedColor()
                let isSelected = selectedProjectIDs.contains(p.id)

                ProjectCardView(
                    project: p,
                    moduleTitle: moduleTitle,
                    accent: accent,
                    previewURL: previewURLForProjectID(p.id),
                    isSelectionMode: isSelectionMode,
                    isSelected: isSelected,
                    cardHeight: cardHeight,
                    thumbnailHeight: thumbnailHeight
                ) {
                    onProjectTap(p)
                } onRename: {
                    onProjectRenameTap(p)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    private var resolvedColumns: [GridItem] {
        if let preferredColumnCount, preferredColumnCount > 0 {
            return Array(
                repeating: GridItem(
                    .flexible(
                        minimum: adaptiveMinWidth ?? 150,
                        maximum: adaptiveMaxWidth ?? 260
                    ),
                    spacing: cardSpacing,
                    alignment: .leading
                ),
                count: preferredColumnCount
            )
        }
        return [
            GridItem(
                .adaptive(
                    minimum: adaptiveMinWidth ?? 170,
                    maximum: adaptiveMaxWidth ?? 280
                ),
                spacing: cardSpacing,
                alignment: .leading
            )
        ]
    }

    private func accentToken(for moduleID: String) -> ColorToken {
        switch moduleID {
        case "plane":
            return .blue
        case "space":
            return .indigo
        case "modeling":
            return .purple
        case "music":
            return .cyan
        case "data":
            return .green
        case "notes":
            return .pink
        default:
            return .blue
        }
    }
}
