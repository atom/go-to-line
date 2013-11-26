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
    atom.workspaceView.command 'editor:go-to-line', '.editor', => @toggle()
    @miniEditor.hiddenInput.on 'focusout', => @detach() unless @detaching
    @on 'core:confirm', => @confirm()
    @on 'core:cancel', => @detach()

    @miniEditor.preempt 'textInput', (e) =>
      false unless e.originalEvent.data.match(/[0-9]/)

  toggle: ->
    if @hasParent()
      @detach()
    else
      @attach()

  detach: ->
    return unless @hasParent()

    @detaching = true
    @miniEditor.setText('')

    if @previouslyFocusedElement?.isOnDom()
      @previouslyFocusedElement.focus()
    else
      atom.workspaceView.focus()

    super

    @detaching = false

  confirm: ->
    lineNumber = @miniEditor.getText()
    editor = atom.workspaceView.getActiveView()

    @detach()

    return unless editor and lineNumber.length
    position = new Point(parseInt(lineNumber - 1))
    editor.scrollToBufferPosition(position, center: true)
    editor.setCursorBufferPosition(position)
    editor.moveCursorToFirstCharacterOfLine()

  attach: ->
    @previouslyFocusedElement = $(':focus')
    atom.workspaceView.append(this)
    @message.text("Enter a line number 1-#{atom.workspaceView.getActiveView().getLineCount()}")
    @miniEditor.focus()
