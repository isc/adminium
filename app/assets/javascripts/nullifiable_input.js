class NullifiableInput {
  constructor(input, bulkEdit) {
    this.bulkEditMode = bulkEdit
    this.input = input
    const match = input.get(0).name.match(/\[(.*)\](\[\d\])*/)
    if (!match) return
    this.column_name = match[1]
    const type = columns_hash[this.column_name]?.type
    if (type !== 'string' && type !== 'text') return
    const controls = input.parents('.controls')
    const title_n = 'Will save a NULL value if selected'
    const title_e = 'Will save an empty string if selected'
    this.btns = $(
      `<div class='null_btn btn btn-xs btn-default' title='${title_n}'>null</div><div class='empty_string_btn btn-info btn btn-xs btn-default' title='${title_e}'>empty string</div>`
    )
    this.btns.tooltip({ container: 'body' })
    const hidden_input_name = input
      .get(0)
      .name.replace('[', '_nullify_settings[')
    this.hidden_input = $(
      `<input name='${hidden_input_name}' value='empty_string' type='hidden'></input>`
    )
    controls.append(this.btns).append(this.hidden_input)
    this.empty_string_btn = controls.find('.empty_string_btn')
    this.null_btn = controls.find('.null_btn')
    this.input.on('keyup', () => this.toggleBtns())
    this.setBtnPositions()
    this.toggleBtns()
    this.btns.click(evt => {
      this.switchEmptyInputValue($(evt.currentTarget), true)
      return false
    })
    if (this.bulkEditMode) this.unselectBoth()
    else if (input.data('null-value'))
      this.switchEmptyInputValue(this.null_btn, false)
  }

  toggleBtns() {
    const show = this.input.val().length === 0
    if (show && this.bulkEditMode) this.unselectBoth()
    this.btns.toggleClass('hidden', !show)
  }

  setBtnPositions() {
    if (this.input.length == 0) return
    const left =
      this.input.position().left +
      this.input.width() -
      this.empty_string_btn.width() +
      8
    const top = this.input.position().top
    this.empty_string_btn.css('left', left)
    this.null_btn.css('left', left - this.null_btn.width() - 15)
  }

  switchEmptyInputValue(link, user_action) {
    if (user_action) this.input.focus()
    if (this.bulkEditMode && link.hasClass('btn-info'))
      return this.unselectBoth()
    this.btns.removeClass('btn-info')
    link.addClass('btn-info')
    const value = link.hasClass('empty_string_btn') ? 'empty_string' : 'null'
    this.hidden_input.val(value)
  }

  unselectBoth() {
    this.btns.removeClass('btn-info')
    this.hidden_input.val('')
  }
}

NullifiableInput.setup = (path, bulkEdit) => {
  $(path).each((index, elt) => new NullifiableInput($(elt), bulkEdit))
}
