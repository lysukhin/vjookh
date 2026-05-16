import Core
import Foundation

/// Wires the pure Core (`KeystrokeBuffer` → `Detector` → `EditPlanner`) to the
/// system adapters. Owns the small mutable state for undo / force-convert.
final class CorrectionPipeline {
    private var buffer = KeystrokeBuffer()
    private let map: LayoutMap
    private let detector: Detector
    private let synth: InputSynthesizer
    private let inputSource: InputSourceController
    private let frontmostBundleID: () -> String?
    private var shiftTap = ShiftDoubleTapDetector()

    /// The most recent completed word (for force-convert).
    private var lastCompleted: (word: String, separator: String, layout: Detector.Layout)?
    /// The most recent applied auto-correction (for one-shot undo).
    private var lastCorrection:
        (edit: EditPlanner.Edit, word: String, separator: String, layout: Detector.Layout)?

    init(
        map: LayoutMap, detector: Detector, synth: InputSynthesizer,
        inputSource: InputSourceController, frontmostBundleID: @escaping () -> String?
    ) {
        self.map = map
        self.detector = detector
        self.synth = synth
        self.inputSource = inputSource
        self.frontmostBundleID = frontmostBundleID
    }

    func ingest(_ k: EventTapController.Keystroke) {
        guard Settings.shared.isEnabled,
              !Settings.shared.isExcluded(frontmostBundleID()) else { return }

        // Any real key cancels an in-progress double-Shift gesture.
        _ = shiftTap.feed(.otherKey, at: CFAbsoluteTimeGetCurrent())

        let event = EventClassifier.classify(
            typed: k.typed, isDelete: k.isDelete, keyCode: Int(k.keyCode)
        )
        let separator: String
        if event == .boundary {
            // Tab/Return often deliver no Unicode string — reconstruct it so
            // the retyped text keeps the user's actual separator.
            if !k.typed.isEmpty { separator = k.typed }
            else if k.keyCode == 48 { separator = "\t" }
            else if k.keyCode == 36 || k.keyCode == 76 { separator = "\n" }
            else { separator = " " }
        } else {
            separator = " "
        }
        guard let word = buffer.handle(event), !word.isEmpty else { return }

        let layout = inputSource.currentLayout()
            ?? ((word.first?.isASCII ?? true) ? .latin : .cyrillic)
        lastCompleted = (word, separator, layout)

        if detector.evaluate(token: word, activeLayout: layout).shouldConvert {
            applyCorrection(word: word, separator: separator, from: layout)
        }
    }

    /// Fed by the event tap on every Shift transition. A recognized double-tap
    /// flips the last word's decision.
    func handleShift(_ isDown: Bool) {
        guard Settings.shared.isEnabled,
              !Settings.shared.isExcluded(frontmostBundleID()) else { return }
        let e: ShiftDoubleTapDetector.Event = isDown ? .modifierDown : .modifierUp
        if shiftTap.feed(e, at: CFAbsoluteTimeGetCurrent()) {
            toggleLastDecision()
        }
    }

    /// The single manual override: if the last word was auto-corrected, revert
    /// it; otherwise convert it now. Repeated gestures flip it back and forth.
    func toggleLastDecision() {
        if lastCorrection != nil {
            undoLast()
        } else {
            forceConvertLast()
        }
    }

    /// Force-convert the last completed word even though the detector left it
    /// alone (the user's manual override for missed cases).
    private func forceConvertLast() {
        guard let lc = lastCompleted else { return }
        applyCorrection(word: lc.word, separator: lc.separator, from: lc.layout)
    }

    /// Exactly reverse the most recent auto-correction (false-positive escape).
    private func undoLast() {
        guard let lc = lastCorrection else { return }
        let undo = EditPlanner.undo(of: lc.edit, originalWord: lc.word, separator: lc.separator)
        synth.apply(undo)
        inputSource.switchTo(lc.layout)  // restore the original layout
        lastCorrection = nil
    }


    private func applyCorrection(
        word: String, separator: String, from layout: Detector.Layout
    ) {
        let target: Detector.Layout = (layout == .latin) ? .cyrillic : .latin
        let corrected = (layout == .latin) ? map.toCyrillic(word) : map.toLatin(word)
        let edit = EditPlanner.correction(
            word: word, separator: separator, corrected: corrected
        )
        synth.apply(edit)
        inputSource.switchTo(target)
        lastCorrection = (edit, word, separator, layout)
    }
}
