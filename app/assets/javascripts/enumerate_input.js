class EnumerateInput {
  constructor(input, action) {
    if (!input[0]) return
    const column = input[0].name.match(/\[(.*)\]/)[1]
    this.values = adminium_column_options[column].values
    input.select2({ templateResult: (state) => { return this.format(state) } })
    if (action) input.select2(action)
  }

  format(state){
    if (this.values[state.id])
      return $('<div>').addClass('label label-info').css('background-color', this.values[state.id].color).text(state.text)
    else
      return state.text
  }
}

$(() => {
  const editForm = $('body.resources.edit form')
  if (!editForm.length) return
  Object.keys(adminium_column_options).filter((key) => adminium_column_options[key].is_enum).forEach((key) => {
    const field = editForm.find(`select[id*=_${key}]`)
    new EnumerateInput(field)
  })
})
