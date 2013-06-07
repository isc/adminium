class InPlaceEditing

  constructor: ->
    @table = $('*[data-table]').data('table')
    $('td[data-column-name]').bind 'hover', @setupEditableColumn
    $('.items-list, .resources.show table').on 'click', 'td[data-column-name] i.icon-pencil', @switchToEditionModeByClickingIcon
    $('.items-list, .resources.show table').on 'dblclick', 'td[data-column-name]', @switchToEditionModeByDblClicking

  setupEditableColumn: (elt) =>
    td = $(elt.currentTarget)
    if td.find('i.icon-pencil').length is 0 and td.attr('data-mode') isnt 'editing'
      $("<i class='icon-pencil'>").appendTo(td)

  switchToEditionModeByClickingIcon: (elt) =>
    td = $(elt.currentTarget).parents("td")
    @switchToEditionMode(td)
    
  switchToEditionModeByDblClicking: (elt) =>
    td = $(elt.currentTarget)
    @switchToEditionMode(td)
  
  switchToEditionMode: (td) =>
    $("td[data-mode=editing] a").click()
    raw_value = td.attr('data-raw-value')
    raw_value = td.text() unless raw_value or td.hasClass('nilclass') or td.hasClass('emptystring')
    column = td.attr('data-column-name')
    name = "#{@table}[#{column}]"
    type = columns_hash[column].type
    type = 'enum' if adminium_column_options[column].is_enum
    if td.find('a i.icon-plus-sign').length
      type = 'text'
      raw_value = td.find('a').attr('data-content')
    td.attr("data-original-content", td.html())
    td.html($("<form class='form form-inline'><div class='control-group'><div class='controls'><div class='in-place-actions'><button class='btn'><i class='icon-ok' /></button><a class='cancel'><i class='icon-remove'></i></a></div>"))
    td.attr("data-mode", "editing")
    td.find('a.cancel').click @cancelEditionMode
    td.find('form').submit @submitColumnEdition
    if this["#{type}EditionMode"]
      input = this["#{type}EditionMode"](td, name, raw_value)
    else
      input = @defaultEditionMode td, name, raw_value
    input.prependTo(td.find('.controls'))
    input.val(raw_value).focus()
    input.attr('name', name)
    input.data('null-value', true) if td.hasClass('nilclass')
    new EnumerateInput(input) if type == 'enum'
    new NullifiableInput(input)

  
    
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
    $("<select>#{options}")

  booleanEditionMode: (td, name) =>
    options = ""
    column = td.attr('data-column-name')
    f = adminium_column_options[column].boolean_false or 'false'
    t = adminium_column_options[column].boolean_true or 'true'
    display = {true: t, false: f}
    for value in [null, 'true', 'false']
      v = if value then "value='#{value}'> #{display[value]}" else 'value= >'
      options += "<option #{v}</option>"
    $("<select>#{options}")

  submitColumnEdition: (elt) =>
    form = $(elt.currentTarget)
    id = form.parents('tr').attr("data-item-id")
    id = $('.row-fluid[data-item-id]').attr('data-item-id') unless id
    spinner = $("#facebookG").clone()
    form.find('.btn').replaceWith(spinner)
    form.find('a').remove()
    $.ajax
      type: 'POST'
      url: "/resources/#{@table}/#{id}"
      data: "#{form.serialize()}&_method=PUT"
      success: @submitCallback
      error: @errorCallback
      dataType: 'json'
    false

  submitCallback: (data) =>
    if $('.items-list').length
      td_css_path = ".items-list tr[data-item-id=#{data.id}] td=[data-column-name=#{data.column}]"
    else
      td_css_path = "td[data-column-name=#{data.column}]"
    if data.result is 'success'
      td = $(td_css_path).replaceWith(data.value)
      $(td_css_path).bind 'hover', @setupEditableColumn
    else
      alert(data.message)
      @restoreOriginalValue $(td_css_path)

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
