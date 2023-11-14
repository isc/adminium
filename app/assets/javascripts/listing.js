const checkboxSelector = '.items-list tbody input[type=checkbox]'

class BulkActions {
  constructor() {
    this.setupBulkEdit()
    this.setupBulkDestroy()
    this.setupBulkCheckbox()
  }

  setupBulkEdit() {
    $('#bulk-edit-modal').on('hide', () =>
      $('#bulk-edit-modal').html($('.loading_modal').html())
    )
    $('.bulk-edit').on('click', () => {
      if ($('.bulk-edit').attr('disabled')) return false
      $('#bulk-edit-modal').html($('.loading_modal').html()).modal('show')
      const item_ids = $(`${checkboxSelector}:checked`)
        .map(
          (_, item) => `record_ids[]=${$(item).closest('tr').data('item-id')}`
        )
        .get()
      const path = $('#bulk-edit-modal').attr('data-remote-path')
      $.get(`${path}?${item_ids.join('&')}`, data => {
        $('#bulk-edit-modal').html(data)
        AutocompleteAssociationsForm.setup()
      })
      return false
    })
  }

  setupBulkDestroy() {
    $('.bulk-destroy').on('click', () => {
      if ($('.bulk-destroy').attr('disabled')) return false
      const items = $(`${checkboxSelector}:checked`)
      if (
        !confirm(
          `Are you sure you want to trash the ${items.length} selected items?`
        )
      )
        return false
      items.each((_, item) => {
        const item_id = $(item).closest('tr').data('item-id')
        $('<input>')
          .attr({ type: 'hidden', name: 'item_ids[]' })
          .val(item_id)
          .appendTo('#bulk-destroy-form')
      })

      $('#bulk-destroy-form').submit()
      return false
    })
  }

  setupBulkCheckbox() {
    $(checkboxSelector).click(() => this.formVisibility())
    $('.items-list thead input[type=checkbox]').click(e => {
      $(checkboxSelector).prop('checked', e.target.checked)
      this.formVisibility()
    })
  }

  formVisibility() {
    if ($(`${checkboxSelector}:checked`).length == 0)
      $('.bulk-destroy, .bulk-edit').attr('disabled', 'disabled')
    else $('.bulk-destroy, .bulk-edit').removeAttr('disabled')
    $('table.items-list input:checked').parents('tr').addClass('warning')
    $('table.items-list input:not(:checked)')
      .parents('tr')
      .removeClass('warning')
  }
}

class CustomColumns {
  constructor(root) {
    $(root)
      .find('select.select-custom-column')
      .on('change', event => this.columnSelected(event))
  }

  columnSelected(event) {
    const column = event.target.value
    const optgroup = $(event.target).find(':selected').closest('optgroup')
    const ul = optgroup
      .parents('.custom-column')
      .siblings('ul:not(.master_checkbox)')
    const assoc = optgroup.data('name')
    var value, text
    if (optgroup.data('kind') == 'belongs_to')
      [value, text] = [
        `${assoc}.${column}`,
        `${optgroup.attr('label')} > ${column}`
      ]
    else if (optgroup.data('kind') == 'has_many')
      [value, text] = [`has_many/${assoc}`, `${optgroup.attr('label')} count`]
    else value = text = column
    const label = $('<label>').text(` ${text}`)
    const input = $('<input>').attr({
      type: 'checkbox',
      checked: 'checked',
      name: `${ul.data('type')}_columns[]`,
      value: value
    })
    label.prepend(input)
    const icon = $('<i class="fa fa-arrows-v pull-right">')
    $('<li class="list-group-item">').append(label).append(icon).appendTo(ul)
  }
}

class ColumnSettings {
  constructor() {
    $('.column_settings').click(evt =>
      remoteModal('#column-settings', $(evt.currentTarget).data('path'), () => {
        $('#is_enum').click(evt => this.toggleEnumConfigurationPanel(evt))
        $('.template_line a').click(() => this.addNewEmptyLine())
      })
    )
  }

  toggleEnumConfigurationPanel(evt) {
    $('table.enum_details_area tbody tr:not(.template_line)').remove()
    if ($(evt.currentTarget)[0].checked) {
      $('.loading_enum')
        .removeClass('hidden')
        .parents('.modal-body')
        .scrollTop(1000)
      $.getJSON($(evt.currentTarget).data('values-url'), data => {
        $('.enum_details_area').removeClass('hidden')
        data.forEach(value => {
          $('.template_line input[type=text]').val(value)
          this.addNewEmptyLine()
        })
        $('.loading_enum')
          .addClass('hidden')
          .parents('.modal-body')
          .scrollTop(1000)
      })
    } else $('.enum_details_area').addClass('hidden')
  }

  nextDefaultColor() {
    const index = $('table.enum_details_area tr').length
    const colors = [
      '#2a8bcc',
      '#86b558',
      '#ffb650',
      '#d15b47',
      '#9585bf',
      '#a0a0a0',
      '#555555',
      '#d6487e',
      '#6fb3e0',
      '#892e65',
      '#2e8965',
      '#996666'
    ]
    return index > 1 && index < colors.length ? colors[index - 2] : '#0000FF'
  }

  addNewEmptyLine() {
    const line = $('.template_line').clone().removeClass('template_line')
    line.find('a').remove()
    $('.template_line').before(line)
    $('.template_line input').val('')
    line.find('input[type=color]').val(this.nextDefaultColor())
    const previousId = $('.template_line').data('line-identifer')
    const newId = parseInt(previousId) + 1
    $('.template_line').data('line-identifer', newId)
    $('.template_line input').each(function () {
      $(this).attr('name', $(this).attr('name').replace(previousId, newId))
    })
    $('.template_line input').eq(1).focus()
  }
}

class ClickToCopyFixnums {
  constructor() {
    const selector = 'td.column.integer:not([data-editable])'
    $(selector).each(function () {
      $(this).attr({
        'data-clipboard-text': this.innerText.replace(/,/g, ''),
        title: 'Click to copy'
      })
    })
    new Clipboard(selector).on('success', function (e) {
      $(e.trigger)
        .attr({ title: 'Copied!' })
        .tooltip({ trigger: 'manual', container: 'body' })
        .on('shown.bs.tooltip', function () {
          setTimeout(
            () => $(this).attr({ title: 'Click to copy' }).tooltip('destroy'),
            1000
          )
        })
        .tooltip('show')
    })
  }
}

$(() => {
  new BulkActions()
  new CustomColumns('#displayed-columns_pane')
  new CustomColumns('#select-exported-fields_pane')
  new ColumnSettings()
  new ClickToCopyFixnums()
})
