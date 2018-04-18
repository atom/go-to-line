'use babel'

import { Point, TextEditor } from 'atom'

class GoToLineView {
  constructor () {
    this.miniEditor = new TextEditor({ mini: true })
    this.miniEditor.element.addEventListener('blur', this.close.bind(this))

    this.message = document.createElement('div')
    this.message.classList.add('message')

    this.element = document.createElement('div')
    this.element.classList.add('go-to-line')
    this.element.appendChild(this.miniEditor.element)
    this.element.appendChild(this.message)

    this.panel = atom.workspace.addModalPanel({
      item: this,
      visible: false
    })
    atom.commands.add('atom-text-editor', 'go-to-line:toggle', () => {
      this.toggle()
      return false
    })
    atom.commands.add(this.miniEditor.element, 'core:confirm', () => {
      this.confirm()
    })
    atom.commands.add(this.miniEditor.element, 'core:cancel', () => {
      this.close()
    })
    this.miniEditor.onWillInsertText((arg) => {
      if (this.miniEditor.getText().length > 0) {
        if (arg.text.match(/[^0-9:]/)) {
          arg.cancel()
        }
      } else if (arg.text.match(/[^0-9:\-+=]/)) {
        arg.cancel()
      }
    })
  }

  toggle () {
    this.panel.isVisible() ? this.close() : this.open()
  }

  close () {
    if (!this.panel.isVisible()) return
    this.miniEditor.setText('')
    this.panel.hide()
    if (this.miniEditor.element.hasFocus()) {
      this.restoreFocus()
    }
  }

  confirm () {
    const lineNumber = this.miniEditor.getText()
    const editor = atom.workspace.getActiveTextEditor()
    this.close()
    if (!editor || !lineNumber.length) return

    const currentRow = editor.getCursorBufferPosition().row
    const rowLineNumber = lineNumber.split(/:+/)[0] || ''
    let row = currentRow
    if (rowLineNumber.length > 0) {
      if (rowLineNumber[0] === '-') {
        if (rowLineNumber.length === 1) return
        // Go backward
        const delta = parseInt(rowLineNumber.substring(1))
        row = currentRow - delta
      } else if (rowLineNumber[0] === '+' || rowLineNumber[0] === '=') {
        if (rowLineNumber.length === 1) return
        // Go forward
        const delta = parseInt(rowLineNumber.substring(1))
        row = currentRow + delta
      } else {
        // Absolute line number
        row = parseInt(rowLineNumber) - 1
      }
    }

    const columnLineNumber = lineNumber.split(/:+/)[1] || ''
    const column = columnLineNumber.length > 0 ? parseInt(columnLineNumber) - 1 : -1

    const position = new Point(row, column)
    editor.setCursorBufferPosition(position)
    editor.unfoldBufferRow(row)
    if (column < 0) {
      editor.moveToFirstCharacterOfLine()
    }
    editor.scrollToBufferPosition(position, {
      center: true
    })
  }

  storeFocusedElement () {
    this.previouslyFocusedElement = document.activeElement
    return this.previouslyFocusedElement
  }

  restoreFocus () {
    if (this.previouslyFocusedElement && this.previouslyFocusedElement.parentElement) {
      return this.previouslyFocusedElement.focus()
    }
    atom.views.getView(atom.workspace).focus()
  }

  open () {
    if (this.panel.isVisible() || !atom.workspace.getActiveTextEditor()) return
    this.storeFocusedElement()
    this.panel.show()
    this.message.textContent = 'Enter a <row> or <row>:<column> to go there. Examples: "3" for row 3 or "2:7" for row 2 and column 7'
    this.miniEditor.element.focus()
  }
}

export default {
  activate () {
    return new GoToLineView()
  }
}
