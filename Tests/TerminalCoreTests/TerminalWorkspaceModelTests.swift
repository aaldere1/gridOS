import XCTest
@testable import TerminalCore

final class TerminalWorkspaceModelTests: XCTestCase {
    func testDefaultWorkspaceStartsWithOnePane() {
        let state = TerminalWorkspaceState(defaultConfiguration: fixtureConfiguration())

        XCTAssertEqual(state.layout.paneIDsInVisualOrder, ["primary"])
        XCTAssertEqual(state.activePaneID, "primary")
        XCTAssertEqual(state.panesByID["primary"]?.configuration.workingDirectory, "/Users/test")
    }

    func testSplitRightCreatesSecondPane() {
        var state = TerminalWorkspaceState(defaultConfiguration: fixtureConfiguration())

        state.splitActivePane(axis: .horizontal, newPaneID: "pane-b")

        XCTAssertEqual(state.layout.paneIDsInVisualOrder, ["primary", "pane-b"])
        XCTAssertEqual(state.activePaneID, "pane-b")
        XCTAssertEqual(state.panesByID["pane-b"]?.configuration.workingDirectory, "/Users/test")
        XCTAssertEqual(state.panesByID["pane-b"]?.lastWorkingDirectory, "/Users/test")

        guard case .split(let axis, let fraction, _, _) = state.layout else {
            return XCTFail("Expected split layout")
        }
        XCTAssertEqual(axis, .horizontal)
        XCTAssertEqual(fraction, 0.50)
    }

    func testSplitDownCreatesVerticalSplit() {
        var state = TerminalWorkspaceState(defaultConfiguration: fixtureConfiguration())

        state.splitActivePane(axis: .vertical, newPaneID: "pane-b")

        guard case .split(let axis, _, _, _) = state.layout else {
            return XCTFail("Expected split layout")
        }
        XCTAssertEqual(axis, .vertical)
        XCTAssertEqual(state.layout.paneIDsInVisualOrder, ["primary", "pane-b"])
    }

    func testClosePanePromotesSiblingAndKeepsOnePane() {
        var state = TerminalWorkspaceState(defaultConfiguration: fixtureConfiguration())
        state.splitActivePane(axis: .horizontal, newPaneID: "pane-b")

        let closedPaneID = state.closeActivePane()

        XCTAssertEqual(closedPaneID, "pane-b")
        XCTAssertEqual(state.layout, .pane("primary"))
        XCTAssertNil(state.panesByID["pane-b"])
        XCTAssertEqual(state.activePaneID, "primary")
        XCTAssertNil(state.closeActivePane())
        XCTAssertEqual(state.layout, .pane("primary"))
    }

    func testDuplicatePaneCopiesConfigurationWithNewIdentity() {
        var state = TerminalWorkspaceState(defaultConfiguration: fixtureConfiguration())
        state.updateWorkingDirectory("/Users/test/project", for: "primary")

        state.duplicateActivePane(newPaneID: "duplicate")

        XCTAssertEqual(state.activePaneID, "duplicate")
        XCTAssertEqual(state.panesByID["duplicate"]?.id, "duplicate")
        XCTAssertEqual(state.panesByID["duplicate"]?.configuration.shellPath, "/bin/zsh")
        XCTAssertEqual(state.panesByID["duplicate"]?.configuration.workingDirectory, "/Users/test/project")
        XCTAssertEqual(state.panesByID["duplicate"]?.lastWorkingDirectory, "/Users/test/project")
    }

    func testFocusNextAndPreviousFollowVisualOrder() {
        var state = TerminalWorkspaceState(defaultConfiguration: fixtureConfiguration())
        state.splitActivePane(axis: .horizontal, newPaneID: "pane-b")
        state.splitActivePane(axis: .vertical, newPaneID: "pane-c")

        XCTAssertEqual(state.layout.paneIDsInVisualOrder, ["primary", "pane-b", "pane-c"])
        XCTAssertEqual(state.activePaneID, "pane-c")

        state.focusNextPane()
        XCTAssertEqual(state.activePaneID, "primary")

        state.focusPreviousPane()
        XCTAssertEqual(state.activePaneID, "pane-c")
    }

    func testMovePanePlacesSourceRelativeToTargetAndKeepsDescriptors() {
        var state = TerminalWorkspaceState(defaultConfiguration: fixtureConfiguration())
        state.splitActivePane(axis: .horizontal, newPaneID: "pane-b")
        state.splitActivePane(axis: .vertical, newPaneID: "pane-c")

        XCTAssertTrue(state.movePane("primary", relativeTo: "pane-c", placement: .after))

        XCTAssertEqual(state.layout.paneIDsInVisualOrder, ["pane-b", "pane-c", "primary"])
        XCTAssertEqual(state.activePaneID, "primary")
        XCTAssertEqual(state.panesByID["primary"]?.configuration.workingDirectory, "/Users/test")
        XCTAssertEqual(state.panesByID["pane-b"]?.configuration.workingDirectory, "/Users/test")
        XCTAssertEqual(state.panesByID["pane-c"]?.configuration.workingDirectory, "/Users/test")
    }

    func testMovePaneCanPlaceSourceAboveTarget() {
        var state = TerminalWorkspaceState(defaultConfiguration: fixtureConfiguration())
        state.splitActivePane(axis: .horizontal, newPaneID: "pane-b")

        XCTAssertTrue(state.movePane("pane-b", relativeTo: "primary", placement: .above))

        guard case .split(let axis, _, let first, let second) = state.layout else {
            return XCTFail("Expected split layout")
        }
        XCTAssertEqual(axis, .vertical)
        XCTAssertEqual(first.paneIDsInVisualOrder, ["pane-b"])
        XCTAssertEqual(second.paneIDsInVisualOrder, ["primary"])
        XCTAssertEqual(state.activePaneID, "pane-b")
    }

    func testMovePaneRejectsSameOrMissingPane() {
        var state = TerminalWorkspaceState(defaultConfiguration: fixtureConfiguration())
        state.splitActivePane(axis: .horizontal, newPaneID: "pane-b")
        let layoutBefore = state.layout

        XCTAssertFalse(state.movePane("pane-b", relativeTo: "pane-b", placement: .after))
        XCTAssertFalse(state.movePane("missing", relativeTo: "primary", placement: .after))

        XCTAssertEqual(state.layout, layoutBefore)
        XCTAssertEqual(state.activePaneID, "pane-b")
    }

    func testRepeatedSplitsSupportMoreThanThreePanes() {
        var state = TerminalWorkspaceState(defaultConfiguration: fixtureConfiguration())

        state.splitActivePane(axis: .horizontal, newPaneID: "pane-b")
        state.splitActivePane(axis: .vertical, newPaneID: "pane-c")
        state.splitActivePane(axis: .horizontal, newPaneID: "pane-d")
        state.splitActivePane(axis: .vertical, newPaneID: "pane-e")

        XCTAssertEqual(state.panesByID.count, 5)
        XCTAssertEqual(state.layout.paneIDsInVisualOrder, ["primary", "pane-b", "pane-c", "pane-d", "pane-e"])
        XCTAssertEqual(state.activePaneID, "pane-e")
    }

    func testSplitFractionsAreClamped() {
        XCTAssertEqual(TerminalPaneLayout.clampedFraction(0.10), 0.20)
        XCTAssertEqual(TerminalPaneLayout.clampedFraction(0.50), 0.50)
        XCTAssertEqual(TerminalPaneLayout.clampedFraction(0.90), 0.80)

        let layout = TerminalPaneLayout.split(
            axis: .horizontal,
            fraction: 0.95,
            first: .pane("a"),
            second: .pane("b")
        ).replacingPane("missing", with: .pane("c"))

        guard case .split(_, let fraction, _, _) = layout else {
            return XCTFail("Expected split layout")
        }
        XCTAssertEqual(fraction, 0.80)
    }

    func testSnapshotRoundTripsWithoutProcessIdentifiers() throws {
        var state = TerminalWorkspaceState(defaultConfiguration: fixtureConfiguration())
        state.splitActivePane(axis: .horizontal, newPaneID: "pane-b")

        let data = try JSONEncoder().encode(state.snapshot())
        let json = String(decoding: data, as: UTF8.self)
        XCTAssertFalse(json.contains("shellPid"))
        XCTAssertFalse(json.contains("processID"))
        XCTAssertFalse(json.contains("childfd"))
        XCTAssertFalse(json.contains("pid"))

        let decoded = try JSONDecoder().decode(TerminalWorkspaceSnapshot.self, from: data)
        let restored = TerminalWorkspaceState(
            snapshot: decoded,
            fallbackConfiguration: fixtureConfiguration(workingDirectory: "/Users/fallback"),
            directoryExists: { _ in true }
        )

        XCTAssertEqual(restored.layout, state.layout)
        XCTAssertEqual(restored.activePaneID, state.activePaneID)
        XCTAssertEqual(restored.panesByID["pane-b"]?.isRestored, true)
    }

    func testMissingRestoredDirectoryFallsBackToDefault() {
        let snapshot = TerminalWorkspaceSnapshot(
            layout: .pane("primary"),
            panes: [
                TerminalPaneDescriptor(
                    id: "primary",
                    configuration: fixtureConfiguration(workingDirectory: "/missing"),
                    lastWorkingDirectory: "/missing"
                )
            ],
            activePaneID: "primary"
        )

        let restored = TerminalWorkspaceState(
            snapshot: snapshot,
            fallbackConfiguration: fixtureConfiguration(workingDirectory: "/Users/fallback"),
            directoryExists: { _ in false }
        )

        XCTAssertEqual(restored.panesByID["primary"]?.configuration.workingDirectory, "/Users/fallback")
        XCTAssertNil(restored.panesByID["primary"]?.lastWorkingDirectory)
        XCTAssertEqual(restored.panesByID["primary"]?.isRestored, true)
    }

    func testRecentDirectoriesNormalizeDedupeAndCapAtTen() {
        var state = TerminalWorkspaceState(defaultConfiguration: fixtureConfiguration())

        for index in 0..<12 {
            state.recordRecentDirectory(" /tmp/project-\(index) ")
        }
        state.recordRecentDirectory("/tmp/project-5")
        state.recordRecentDirectory("  ")

        XCTAssertEqual(state.recentDirectories.count, 10)
        XCTAssertEqual(state.recentDirectories.first, "/tmp/project-5")
        XCTAssertEqual(Set(state.recentDirectories).count, 10)
        XCTAssertFalse(state.recentDirectories.contains("/tmp/project-0"))
        XCTAssertFalse(state.recentDirectories.contains("/tmp/project-1"))
    }

    func testTerminalFontSizeUpdatesEveryPaneConfigurationWithoutChangingLayout() {
        var state = TerminalWorkspaceState(defaultConfiguration: fixtureConfiguration())
        state.splitActivePane(axis: .horizontal, newPaneID: "secondary")
        let layoutBefore = state.layout

        state.updateTerminalFontSize(18)

        XCTAssertEqual(state.layout, layoutBefore)
        XCTAssertEqual(state.panesByID["primary"]?.configuration.fontSize, 18)
        XCTAssertEqual(state.panesByID["secondary"]?.configuration.fontSize, 18)
    }

    private func fixtureConfiguration(workingDirectory: String? = "/Users/test") -> TerminalSessionConfiguration {
        TerminalSessionConfiguration(
            shellPath: "/bin/zsh",
            shellArguments: ["-l"],
            workingDirectory: workingDirectory,
            fontName: "Menlo",
            fontSize: 14,
            startupCommand: "echo ready"
        )
    }
}
