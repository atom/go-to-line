{$, EditorView, Point, View} = require 'atom'

module.exports =
class GoToLineView extends View
  @activate: -> new GoToLineView

  @content: ->
    @div class: 'go-to-line overlay from-top mini', =>
      @subview 'miniEditor', new EditorView(mini: true)
      @div class: 'message', outlet: 'message'

  detaching: false

  initialize: ->
    atom.workspaceView.command 'go-to-line:toggle', '.editor', =>
      @toggle()
      false

    @miniEditor.hiddenInput.on 'focusout', => @detach() unless @detaching
    @on 'core:confirm', => @confirm()
    @on 'core:cancel', => @detach()

    @miniEditor.getModel().on 'will-insert-text', ({cancel, text}) =>
      cancel() unless text.match(/[0-9]|:/)

  toggle: ->
    if @hasParent()
      @detach()
    else
      @attach()

  detach: ->
    return unless @hasParent()

    @detaching = true
    miniEditorFocused = @miniEditor.isFocused
    @miniEditor.setText('')

    super

    @restoreFocus() if miniEditorFocused
    @detaching = false

  confirm: ->
    lineNumber = @miniEditor.getText()
    editorView = atom.workspaceView.getActiveView()

    @detach()

    return unless editorView? and lineNumber.length

    currentLineNum = editorView.getModel().getCursorBufferPosition().row
    lineAndCol = lineNumber.split(':')
    if lineAndCol[0]?.length > 0
      # Line number was specified
      lineNum = parseInt(lineAndCol[0]) - 1
    else
      # Line number was not specified, so assume we will be at the same line
      # as where the cursor currently is (no change)
      lineNum = currentLineNum

    if lineAndCol[1]?.length > 0
      # Column number was specified
      colNum = parseInt(lineAndCol[1]) - 1
    else
      # Column number was not specified, so if the line number was specified,
      # then we should assume that we're navigating to the first character
      # of the specified line.
      colNum = -1

    linePos = new Point(lineNum, colNum)
    editorView.scrollToBufferPosition(linePos, center: true)
    editorView.editor.setCursorBufferPosition(linePos)
    if colNum < 0
      editorView.editor.moveCursorToFirstCharacterOfLine()

  storeFocusedElement: ->
    @previouslyFocusedElement = $(':focus')

  restoreFocus: ->
    if @previouslyFocusedElement?.isOnDom()
      @previouslyFocusedElement.focus()
    else
      atom.workspaceView.focus()

  attach: ->
    if editor = atom.workspace.getActiveEditor()
      @storeFocusedElement()
      atom.workspaceView.append(this)
      @message.text("Enter a line number 1-#{editor.getLineCount()} and column number")
      @miniEditor.focus()
