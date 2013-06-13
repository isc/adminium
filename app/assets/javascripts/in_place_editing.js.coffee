class InPlaceEditing

  constructor: ->
    $('.items-list, .resources.show table')
      .on('hover', 'td[data-column-name]', @setupEditableColumn)
      .on('click', 'td[data-column-name] i.icon-pencil', @switchToEditionModeByClickingIcon)
      .on('dblclick', 'td[data-column-name]', @switchToEditionModeByDblClicking)

  setupEditableColumn: (elt) =>
    td = $(elt.currentTarget)
    if td.find('i.icon-pencil').length is 0 and td.attr('data-mode') isnt 'editing'
      $("<i class='icon-pencil'>").appendTo(td)

  switchToEditionModeByClickingIcon: (elt) =>
    td = $(elt.currentTarget).parents('td')
    @switchToEditionMode(td)
    
  switchToEditionModeByDblClicking: (elt) =>
    td = $(elt.currentTarget)
    @switchToEditionMode(td)
  
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
    if td.find('a i.icon-plus-sign').length
      type = 'text'
      raw_value = td.find('a').attr('data-content')
    td.attr("data-original-content", td.html())
    td.html($("<form class='form form-inline' action='/resources/#{table}/#{id}'><div class='control-group'><div class='controls'><div class='in-place-actions'><button class='btn'><i class='icon-ok' /></button><a class='cancel'><i class='icon-remove'></i></a></div></div</div></form>"))
    td.attr("data-mode", "editing")
    td.find('a.cancel').click @cancelEditionMode
    td.find('form').submit @submitColumnEdition
    input = if this["#{type}EditionMode"]
      this["#{type}EditionMode"](td, name, raw_value)
    else
      @defaultEditionMode td, name, raw_value
    input.prependTo(td.find('.controls'))
    input.val(raw_value).focus()
    input.attr('name', name)
    input.data('null-value', true) if td.hasClass('nilclass')
    new EnumerateInput(input, 'open') if type is 'enum'
    new NullifiableInput(input, false, type)

  textEditionMode: (td) =>
    input = $('<textarea>')
  
  integerEditionMode: (td) =>
    $('<input type="number">')
  
  decimalEditionMode: (td) =>
    @floatEditionMode(td)
    
  floatEditionMode: (td) =>
    $('<input type="number" step="any">')

  dateEditionMode: (td, name, raw_value) =>
    @datetimeEditionMode td, name, raw_value

  timestampEditionMode: (td, name, raw_value) =>
    @datetimeEditionMode td, name, raw_value

  datetimeEditionMode: (td, name, raw_value) =>
    d = $('<div>')
    d.prependTo(td.find('.controls'))
    i = $('<input>')
    i.attr('name', name)
    if raw_value && raw_value.length > 0
      time = raw_value.split(" ")
      time.shift()
      time = time.join(" ")
    else
      time = ''
    d.datepicker altField:i,  altFormat: "yy-mm-dd #{time}"
    i

  defaultEditionMode: (td, name, raw_value) =>
    $('<input type=text>')

  enumEditionMode: (td, name, raw_value) =>
    options = ""
    column = td.attr('data-column-name')
    for value, info of adminium_column_options[column].values
      options += "<option value=#{value}>#{info.label}</option>"
    $("<select>#{options}</select>")

  booleanEditionMode: (td, name) =>
    options = ""
    column = td.attr('data-column-name')
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
    spinner = $("#facebookG").clone()
    form.find('.btn').replaceWith(spinner)
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
    alert('internal error : failed to update this field')
    @restoreOriginalValue $('td[data-mode=editing]')

  cancelEditionMode: (elt) =>
    td = $(elt.currentTarget).parents('td')
    @restoreOriginalValue(td)
    false

  restoreOriginalValue: (td) =>
    td.html(td.attr('data-original-content'))
    td.removeAttr('data-mode').removeAttr('data-original-content')


$ ->
  new InPlaceEditing()
  $(document).keyup (ev) ->
    $('td[data-mode=editing] a').click() if ev.keyCode is 27
