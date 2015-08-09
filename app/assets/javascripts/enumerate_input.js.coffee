class @EnumerateInput

  constructor: (input, action) ->
    return unless input[0]
    column = input[0].name.match(/\[(.*)\]/)[1]
    @values = adminium_column_options[column].values
    options = {matcher: adminiumSelect2Matcher, formatResult: @format}
    input.select2(options)
    input.select2(action) if action
    input

  format: (state) =>
    if @values[state.id]
      "<div class='label label-info' style='background-color: #{@values[state.id].color}'>#{state.text}</div>"
    else
      state.text

  @setupForEdit: (scope) ->
    return unless $(scope).length
    for name, info of adminium_column_options when info['is_enum']
      new EnumerateInput($("#{scope} select[id*=_#{name}]"))

$ ->
  EnumerateInput.setupForEdit('body.resources.edit')
