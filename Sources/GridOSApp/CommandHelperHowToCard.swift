import SwiftUI

struct CommandHelperHowToCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("How it works")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                CommandHelperHowToRow(
                    symbolName: "keyboard",
                    title: "Open it from the terminal",
                    detail: "Press Command-K while a pane is focused."
                )

                CommandHelperHowToRow(
                    symbolName: "rectangle.3.group",
                    title: "Choose the job",
                    detail: "Suggest a command, explain output, or fix a failed command."
                )

                CommandHelperHowToRow(
                    symbolName: "checkmark.shield",
                    title: "Preview before sending",
                    detail: "Review redacted context first. Generated commands wait for your action."
                )
            }
        }
        .padding(12)
        .background(.secondary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .accessibilityElement(children: .contain)
    }
}

private struct CommandHelperHowToRow: View {
    let symbolName: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: symbolName)
                .font(.system(size: 13, weight: .semibold))
                .frame(width: 18, height: 18)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.footnote.weight(.semibold))
                Text(detail)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
