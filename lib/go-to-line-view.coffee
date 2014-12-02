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
    atom.commands.add 'atom-text-editor', 'go-to-line:toggle', =>
      @toggle()
      false

    @miniEditor.hiddenInput.on 'focusout', => @detach() unless @detaching
    @on 'core:confirm', => @confirm()
    @on 'core:cancel', => @detach()

    @miniEditor.getModel().on 'will-insert-text', ({cancel, text}) =>
      cancel() unless text.match(/[0-9:]/)

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

    currentRow = editorView.getModel().getCursorBufferPosition().row
    [row, column] = lineNumber.split(/:+/)
    if row?.length > 0
      # Line number was specified
      row = parseInt(row) - 1
    else
      # Line number was not specified, so assume we will be at the same line
      # as where the cursor currently is (no change)
      row = currentRow

    if column?.length > 0
      # Column number was specified
      column = parseInt(column) - 1
    else
      # Column number was not specified, so if the line number was specified,
      # then we should assume that we're navigating to the first character
      # of the specified line.
      column = -1

    position = new Point(row, column)
    editorView.scrollToBufferPosition(position, center: true)
    editorView.editor.setCursorBufferPosition(position)
    if column < 0
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
      @message.text("Enter a line row:column to go to")
      @miniEditor.focus()
