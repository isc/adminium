class @EnumerateInput
  
  constructor: (input, action) ->
    return unless input[0]
    column = input[0].name.match(/\[(.*)\]/)[1]
    @values = adminium_column_options[column].values
    options = {matcher: adminiumSelect2Matcher, formatResult: @format, dropdownCssClass: 'enumedit'}
    input.select2(options)
    if action
      input.select2(action)
    input

  format: (state) =>
    if @values[state.id]
      "<div class='label label-info' style='background-color: #{@values[state.id].color}'>#{state.text}</div>"
    else
      state.text
  
  @setupForEdit: (scope) ->
    return if $(scope).length == 0
    for name, info of adminium_column_options
      if info['is_enum']
        new EnumerateInput($("#{scope} select[id*=_#{name}]"))
    return
    
$ ->
  EnumerateInput.setupForEdit("body.resources.edit")