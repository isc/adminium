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
    td.html($("<form class='form form-inline'><div class='control-group'><div class='controls'><div class='null_btn selected'>NULL</div><div class='empty_string_btn'>empty string</div><div class='in-place-actions'><button class='btn'><i class='icon-ok' /></button><a class='cancel'><i class='icon-remove'></i></a></div><input name=save_empty_input_as value=null type='hidden'></input>"))
    td.attr("data-mode", "editing")
    td.find('a.cancel').click @cancelEditionMode
    td.find('form').submit @submitColumnEdition
    if this["#{type}EditionMode"]
      input = this["#{type}EditionMode"](td, name, raw_value)
    else
      input = @defaultEditionMode td, name, raw_value
    input.prependTo(td.find('.controls'))
    @setBtnPositions(td)
    switchLink = td.find('.null_btn, .empty_string_btn')
    switchLink.click (evt) =>
      @switchEmptyInputValue($(evt.currentTarget))
      false
    @switchEmptyInputValue($('.empty_string_btn')) if td.hasClass('emptystring')
    input.val(raw_value).focus()
    input.attr('name', name)

  setBtnPositions: (elt) =>
    input = elt.find('input[type=text]')
    return if input.length == 0
    left = input.position().left + input.width()  - elt.find(".empty_string_btn").width() - 2
    elt.find(".empty_string_btn").css('left', left)
    left += elt.find(".null_btn").width() - 3
    elt.find(".null_btn").css('left', left - elt.find(".empty_string_btn").width())
      
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
    time = raw_value.split(" ")
    time.shift()
    time = time.join(" ")
    d.datepicker altField:i,  altFormat: "yy-mm-dd #{time}"
    i

  defaultEditionMode: (td, name, raw_value) =>
    @showNullBlankBtn(td, !(raw_value && raw_value.length > 0))
    input  = $('<input type=text>')
    input.on 'keyup', @displaySwitchEmptyValueLink
    input
  
  displaySwitchEmptyValueLink: (evt) =>
    key = evt.keyCode || evt.charCode;
    input = $(evt.currentTarget)
    value = input.val()
    show = value.length == 0
    @showNullBlankBtn(input.parents('td'), show)
    
  
  showNullBlankBtn: (elt, show) =>
    elt.find('.empty_string_btn, .null_btn').toggleClass('active', show)
    @setBtnPositions(elt)

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

  switchEmptyInputValue: (link) =>
    $(".empty_string_btn, .null_btn").removeClass('selected')
    link.addClass('selected')
    input = link.parents('td').find('input[type=text]').focus()
    hidden_input = link.parents('td').find('input[name=save_empty_input_as]')
    if link.hasClass('empty_string_btn')
      hidden_input.val('empty_string')
    else
      hidden_input.val('null')

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
