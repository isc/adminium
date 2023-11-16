class AutocompleteAssociationsForm {
  constructor(search_input) {
    if (search_input.data('autocomplete-association') === 'done') return
    const control = search_input.closest('.adminium-association')
    this.hidden_input = control.find('input[type=hidden]')
    this.single_record_area = control.find('.single-record')
    this.single_record_value = control.find('.single-record input')
    this.selected_records_area = control.find('.multiple-records')
    this.spinner = control.find('.fa-refresh')
    this.list = control.find('ul.list-unstyled')
    search_input.on('keyup', e => this.keyUp(e))
    this.single_record_area
      .find('a.clear-selection')
      .on('click', () => this.clearSelected())
    this.url = search_input.data('autocomplete-url')
    this.current_requests = 0
    search_input.data('autocomplete-association', 'done')
  }

  clearSelected() {
    this.single_record_area.find('.input-group-addon i').addClass('invisible')
    this.single_record_value.val('null')
    this.hidden_input.val('')
    return false
  }

  keyUp(evt) {
    const value = $(evt.currentTarget).val()
    if (this.query === value.toLowerCase()) return
    this.query = value.toLowerCase()
    clearTimeout(this.timeoutId)
    this.timeoutId = setTimeout(() => this.search(), 300)
  }

  displaySearchResults(data) {
    this.list.html('')
    data.results.forEach(record => {
      var text = record.adminium_label.toString().toLowerCase()
      if (text.indexOf(this.query) !== -1)
        text = text.replace(
          this.query,
          `<span class='bg-success'>${this.query}</span>`
        )
      else {
        const attrs = Object.keys(record)
          .filter(
            key =>
              record[key] &&
              record[key].toString().toLowerCase().indexOf(this.query) !== -1
          )
          .map(
            key =>
              `<i class='text-muted'>${key}=</i>${record[key]
                .toString()
                .toLowerCase()
                .replace(
                  this.query,
                  `<span class='bg-success'>${this.query}</span>`
                )}`
          )
        if (attrs.length > 0) text += ` <span>${attrs.join(' ')}</span>`
      }
      const li = $('<li>')
        .html(text)
        .data('label', record.adminium_label)
        .data('record_pk', record[data.primary_key])
        .appendTo(this.list)
      li.on('click', e => this.selectRecord(e))
    })
  }

  search() {
    if (!this.query.length) return this.list.html('')
    this.current_requests += 1
    this.spinner.removeClass('invisible')
    $.ajax({
      url: `${this.url}&search=${this.query}`,
      complete: () => {
        this.current_requests -= 1
        if (this.current_requests < 0) this.current_requests = 0
        this.spinner.toggleClass('invisible', this.current_requests === 0)
      },
      success: data => this.displaySearchResults(data)
    })
  }

  selectRecord(evt) {
    const li = $(evt.currentTarget)
    if (this.single_record_area.length) {
      this.hidden_input.val(li.data('record_pk'))
      this.single_record_value.val(li.data('label'))
      this.single_record_area
        .find('.input-group-addon i')
        .removeClass('invisible')
    } else {
      const label = $('<label>')
      const input = $('<input type="checkbox" checked="checked">')
        .attr({ name: this.selected_records_area.data('input-name') })
        .val(li.data('record_pk'))
        .appendTo(label)
      label.append(` ${li.data('label')}`)
      $('<li>').append(label).appendTo(this.selected_records_area)
    }
    li.siblings('.bg-info').removeClass('bg-info')
    li.addClass('bg-info')
  }
}

AutocompleteAssociationsForm.setup = () => {
  $('input[data-autocomplete-url]').each(
    (_, input) => new AutocompleteAssociationsForm($(input))
  )
}

AutocompleteAssociationsForm.setup()
