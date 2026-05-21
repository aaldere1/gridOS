import Integrations
import SwiftUI

struct MenuBarExtraView: View {
    @ObservedObject var controller: MacIntegrationsController

    var body: some View {
        Button("Open gridOS") {
            controller.openGridOS()
        }

        Divider()

        Text("Active workspace")

        if !controller.status.shellDisplayName.isEmpty {
            Text(controller.status.shellDisplayName)
        }

        Menu("Host Status") {
            Text(controller.status.cpuText)
            Text(controller.status.memoryText)
            Text(controller.status.networkText)
            Text(controller.status.batteryText)
            Text(controller.status.thermalText)

            if controller.status.isStale {
                Text("Stale")
            }
        }

        Menu("Recent Directories") {
            if controller.recentDirectories.isEmpty {
                Text("No recent directories yet.")
            } else {
                ForEach(controller.recentDirectories) { directory in
                    Button(directory.displayName) {
                        controller.openRecentDirectory(directory)
                    }
                }
            }
        }

        Divider()

        Button("Settings") {
            controller.openSettings()
        }

        Button("Quit gridOS") {
            controller.quitGridOS()
        }
        .onAppear {
            controller.refresh()
        }
    }
}
