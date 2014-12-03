GoToLineView = require '../lib/go-to-line-view'

describe 'GoToLine', ->
  [goToLine, editor, editorView] = []

  beforeEach ->
    waitsForPromise ->
      atom.workspace.open('sample.js')

    runs ->
      editor = atom.workspace.getActiveTextEditor()
      editorView = atom.views.getView(editor)
      goToLine = GoToLineView.activate()
      editor.setCursorBufferPosition([1,0])

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
      atom.commands.dispatch(goToLine.miniEditor.element, 'core:confirm')
      expect(editor.getCursorBufferPosition()).toEqual [2, 13]

  describe "when entering a line number greater than the number in the buffer", ->
    it "moves the cursor position to the first character of the last line", ->
      atom.commands.dispatch editorView, 'go-to-line:toggle'
      expect(goToLine.panel.isVisible()).toBeTruthy()
      expect(goToLine.miniEditor.getText()).toBe ''
      goToLine.miniEditor.getModel().insertText '14'
      atom.commands.dispatch(goToLine.miniEditor.element, 'core:confirm')
      expect(goToLine.panel.isVisible()).toBeFalsy()
      expect(editor.getCursorBufferPosition()).toEqual [12, 0]

  describe "when entering a column number greater than the number in the specified line", ->
    it "moves the cursor position to the last character of the specified line", ->
      atom.commands.dispatch editorView, 'go-to-line:toggle'
      expect(goToLine.panel.isVisible()).toBeTruthy()
      expect(goToLine.miniEditor.getText()).toBe ''
      goToLine.miniEditor.getModel().insertText '3:43'
      atom.commands.dispatch(goToLine.miniEditor.element, 'core:confirm')
      expect(goToLine.panel.isVisible()).toBeFalsy()
      expect(editor.getCursorBufferPosition()).toEqual [2, 40]

  describe "when core:confirm is triggered", ->
    describe "when a line number has been entered", ->
      it "moves the cursor to the first character of the line", ->
        goToLine.miniEditor.getModel().insertText '3'
        atom.commands.dispatch(goToLine.miniEditor.element, 'core:confirm')
        expect(editor.getCursorBufferPosition()).toEqual [2, 4]

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
      atom.commands.dispatch(goToLine.miniEditor.element, 'core:confirm')
      expect(goToLine.panel.isVisible()).toBeFalsy()
      expect(editor.getCursorBufferPosition()).toEqual [3, 0]
      atom.commands.dispatch editorView, 'go-to-line:toggle'
      expect(goToLine.panel.isVisible()).toBeTruthy()
      goToLine.miniEditor.getModel().insertText ':19'
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
