import SwiftUI

struct CommandHelperInfoPopover: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("What it does")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                Label("Suggests shell commands from plain English.", systemImage: "sparkles")
                Label("Explains selected or pasted terminal output.", systemImage: "text.magnifyingglass")
                Label("Repairs failed commands with a reviewable next step.", systemImage: "wrench.adjustable")
            }
            .font(.subheadline)

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Label("Nothing is sent until you approve the redacted preview.", systemImage: "checkmark.shield")
                Label("Provider keys stay in Keychain.", systemImage: "key")
                Label("It does not watch shell history in the background.", systemImage: "eye.slash")
                Label("Generated commands are checked locally before run.", systemImage: "lock.shield")
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
    }
}
