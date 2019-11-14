class InPlaceEditing

  constructor: ->
    $('.items-list, .resources.show table')
      .on('mouseover', 'td[data-editable]', @setupEditableColumn)
      .on('click', 'td[data-editable] i.fa-pencil', @switchToEditionModeByClickingIcon)
      .on('dblclick', 'td[data-editable]', @switchToEditionModeByDblClicking)

  setupEditableColumn: (elt) =>
    td = $(elt.currentTarget)
    if not td.find('i.fa-pencil').length and td.attr('data-mode') isnt 'editing'
      $("<i class='fa fa-pencil cell-action' title='Edit this value' >").appendTo(td)

  integerEditionMode: -> $('<input type="number">')
  floatEditionMode: -> $('<input type="number" step="any">')
  dateEditionMode: -> $('<input type="date">')
  defaultEditionMode: (raw_value) ->
    if raw_value?.match("\n") then $('<textarea>') else $('<input type=text>')
  datetimeEditionMode: (td, name, raw_value) =>
    [date, time] = raw_value?.split(' ') or ['', '']
    $('<span>')
    .append $('<input type="date">').attr('name', "#{name}[date]").val(date).addClass('form-control')
    .append @buildSelect(24).attr('name', "#{name}[4i]").val(time.split(':')[0])
    .append ' : '
    .append @buildSelect(60).attr('name', "#{name}[5i]").val(time.split(':')[1])

  switchToEditionModeByClickingIcon: (elt) =>
    @switchToEditionMode $(elt.currentTarget).parents('td')

  switchToEditionModeByDblClicking: (elt) =>
    @switchToEditionMode $(elt.currentTarget)

  switchToEditionMode: (td) =>
    return if @submitInProgress
    $("td[data-mode=editing] a").click()
    raw_value = td.attr('data-raw-value')
    raw_value = td.text() unless raw_value or td.hasClass('nilclass') or td.hasClass('emptystring')
    column = td.attr('data-column-name')
    header = $('.items-list thead th').eq(td.index())
    table = $('.item-attributes').data('table') or header.data('table-name')
    type = td.data('column-type') or header.data('column-type')
    name = "#{table}[#{column}]"
    # TODO enum for associated column
    type = 'enum' if adminium_column_options[column]?.is_enum
    id = td.data('item-id') or td.parents('tr').data('item-id') or $('.item-attributes').data('item-id')
    if td.find('a i.fa-plus-circle').length
      type = 'text'
      raw_value = $(td.find('a').attr('data-target')).find('.modal-body').text()
    td.attr('data-original-content', td.html())
    td.html($("<form class='well form form-inline' action='/resources/#{table}/#{id}'><div class='control-group'><div class='controls'>&nbsp;<button class='btn btn-sm btn-primary'><i class='fa fa-check' /></button><a class='cancel btn btn-sm'><i class='fa fa-remove'></i></a></div</div></form>")).attr('data-mode', 'editing')
    td.find('a.cancel').click @cancelEditionMode
    td.find('form').submit @submitColumnEdition
    type = {decimal: 'float', timestamp: 'datetime'}[type] or type
    input = if this["#{type}EditionMode"]
      this["#{type}EditionMode"](td, name, raw_value)
    else
      @defaultEditionMode(raw_value)
    input.prependTo(td.find('.controls'))
    input.val(raw_value) unless input.val()
    if input.prop('tagName') is 'SPAN'
      td.find('.controls').addClass('datetime-in-place-edit')
    else
      input.attr('name', name).addClass('form-control').focus()
    input.data('null-value', true) if td.hasClass('nilclass')
    initDatepickers()
    new EnumerateInput(input, 'open') if type is 'enum'
    new NullifiableInput(input, false, type) unless input.prop('tagName') is 'SPAN'

  enumEditionMode: (td) =>
    [options, column, select] = ['', td.attr('data-column-name'), $('<select>')]
    for value, info of adminium_column_options[column].values
      $('<option>').attr('value', value).text(info.label).appendTo(select)
    select

  booleanEditionMode: (td) =>
    [options, column] = ['', td.attr('data-column-name')]
    f = adminium_column_options[column].boolean_false or 'false'
    t = adminium_column_options[column].boolean_true or 'true'
    display = {true: t, false: f}
    for value in [null, 'true', 'false']
      v = if value then "value='#{value}'> #{display[value]}" else 'value= >'
      options += "<option #{v}</option>"
    $("<select>#{options}</select>")

  submitColumnEdition: (elt) =>
    @submitInProgress = true
    form = $(elt.currentTarget)
    form.find('.btn').attr(disabled: true).find('i').removeClass('fa-check').addClass('fa-spin fa-spinner')
    form.find('a').remove()
    $.ajax
      type: 'POST'
      url: form.attr('action')
      data: "#{form.serialize()}&_method=PUT"
      success: @submitCallback
      error: @errorCallback
      dataType: 'json'
    false

  submitCallback: (data) =>
    @submitInProgress = false
    td = $('td[data-mode=editing]')
    if data.result is 'success'
      td.replaceWith(data.value)
    else
      alert data.message
      @restoreOriginalValue td

  errorCallback: (data) =>
    alert('Internal error : failed to update this field.')
    @restoreOriginalValue $('td[data-mode=editing]')

  cancelEditionMode: (elt) =>
    td = $(elt.currentTarget).parents('td')
    @restoreOriginalValue(td)
    false

  restoreOriginalValue: (td) ->
    td.html(td.attr('data-original-content')).removeAttr('data-mode').removeAttr('data-original-content')

  buildSelect: (max) =>
    select = $('<select>').addClass('form-control')
    for i in [0...max]
      val = if i < 10 then "0#{i}" else i.toString()
      select.append $('<option>').val(val).text(val)
    select

$ ->
  new InPlaceEditing()
  $(document).keyup (ev) ->
    $('td[data-mode=editing] a').click() if ev.keyCode is 27
