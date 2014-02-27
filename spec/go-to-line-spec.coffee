{WorkspaceView} = require 'atom'
GoToLineView = require '../lib/go-to-line-view'

describe 'GoToLine', ->
  [goToLine, editor, editorView] = []

  beforeEach ->
    atom.workspaceView = new WorkspaceView
    atom.workspace = atom.workspaceView.model
    atom.workspaceView.openSync('sample.js')
    atom.workspaceView.enableKeymap()
    editorView = atom.workspaceView.getActiveView()
    {editor} = editorView
    goToLine = GoToLineView.activate()
    editor.setCursorBufferPosition([1,0])

  describe "when go-to-line:toggle is triggered", ->
    it "attaches to the root view", ->
      expect(goToLine.hasParent()).toBeFalsy()
      editorView.trigger 'go-to-line:toggle'
      expect(goToLine.hasParent()).toBeTruthy()

  describe "when entering a line number", ->
    it "only allows 0-9 to be entered in the mini editor", ->
      expect(goToLine.miniEditor.getText()).toBe ''
      goToLine.miniEditor.textInput 'a'
      expect(goToLine.miniEditor.getText()).toBe ''
      goToLine.miniEditor.textInput '40'
      expect(goToLine.miniEditor.getText()).toBe '40'

  describe "when core:confirm is triggered", ->
    describe "when a line number has been entered", ->
      it "moves the cursor to the first character of the line", ->
        goToLine.miniEditor.textInput '3'
        goToLine.miniEditor.trigger 'core:confirm'
        expect(editor.getCursorBufferPosition()).toEqual [2, 4]

    describe "when no line number has been entered", ->
      it "closes the view and does not update the cursor position", ->
        editorView.trigger 'go-to-line:toggle'
        expect(goToLine.hasParent()).toBeTruthy()
        goToLine.miniEditor.trigger 'core:confirm'
        expect(goToLine.hasParent()).toBeFalsy()
        expect(editor.getCursorBufferPosition()).toEqual [1, 0]

  describe "when core:cancel is triggered", ->
    it "closes the view and does not update the cursor position", ->
      editorView.trigger 'go-to-line:toggle'
      expect(goToLine.hasParent()).toBeTruthy()
      goToLine.miniEditor.trigger 'core:cancel'
      expect(goToLine.hasParent()).toBeFalsy()
      expect(editor.getCursorBufferPosition()).toEqual [1, 0]
