import AppKit

/// Triggers macOS Spaces and Mission Control features by posting their default shortcuts.
enum SystemActions {
    private enum KeyCode {
        static let left: CGKeyCode = 123
        static let right: CGKeyCode = 124
        static let down: CGKeyCode = 125
        static let f11: CGKeyCode = 103
    }

    /// Posts Ctrl+Left / Ctrl+Right ("Move left/right a space").
    static func switchSpace(right: Bool) {
        postShortcut(right ? KeyCode.right : KeyCode.left)
    }

    static func openMissionControl() {
        NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/Mission Control.app"))
    }

    /// Posts Ctrl+Down ("Application windows").
    static func showAppWindows() {
        postShortcut(KeyCode.down)
    }

    /// Posts F11 ("Show Desktop").
    static func showDesktop() {
        postShortcut(KeyCode.f11, flags: .maskSecondaryFn)
    }

    /// Re-creates a plain middle click at `location`, tagged so the event tap lets it through.
    static func postMiddleClick(at location: CGPoint) {
        let src = CGEventSource(stateID: .hidSystemState)
        for type in [CGEventType.otherMouseDown, .otherMouseUp] {
            guard let event = CGEvent(mouseEventSource: src, mouseType: type,
                                      mouseCursorPosition: location, mouseButton: .center) else { continue }
            event.setIntegerValueField(.eventSourceUserData, value: GestureEngine.syntheticEventMarker)
            event.post(tap: .cghidEventTap)
        }
    }

    /// Arrow-key hotkeys are registered with Ctrl + Fn, and function keys with Fn, so Fn is required to match.
    private static func postShortcut(_ key: CGKeyCode, flags: CGEventFlags = [.maskControl, .maskSecondaryFn]) {
        let initialFlags = CGEventSource.flagsState(.combinedSessionState)
        guard let source = CGEventSource(stateID: .privateState) else { return }
        let sequence = ShortcutSequence.events(for: key, flags: flags, initialFlags: initialFlags)

        // Allocate the whole sequence first: an allocation failure must not leave only the
        // modifier-down half of the shortcut posted to the system.
        var events: [CGEvent] = []
        for step in sequence {
            guard let event = CGEvent(keyboardEventSource: source, virtualKey: step.keyCode,
                                      keyDown: step.keyDown) else { return }
            event.type = step.type
            event.flags = step.flags
            events.append(event)
        }
        for event in events { event.post(tap: .cghidEventTap) }
    }
}
