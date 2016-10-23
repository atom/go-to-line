GoToLineView = require '../lib/go-to-line-view'

describe 'GoToLine', ->
  [goToLine, editor, editorView] = []

  beforeEach ->
    waitsForPromise ->
      atom.workspace.open('sample.js')

    runs ->
      workspaceElement = atom.views.getView(atom.workspace)
      workspaceElement.style.height = "200px"
      workspaceElement.style.widht = "1000px"
      jasmine.attachToDOM(workspaceElement)

      editor = atom.workspace.getActiveTextEditor()
      editorView = atom.views.getView(editor)
      goToLine = GoToLineView.activate()
      editor.setCursorBufferPosition([1, 0])

  describe "when go-to-line:toggle is triggered", ->
    it "adds a modal panel", ->
      expect(goToLine.panel.isVisible()).toBeFalsy()
      atom.commands.dispatch editorView, 'go-to-line:toggle'
      expect(goToLine.panel.isVisible()).toBeTruthy()

  describe "when entering a line number", ->
    it "only allows 0-9 and the colon character to be entered in the mini editor", ->
      expect(goToLine.miniEditor.getText()).toBe ''
      goToLine.miniEditor.getModel().insertText 'a'
      expect(goToLine.miniEditor.getText()).toBe ''
      goToLine.miniEditor.getModel().insertText ':'
      expect(goToLine.miniEditor.getText()).toBe ':'
      goToLine.miniEditor.getModel().setText ''
      goToLine.miniEditor.getModel().insertText '4'
      expect(goToLine.miniEditor.getText()).toBe '4'

  describe "when entering a line number and column number", ->
    it "moves the cursor to the column number of the line specified", ->
      expect(goToLine.miniEditor.getText()).toBe ''
      goToLine.miniEditor.getModel().insertText '3:14'
      advanceClock(editor.buffer.stoppedChangingDelay)
      atom.commands.dispatch(goToLine.miniEditor.element, 'core:confirm')
      expect(editor.getCursorBufferPosition()).toEqual [2, 13]

    it "centers the selected line", ->
      goToLine.miniEditor.getModel().insertText '45:4'
      advanceClock(editor.buffer.stoppedChangingDelay)
      atom.commands.dispatch(goToLine.miniEditor.element, 'core:confirm')
      rowsPerPage = editor.getRowsPerPage()
      currentRow = (editor.getCursorBufferPosition().row) - 1
      expect(editor.getVisibleRowRange()).toEqual [
        currentRow - Math.floor(rowsPerPage / 2) - 1, # do not include the current row
        currentRow + Math.floor(rowsPerPage / 2)
      ]

  describe "when entering a line number greater than the number of rows in the buffer", ->
    it "moves the cursor position to the first character of the last line", ->
      atom.commands.dispatch editorView, 'go-to-line:toggle'
      expect(goToLine.panel.isVisible()).toBeTruthy()
      expect(goToLine.miniEditor.getText()).toBe ''
      goToLine.miniEditor.getModel().insertText '71'
      advanceClock(editor.buffer.stoppedChangingDelay)
      atom.commands.dispatch(goToLine.miniEditor.element, 'core:confirm')
      expect(goToLine.panel.isVisible()).toBeFalsy()
      expect(editor.getCursorBufferPosition()).toEqual [70, 0]

  describe "when entering a column number greater than the number in the specified line", ->
    it "moves the cursor position to the last character of the specified line", ->
      atom.commands.dispatch editorView, 'go-to-line:toggle'
      expect(goToLine.panel.isVisible()).toBeTruthy()
      expect(goToLine.miniEditor.getText()).toBe ''
      goToLine.miniEditor.getModel().insertText '3:43'
      advanceClock(editor.buffer.stoppedChangingDelay)
      atom.commands.dispatch(goToLine.miniEditor.element, 'core:confirm')
      expect(goToLine.panel.isVisible()).toBeFalsy()
      expect(editor.getCursorBufferPosition()).toEqual [2, 40]

  describe "when core:confirm is triggered", ->
    describe "when a line number has been entered", ->
      it "moves the cursor to the first character of the line", ->
        goToLine.miniEditor.getModel().insertText '3'
        advanceClock(editor.buffer.stoppedChangingDelay)
        atom.commands.dispatch(goToLine.miniEditor.element, 'core:confirm')
        expect(editor.getCursorBufferPosition()).toEqual [2, 4]

    describe "when the line number entered is nested within foldes", ->
      it "unfolds all folds containing the given row", ->
        expect(editor.indentationForBufferRow(6)).toEqual 3
        editor.foldAll()
        expect(editor.screenRowForBufferRow(6)).toEqual 0

        # buffer rows are 0-indexed whereas the gutter row numbers are 1-indexed
        # so buffer row 6 corresponds to gutter row 7
        goToLine.miniEditor.getModel().insertText '7'
        advanceClock(editor.buffer.stoppedChangingDelay)
        atom.commands.dispatch(goToLine.miniEditor.element, 'core:confirm')
        expect(editor.getCursorBufferPosition()).toEqual [6, 6]

  describe "when no line number has been entered", ->
    it "closes the view and does not update the cursor position", ->
      atom.commands.dispatch editorView, 'go-to-line:toggle'
      expect(goToLine.panel.isVisible()).toBeTruthy()
      atom.commands.dispatch(goToLine.miniEditor.element, 'core:confirm')
      expect(goToLine.panel.isVisible()).toBeFalsy()
      expect(editor.getCursorBufferPosition()).toEqual [1, 0]

  describe "when no line number has been entered, but a column number has been entered", ->
    it "navigates to the column of the current line", ->
      atom.commands.dispatch editorView, 'go-to-line:toggle'
      expect(goToLine.panel.isVisible()).toBeTruthy()
      goToLine.miniEditor.getModel().insertText '4:1'
      advanceClock(editor.buffer.stoppedChangingDelay)
      atom.commands.dispatch(goToLine.miniEditor.element, 'core:confirm')
      expect(goToLine.panel.isVisible()).toBeFalsy()
      expect(editor.getCursorBufferPosition()).toEqual [3, 0]
      atom.commands.dispatch editorView, 'go-to-line:toggle'
      expect(goToLine.panel.isVisible()).toBeTruthy()
      goToLine.miniEditor.getModel().insertText ':19'
      advanceClock(editor.buffer.stoppedChangingDelay)
      atom.commands.dispatch(goToLine.miniEditor.element, 'core:confirm')
      expect(goToLine.panel.isVisible()).toBeFalsy()
      expect(editor.getCursorBufferPosition()).toEqual [3, 18]

  describe "when core:cancel is triggered", ->
    it "closes the view and does not update the cursor position", ->
      atom.commands.dispatch editorView, 'go-to-line:toggle'
      expect(goToLine.panel.isVisible()).toBeTruthy()
      atom.commands.dispatch(goToLine.miniEditor.element, 'core:cancel')
      expect(goToLine.panel.isVisible()).toBeFalsy()
      expect(editor.getCursorBufferPosition()).toEqual [1, 0]

  describe "when entering a line number with delay and without confirm", ->
    it "cursor should navigate to the line number", ->
      atom.commands.dispatch editorView, 'go-to-line:toggle'
      expect(goToLine.panel.isVisible()).toBeTruthy()
      goToLine.miniEditor.getModel().insertText '5'
      advanceClock(editor.buffer.stoppedChangingDelay)
      expect(goToLine.panel.isVisible()).toBeTruthy()
      expect(editor.getCursorBufferPosition()).toEqual [4, 4]
      goToLine.miniEditor.getModel().insertText '1'
      advanceClock(editor.buffer.stoppedChangingDelay)
      atom.commands.dispatch(goToLine.miniEditor.element, 'core:confirm')
      expect(goToLine.panel.isVisible()).toBeFalsy()
      expect(editor.getCursorBufferPosition()).toEqual [50, 0]

  describe "when line number is entered and cancelled", ->
    it "cursor should navigate to the initial position before navigation", ->
      atom.commands.dispatch editorView, 'go-to-line:toggle'
      expect(goToLine.panel.isVisible()).toBeTruthy()
      goToLine.miniEditor.getModel().insertText '51'
      advanceClock(editor.buffer.stoppedChangingDelay)
      atom.commands.dispatch(goToLine.miniEditor.element, 'core:confirm')
      expect(goToLine.panel.isVisible()).toBeFalsy()
      expect(editor.getCursorBufferPosition()).toEqual [50, 0]
      atom.commands.dispatch editorView, 'go-to-line:toggle'
      expect(goToLine.panel.isVisible()).toBeTruthy()
      goToLine.miniEditor.getModel().insertText '20'
      advanceClock(editor.buffer.stoppedChangingDelay)
      expect(editor.getCursorBufferPosition()).toEqual [19, 4]
      atom.commands.dispatch(goToLine.miniEditor.element, 'core:cancel')
      expect(goToLine.panel.isVisible()).toBeFalsy()
      expect(editor.getCursorBufferPosition()).toEqual [50, 0]
