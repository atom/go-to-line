{Point} = require 'atom'
{$, TextEditorView, View}  = require 'atom-space-pen-views'

module.exports =
class GoToLineView extends View
  @activate: -> new GoToLineView

  @content: ->
    @div class: 'go-to-line', =>
      @subview 'miniEditor', new TextEditorView(mini: true)
      @div class: 'message', outlet: 'message'

  initialize: ->
    @panel = atom.workspace.addModalPanel(item: this, visible: false)

    atom.commands.add 'atom-text-editor', 'go-to-line:toggle', =>
      @toggle()
      false

    @miniEditor.on 'blur', => @close()
    atom.commands.add @miniEditor.element, 'core:confirm', => @confirm()
    atom.commands.add @miniEditor.element, 'core:cancel', => @close()

    @miniEditor.getModel().onWillInsertText ({cancel, text}) =>
      cancel() unless text.match(/[0-9:]/)

  toggle: ->
    if @panel.isVisible()
      @close()
    else
      @open()

  close: ->
    return unless @panel.isVisible()

    miniEditorFocused = @miniEditor.hasFocus()
    @miniEditor.setText('')
    @panel.hide()
    @restoreFocus() if miniEditorFocused

  confirm: ->
    lineNumber = @miniEditor.getText()
    editor = atom.workspace.getActiveTextEditor()

    @close()

    return unless editor? and lineNumber.length

    currentRow = editor.getCursorBufferPosition().row
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
    editor.scrollToBufferPosition(position, center: true)
    editor.setCursorBufferPosition(position)
    if column < 0
      editor.moveToFirstCharacterOfLine()

  storeFocusedElement: ->
    @previouslyFocusedElement = $(':focus')

  restoreFocus: ->
    if @previouslyFocusedElement?.isOnDom()
      @previouslyFocusedElement.focus()
    else
      atom.views.getView(atom.workspace).focus()

  open: ->
    return if @panel.isVisible()

    if editor = atom.workspace.getActiveTextEditor()
      @storeFocusedElement()
      @panel.show()
      @message.text("Enter a line row:column to go to")
      @miniEditor.focus()
