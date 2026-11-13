import CoreGraphics

/// Describes the events to send for a shortcut, before any system input is posted.
enum ShortcutSequence {
    struct Event {
        let keyCode: CGKeyCode
        let keyDown: Bool
        let type: CGEventType
        let flags: CGEventFlags
    }

    static func events(for key: CGKeyCode, flags: CGEventFlags, initialFlags: CGEventFlags) -> [Event] {
        let modifiers: [(flag: CGEventFlags, key: CGKeyCode)] = [
            (.maskControl, 59),
            (.maskSecondaryFn, 63),
        ]
        let addedModifiers = modifiers.filter {
            flags.contains($0.flag) && !initialFlags.contains($0.flag)
        }
        var state = initialFlags
        var result: [Event] = []

        for modifier in addedModifiers {
            state.insert(modifier.flag)
            result.append(Event(keyCode: modifier.key, keyDown: true, type: .flagsChanged, flags: state))
        }
        for keyDown in [true, false] {
            result.append(Event(keyCode: key, keyDown: keyDown, type: keyDown ? .keyDown : .keyUp,
                                flags: initialFlags.union(flags)))
        }
        // Return to the exact state from before the shortcut. Clearing every modifier would
        // incorrectly release keys the user is actually holding, including via remote input.
        for modifier in addedModifiers.reversed() {
            state.remove(modifier.flag)
            result.append(Event(keyCode: modifier.key, keyDown: false, type: .flagsChanged, flags: state))
        }
        return result
    }
}
