class InPlaceEditing

  constructor: ->
    @table = $('.items-list').attr("data-table")
    @model = $('.items-list').attr("data-model")
    $(".items-list td[data-column-name]:not([data-mode=editing])").bind 'hover', @setupEditableColumn
    $(document).keyup (ev) ->
      $(".items-list td[data-mode=editing] a").click() if ev.keyCode is 27

  setupEditableColumn: (elt) =>
    td = $(elt.currentTarget)
    if td.find('i.icon-pencil').length is 0 && td.attr('data-mode') isnt 'editing'
      $("<i class='icon-pencil'>").appendTo(td).click @switchToEditionMode

  switchToEditionMode: (elt) =>
    td = $(elt.currentTarget).parents("td")
    raw_value = td.attr("data-raw-value")
    raw_value = td.text() unless raw_value
    column = td.attr('data-column-name')
    name = "#{@model}[#{column}]"
    type = columns_hash[column].type
    type = 'enum' if adminium_column_options[column].is_enum
    if td.find('a i.icon-plus-sign').length
      type = 'text'
      raw_value = td.find('a').attr('data-content')
    td.attr("data-original-text", td.text())
    td.html($("<form class='form form-inline'><div class='control-group'><div class='controls'><div><button class='btn' ><i class='icon-ok' /></button><a>cancel</a></div>"))
    td.attr("data-mode", "editing")
    td.find('a').click @cancelEditionMode
    td.find('form').submit @submitColumnEdition
    if this["#{type}EditionMode"]
      input = this["#{type}EditionMode"](td, name, raw_value)
    else
      input = @defaultEditionMode td, name
    input.prependTo(td.find('.controls'))
    input.val(raw_value).focus()
    input.attr('name', name)

  textEditionMode: (td) =>
    $('<textarea>')

  dateEditionMode: (td, name, raw_value) =>
    @datetimeEditionMode td, name, raw_value

  datetimeEditionMode: (td, name, raw_value) =>
    d = $('<div>')
    d.prependTo(td.find('.controls'))
    i = $('<input>')
    i.attr('name', name)
    time = raw_value.split(" ")
    time.shift()
    time = time.join(" ")
    d.datepicker({altField:i,  altFormat : "yy-mm-dd #{time}"})
    i

  defaultEditionMode: (td, name) =>
    $('<input>')

  enumEditionMode: (td, name, raw_value) =>
    options = ""
    column = td.attr('data-column-name')
    for display, value of adminium_column_options[column].values
      options += "<option value=#{value}>#{display}</option>"
    return $("<select>#{options}")

  booleanEditionMode: (td, name) =>
    options = ""
    column = td.attr('data-column-name')
    f = adminium_column_options[column].boolean_false || "false"
    t = adminium_column_options[column].boolean_true || "true"
    display = {"true" : t, "false" : f}
    for value in [null, 'true', 'false']
      v = if value then "value='#{value}'> #{display[value]}" else "value= >"
      options += "<option #{v}</option>"
    $("<select>#{options}")

  submitColumnEdition: (elt) =>
    form = $(elt.currentTarget)
    id = form.parents('tr').attr("data-item-id")
    spinner = $("#facebookG").clone()
    form.find('.btn').replaceWith(spinner)
    form.find('a').remove()
    $.ajax({
      type: 'POST',
      url: "/resources/#{@table}/#{id}",
      data: "#{form.serialize()}&_method=PUT",
      success: @submitCallback,
      error: @errorCallback
    })
    false

  submitCallback: (data) =>
    if data.result is "success"
      td = $(".items-list tr[data-item-id=#{data.id}] td=[data-column-name=#{data.column}]").replaceWith(data.value)
      new_td = $(".items-list tr[data-item-id=#{data.id}] td=[data-column-name=#{data.column}]")
      new_td.bind 'hover', @setupEditableColumn
    else
      alert(data.message)
      td = $(".items-list tr[data-item-id=#{data.id}] td=[data-column-name=#{data.column}]")
      @restoreOriginalValue(td)

  errorCallback: (data) =>
    alert('internal error : failed to update this field')

  cancelEditionMode: (elt) =>
    td = $(elt.currentTarget).parents('td')
    @restoreOriginalValue(td)
    false

  restoreOriginalValue: (td) =>
    td.text(td.attr("data-original-text"))
    td.removeAttr("data-mode").removeAttr("data-original-text")


$ ->
  new InPlaceEditing()