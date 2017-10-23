class @EnumerateInput

  constructor: (input, action) ->
    return unless input[0]
    column = input[0].name.match(/\[(.*)\]/)[1]
    @values = adminium_column_options[column].values
    input.select2(templateResult: @format)
    input.select2(action) if action
    input

  format: (state) =>
    if @values[state.id]
      $('<div>').addClass('label label-info').css('background-color', @values[state.id].color).text(state.text)
    else
      state.text

  @setupForEdit: (scope) ->
    return unless $(scope).length
    for name, info of adminium_column_options when info['is_enum']
      new EnumerateInput($("#{scope} select[id*=_#{name}]"))

$ -> EnumerateInput.setupForEdit('body.resources.edit')
