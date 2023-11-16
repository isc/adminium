class Navigation {
  constructor() {
    this.helpShown = false
    this.itemList()
    this.tableSelection()
    this.searchBar()
  }

  tableSelection() {
    this.selector = '#table_select'
    $(this.selector)
      .select2({ placeholder: 'Jump to table (s to focus)' })
      .removeClass('hidden')
      .on('change', event => {
        $(this.selector)
          .select2('destroy')
          .closest('form')
          .replaceWith('<div class="navbar-text">Loading...</div>')
        window.location.href = `/resources/${event.target.value}`
      })
    $('.modal').on('hide', () => $(this).find('input:focus').blur())
    $(document).keypress(e => {
      if ($(e.target).is(':input')) return
      // 's' key
      if (e.which === 115) {
        $(this.selector).select2('open')
        e.preventDefault()
      }
      const actionMap = { create: 99, destroy: 116, edit: 101 }
      Object.keys(actionMap).forEach(action => {
        if (e.which === actionMap[action] && $(`a.btn.${action}-action`).length)
          $(`a.btn.${action}-action`).get(0).click()
      })
      // '?' for help
      if (e.which === 63) this.toggleKeyboardShortcutsHelp()
    })
  }

  searchBar() {
    $(document).keypress(e => {
      if ($(e.target).is(':input')) return
      if (e.which != 47) return
      $('form.navbar-form input[type=text]').focus()
      e.preventDefault()
    })
  }

  toggleKeyboardShortcutsHelp() {
    const selector = '#keyboard-shortcuts-help'
    if (this.helpShown) {
      $(selector).modal('hide')
      this.helpShown = false
    } else {
      if ($(selector).length) $(selector).modal('show')
      else {
        $('<div>')
          .attr({ id: selector.replace('#', ''), tabindex: '-1' })
          .addClass('modal fade')
          .appendTo('body')
          .html($('.loading_modal').html())
          .modal('show')
        $.get('/docs/keyboard_shortcuts', data => $(selector).html(data))
        $(selector).on('hidden', () => (this.helpShown = false))
        this.helpShown = true
      }
    }
  }

  itemList() {
    $(document).keydown(e => {
      if ($(e.target).is(':input') || $('.items-list').length == 0) return
      const row = $('.items-list tr.success')
      if (row.length == 0) {
        if ([74, 40].indexOf(e.which) != -1) {
          $('.items-list tbody tr').first().addClass('success')
          e.preventDefault()
        }
        return
      }
      // j or down arrow
      if ([74, 40].indexOf(e.which) != -1) {
        if (row.next().length)
          row.removeClass('success').next().addClass('success')
      }
      // k or up arrow
      else if ([75, 38].indexOf(e.which) != -1) {
        if (row.prev().length)
          row.removeClass('success').prev().addClass('success')
      }
      // return or right arrow or o
      else if ([13, 39, 79].indexOf(e.which) != -1)
        location.href = row.find('td:first-child a:first-child').attr('href')
      // x
      else if (e.which == 88)
        row.find('td:eq(0) input[type=checkbox]').get(0).click()
      // t
      else if (e.which == 84)
        row.find('td:first-child a[data-method="delete"]').trigger('click')
      // e
      else if (e.which == 69)
        location.href = row.find('td:first-child a:eq(1)').attr('href')
      else return
      e.preventDefault()
    })
  }
}

$(() => new Navigation())
