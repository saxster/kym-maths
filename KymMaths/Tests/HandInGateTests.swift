import Testing
@testable import KymMaths

/// One tap on Hand in marks what Kym typed. Keys can still be queued for the box when the tap lands,
/// so a tap while typing waits for editing to end and is marked then, once.
@Suite("Hand in")
struct HandInGateTests {
    @Test("A tap with no box being typed in marks at once")
    func marksAtOnceWhenNotTyping() {
        var gate = HandInGate()
        let marksNow = gate.tap(isEditing: false)
        let marksAgain = gate.editingEnded()
        #expect(marksNow)
        #expect(!marksAgain)
    }

    @Test("A tap while typing waits for editing to end, then marks once")
    func waitsForTypingToEnd() {
        var gate = HandInGate()
        let marksNow = gate.tap(isEditing: true)
        #expect(!marksNow)
        #expect(gate.isWaiting)
        let marksWhenEnded = gate.editingEnded()
        let marksAgain = gate.editingEnded()
        #expect(marksWhenEnded)
        #expect(!marksAgain)
    }

    @Test("Leaving a box without tapping Hand in marks nothing")
    func leavingABoxMarksNothing() {
        var gate = HandInGate()
        let marks = gate.editingEnded()
        #expect(!marks)
    }

    @Test("A later tap with no box in focus still marks, so the button never sticks")
    func laterTapNeverSticks() {
        var gate = HandInGate()
        _ = gate.tap(isEditing: true)
        let secondTapMarks = gate.tap(isEditing: false)
        let marksAgain = gate.editingEnded()
        #expect(secondTapMarks)
        #expect(!marksAgain)
    }
}
