class InPlaceEditing {
  constructor() {
    $('.items-list, .resources.show table')
      .on('mouseover', 'td[data-editable]', elt =>
        this.setupEditableColumn(elt)
      )
      .on('click', 'td[data-editable] i.fa-pencil', elt =>
        this.switchToEditionModeByClickingIcon(elt)
      )
      .on('dblclick', 'td[data-editable]', elt =>
        this.switchToEditionModeByDblClicking(elt)
      )
  }

  setupEditableColumn(elt) {
    const td = $(elt.currentTarget)
    if (!td.find('i.fa-pencil').length && td.attr('data-mode') != 'editing')
      $(
        "<i class='fa fa-pencil cell-action' title='Edit this value' >"
      ).appendTo(td)
  }

  integerEditionMode() {
    return $('<input type="number">')
  }
  floatEditionMode() {
    return $('<input type="number" step="any">')
  }
  dateEditionMode() {
    return $('<input type="date">')
  }
  defaultEditionMode(raw_value) {
    return raw_value?.match('\n') ? $('<textarea>') : $('<input type=text>')
  }
  datetimeEditionMode(td, name, raw_value) {
    const [date, time] = raw_value?.split(' ') || ['', '']
    return $('<span>')
      .append(
        $('<input type="date">')
          .attr('name', `${name}[date]`)
          .val(date)
          .addClass('form-control')
      )
      .append(
        this.buildSelect(24).attr('name', `${name}[4i]`).val(time.split(':')[0])
      )
      .append(' : ')
      .append(
        this.buildSelect(60).attr('name', `${name}[5i]`).val(time.split(':')[1])
      )
  }

  switchToEditionModeByClickingIcon(elt) {
    this.switchToEditionMode($(elt.currentTarget).parents('td'))
  }

  switchToEditionModeByDblClicking(elt) {
    this.switchToEditionMode($(elt.currentTarget))
  }

  switchToEditionMode(td) {
    if (this.submitInProgress) return
    $('td[data-mode=editing] a').click()
    var raw_value = td.attr('data-raw-value')
    if (!(raw_value || td.hasClass('nilclass') || td.hasClass('emptystring')))
      raw_value = td.text()
    const column = td.attr('data-column-name')
    const header = $('.items-list thead th').eq(td.index())
    const table =
      $('.item-attributes').data('table') || header.data('table-name')
    var type = td.data('column-type') || header.data('column-type')
    const name = `${table}[${column}]`
    // TODO enum for associated column
    if (adminium_column_options[column]?.is_enum) type = 'enum'
    const id =
      td.data('item-id') ||
      td.parents('tr').data('item-id') ||
      $('.item-attributes').data('item-id')
    if (td.find('a i.fa-plus-circle').length) {
      type = 'text'
      raw_value = $(td.find('a').attr('data-target')).find('.modal-body').text()
    }
    td.attr('data-original-content', td.html())
    td.html(
      $(
        `<form class='well form form-inline' action='/resources/${table}/${id}'><div class='control-group'><div class='controls'>&nbsp;<button class='btn btn-sm btn-primary'><i class='fa fa-check' /></button><a class='cancel btn btn-sm'><i class='fa fa-remove'></i></a></div</div></form>`
      )
    ).attr('data-mode', 'editing')
    td.find('a.cancel').click(elt => this.cancelEditionMode(elt))
    td.find('form').submit(elt => this.submitColumnEdition(elt))
    type = { decimal: 'float', timestamp: 'datetime' }[type] || type
    const input = this[`${type}EditionMode`]
      ? this[`${type}EditionMode`](td, name, raw_value)
      : this.defaultEditionMode(raw_value)
    input.prependTo(td.find('.controls'))
    if (!input.val()) input.val(raw_value)
    if (input.prop('tagName') == 'SPAN')
      td.find('.controls').addClass('datetime-in-place-edit')
    else input.attr('name', name).addClass('form-control').focus()
    if (td.hasClass('nilclass')) input.data('null-value', true)
    if (type == 'enum') new EnumerateInput(input, 'open')
    if (input.prop('tagName') !== 'SPAN')
      new NullifiableInput(input, false, type)
  }
  enumEditionMode(td) {
    const options = adminium_column_options[td.attr('data-column-name')].values
    const select = $('<select>')
    Object.keys(options).forEach(value =>
      $('<option>')
        .attr('value', value)
        .text(options[value].label)
        .appendTo(select)
    )
    return select
  }
  booleanEditionMode(td) {
    const options = adminium_column_options[td.attr('data-column-name')]
    const display = {
      true: options.boolean_true || 'true',
      false: options.boolean_false || 'false'
    }
    const options_html = [null, 'true', 'false']
      .map(value => {
        const v = value ? `value='${value}'> ${display[value]}` : 'value= >'
        return `<option ${v}</option>`
      })
      .join('')
    return $(`<select>${options_html}</select>`)
  }

  submitColumnEdition(elt) {
    this.submitInProgress = true
    const form = $(elt.currentTarget)
    form
      .find('.btn')
      .attr({ disabled: true })
      .find('i')
      .removeClass('fa-check')
      .addClass('fa-spin fa-spinner')
    form.find('a').remove()
    $.ajax({
      type: 'POST',
      url: form.attr('action'),
      data: `${form.serialize()}&_method=PUT`,
      success: data => this.submitCallback(data),
      error: data => this.errorCallback(data),
      dataType: 'json'
    })
    return false
  }

  submitCallback(data) {
    this.submitInProgress = false
    const td = $('td[data-mode=editing]')
    if (data.result == 'success') td.replaceWith(data.value)
    else {
      alert(data.message)
      this.restoreOriginalValue(td)
    }
  }

  errorCallback(data) {
    alert('Internal error : failed to update this field.')
    this.restoreOriginalValue($('td[data-mode=editing]'))
  }

  cancelEditionMode(elt) {
    const td = $(elt.currentTarget).parents('td')
    this.restoreOriginalValue(td)
    return false
  }

  restoreOriginalValue(td) {
    td.html(td.attr('data-original-content'))
      .removeAttr('data-mode')
      .removeAttr('data-original-content')
  }

  buildSelect(max) {
    const select = $('<select>').addClass('form-control')
    for (var i = 0; i < max; i++) {
      const val = i < 10 ? `0${i}` : i.toString()
      select.append($('<option>').val(val).text(val))
    }
    return select
  }
}

$(() => {
  new InPlaceEditing()
  $(document).keyup(ev => {
    if (ev.keyCode == 27) $('td[data-mode=editing] a').click()
  })
})
