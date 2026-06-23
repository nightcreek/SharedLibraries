import EMathicaMathCore
import SwiftUI

public struct DeletedObjectHistorySheet: View {
    @Environment(\.dismiss) private var dismiss

    @Bindable var state: WorkspaceState

    public var body: some View {
        NavigationStack {
            Group {
                if rowModels.isEmpty {
                    emptyState
                } else {
                    List(rowModels) { row in
                        rowView(row)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("已删除对象")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var rowModels: [DeletedObjectHistoryPresenter.RowModel] {
        DeletedObjectHistoryPresenter.rowModels(from: state.document.deletedObjectHistory ?? [])
    }

    private var emptyState: some View {
        VStack(alignment: .center, spacing: 10) {
            Text(DeletedObjectHistoryPresenter.emptyTitle)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.primary)
            Text(DeletedObjectHistoryPresenter.emptyMessage)
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Text(DeletedObjectHistoryPresenter.restoreDescription)
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .padding(.horizontal, 24)
    }

    private func rowView(_ row: DeletedObjectHistoryPresenter.RowModel) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(row.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Spacer(minLength: 0)
                Text(row.typeLabel)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 10) {
                Text(row.deletedAtText)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(.secondary)
                Text("·")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(.secondary)
                Text(row.contextText)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(.secondary)
            }

            Text(row.summaryText)
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.tail)

            HStack {
                Spacer(minLength: 0)
                Button("恢复") {
                    state.dispatch(.restoreDeletedObject(recordID: row.recordID))
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
        }
        .padding(.vertical, 6)
    }
}

