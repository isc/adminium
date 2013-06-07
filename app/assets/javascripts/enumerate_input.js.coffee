class @EnumerateInput
  
  constructor: (input) ->
    column = input[0].name.match(/\[(.*)\]/)[1]
    @values = adminium_column_options[column].values
    options = {matcher: adminiumSelect2Matcher, formatResult: @format, dropdownCssClass: 'enumedit'}
    input.select2(options)

  format: (state) =>
    if @values[state.id]
      "<div class='label label-info' style='background-color: #{@values[state.id].color}'>#{state.text}</div>"
    else
      state.text
  
  @setupForEdit: ->
    return if $("body.resources.edit").length == 0
    for name, info of adminium_column_options
      if info['is_enum']
        new EnumerateInput($("select[id*=_#{name}]"))
    return
    
$ ->
  EnumerateInput.setupForEdit()     