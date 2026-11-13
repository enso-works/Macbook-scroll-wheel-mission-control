import CoreGraphics
import Darwin

@main
enum ShortcutSequenceTests {
    static func main() {
        let control = CGEventFlags.maskControl
        let fn = CGEventFlags.maskSecondaryFn
        let required: CGEventFlags = [control, fn]
        var failures = 0
        var checks = 0

        func expect(_ condition: Bool, _ message: String) {
            checks += 1
            if !condition {
                failures += 1
                print("FAIL: \(message)")
            }
        }

        // A completed synthetic shortcut must not turn the next ordinary left click into
        // Control-click. This asserts the outgoing event contract, without injecting input.
        for key: CGKeyCode in [123, 124, 125] {
            let events = ShortcutSequence.events(for: key, flags: required, initialFlags: [])
            expect(events.last?.flags.contains(control) == false,
                   "key \(key): subsequent left click must not inherit Control")
            expect(events.last?.flags.contains(fn) == false,
                   "key \(key): synthetic Fn must be released")
            let arrows = events.filter { $0.keyCode == key }
            expect(arrows.count == 2 && arrows[0].keyDown && !arrows[1].keyDown,
                   "key \(key): one balanced target-key press")
            expect(arrows.allSatisfy { $0.flags == required },
                   "key \(key): required flags remain held until the target key is released")
        }

        let normal = ShortcutSequence.events(for: 124, flags: required, initialFlags: [])
        expect(normal.map(\.keyCode) == [59, 63, 124, 124, 63, 59],
               "press Control/Fn, send arrow, release added modifiers in reverse order")
        expect(normal.map(\.keyDown) == [true, true, true, false, false, false],
               "added modifiers have paired press and release events")
        expect(normal.map { $0.type.rawValue } == [12, 12, 10, 11, 12, 12],
               "modifier transitions use flagsChanged; the arrow uses keyDown/keyUp")
        expect(normal.map { $0.flags.rawValue } == [262144, 8650752, 8650752, 8650752, 262144, 0],
               "each outgoing transition carries the modifier state after that transition")

        let heldControl = ShortcutSequence.events(for: 124, flags: required, initialFlags: control)
        expect(heldControl.filter { $0.keyCode == 59 }.isEmpty,
               "do not synthesize a release for an already-held Control key")
        expect(heldControl.last?.flags == control,
               "preserve the user's held Control after the shortcut")

        let heldFn = ShortcutSequence.events(for: 124, flags: required, initialFlags: fn)
        expect(heldFn.filter { $0.keyCode == 63 }.isEmpty,
               "do not synthesize a release for an already-held Fn key")
        expect(heldFn.last?.flags == fn,
               "preserve the user's held Fn after the shortcut")

        let alreadyHeld = ShortcutSequence.events(for: 124, flags: required, initialFlags: required)
        expect(alreadyHeld.map(\.keyCode) == [124, 124],
               "only press the target key when both required modifiers are already held")
        expect(alreadyHeld.last?.flags == required,
               "do not clear modifiers that were held before the gesture")

        let otherHeld: CGEventFlags = [.maskShift, .maskAlternate, .maskCommand, .maskAlphaShift]
        let withOtherHeld = ShortcutSequence.events(for: 123, flags: required, initialFlags: otherHeld)
        expect(withOtherHeld.last?.flags == otherHeld,
               "restore other held modifiers and Caps Lock exactly")
        expect(withOtherHeld.filter { $0.keyCode == 123 }.allSatisfy { $0.flags == otherHeld.union(required) },
               "do not drop other held modifiers during the shortcut")

        let showDesktop = ShortcutSequence.events(for: 103, flags: fn, initialFlags: [])
        expect(showDesktop.map(\.keyCode) == [63, 103, 103, 63],
               "Fn-only shortcuts never introduce Control")
        expect(showDesktop.last?.flags == [], "release synthetic Fn after Show Desktop")

        print("\(checks - failures)/\(checks) checks passed")
        exit(failures == 0 ? 0 : 1)
    }
}
