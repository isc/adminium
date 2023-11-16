const limit = 10000

class ImportManager {
  constructor() {
    if (!$('#import_file').length) return
    document
      .getElementById('import_file')
      .addEventListener('change', e => this.selectFiles(e.target.files), false)
    this.table = $('.items-list').data('table')
    $('#select-file .btn').on('click', () => $('#import_file').click())
    $('#perform-import').on('click', () => this.perform())
    $('.file-info a.change').click(() => this.disableImport())
    const body = document.body
    body.addEventListener('dragover', e => this.handleDragOver(e), false)
    body.addEventListener('drop', e => this.handleFileDrop(e), false)
  }

  handleDragOver(evt) {
    evt.stopPropagation()
    evt.preventDefault()
    evt.dataTransfer.dropEffect = 'copy'
  }

  handleFileDrop(evt) {
    evt.stopPropagation()
    evt.preventDefault()
    this.selectFiles(evt.dataTransfer.files)
  }

  selectFiles(files) {
    $('.importHelp').addClass('hidden')
    this.disableImport()
    const file = files[0]
    $('.file-info').removeClass('hidden')
    $('.file-info span.filename').html(
      `<b>${file.name}</b> <i>(${file.size} bytes)</i>`
    )
    const reader = new FileReader()
    reader.onload = e => this.readFile(e)
    this.processing('Loading file locally')
    reader.readAsText(file)
  }

  disableImport() {
    this.readyToImport = false
    $('.items-list thead tr, .items-list tbody').html('')
    this.toggleStartImport('select-file', 'Step 1 of 3')
    $('.file-info').addClass('hidden')
    $('.status').html('')
    $('.importable_rows').addClass('hidden')
    $('.importHeader').removeClass('panel-danger panel-success')
    return false
  }

  processing(msg) {
    this.toggleStartImport('processing', 'Processing, please wait...')
    $('#processing .help-block').html(msg)
  }

  toggleStartImport(name, title) {
    $('.importHeader .step').addClass('hidden')
    $(`#${name}`).removeClass('hidden')
    $('.importHeader .panel-title').text(title)
  }

  error(msg, details) {
    this.toggleStartImport('select-file', 'Step 1 of 3')
    $('.importHeader').toggleClass('panel-danger', true)
    details = details ? `(${details})` : ''
    $('.status')
      .html(`<i class='fa fa-ban text-danger' /> <b>${msg}</b> ${details}`)
      .removeClass('hidden')
  }

  readFile(evt) {
    this.processing('Parsing your file')
    try {
      this.rows = $.csv.toArrays(evt.target.result, {
        separator: this.detectSeparator(evt.target.result)
      })
    } catch (e) {
      return this.error(
        "We couldn't parse your file, be sure to provide a CSV file",
        e.message
      )
    }
    const header = this.rows.shift()
    this.sql_column_names = []
    $('.importable_rows').removeClass('hidden')
    $('.importable_rows span').text(`${this.rows.length} rows detected`)
    try {
      header.forEach(name => this.detectColumnName($.trim(name)))
    } catch (e) {
      return this.error('Column name resolution failed', e)
    }
    this.update_rows = []
    this.update_ids = []
    if (this.preview()) {
      this.prepareToImport()
      if (this.checkQuota()) this.checkExistenceOfUpdatingRecord()
    }
  }

  detectSeparator(text) {
    const seps = {}
    var min_pos = 100000
    var separator = ','
    ;[',', ';', '\t'].forEach(sep => {
      const pos = text.indexOf(sep)
      if (pos != -1 && min_pos > pos) {
        min_pos = pos
        separator = sep
      }
    })
    return separator
  }

  checkQuota() {
    if (this.rows.length > limit) {
      this.error(
        'Too many rows to import',
        `sorry but for now, you can only import ${limit} rows at a time`
      )
      return
    }
    return true
  }

  checkExistenceOfUpdatingRecord() {
    if (this.update_ids.length) {
      this.processing('Checking that every rows to update exist')
      $.ajax({
        type: 'POST',
        url: `/resources/${this.table}/check_existence`,
        data: { id: this.update_ids },
        success: data => this.checkExistenceCallback(data),
        error: data => this.errorCallback(data)
      })
    } else this.checkExistenceCallback()
  }

  checkExistenceCallback(data = {}) {
    if (data.error) {
      var sample = data.ids.slice(0, 6).join(', ')
      if (data.ids.length > 6) sample += '...'
      this.error(
        `${data.ids.length} rows that shall be updated were not found :`,
        sample
      )
    } else {
      if (data.update == false) {
        this.data.create = this.data.update
        this.data.update = []
        $('.importable_rows span').text(
          `${this.data.create.length} rows will be imported with the specified primary keys.`
        )
      }
      this.enableImport()
    }
  }

  prepareToImport() {
    this.data = { create: [], update: [], headers: this.sql_column_names }
    const pindex = this.sql_column_names.indexOf(primary_key)
    this.rows.forEach((row, index) => {
      const kind = this.update_rows.indexOf(index) !== -1 ? 'update' : 'create'
      if (kind == 'create' && pindex !== -1) row.splice(pindex, 1)
      if (pindex !== -1 && kind == 'update') this.update_ids.push(row[pindex])
      this.data[kind].push(row)
    })
    const text = []
    ;['create', 'update'].forEach(kind => {
      if (this.data[kind].length > 0)
        text.push(
          `${kind} ${this.data[kind].length} row${
            this.data[kind].length > 1 ? 's' : ''
          }`
        )
    })
    $('.importable_rows span').append(': will ' + text.join(' and '))
  }

  enableImport() {
    this.readyToImport = true
    $('#perform-import').val(`Import ${this.rows.length} rows`)
    this.toggleStartImport('start-import', 'Step 2 of 3')
    $('.status').html("<i class='fa fa-check text-success' /> Ready to import")
  }

  preview() {
    $('.items-list').addClass('hidden')
    $('<th>').appendTo($('.items-list thead tr'))
    this.sql_column_names.forEach(name =>
      $('<th>')
        .addClass('column_header')
        .text(name)
        .appendTo($('.items-list thead tr'))
    )
    for (var index = 0; index < this.rows.length; index++) {
      var row = this.rows[index]
      const tr = $('<tr>').appendTo($('.items-list tbody'))
      $("<td class='importIndex'>")
        .html(index + 1)
        .appendTo(tr)
      for (var i = 0; i < row.length; i++) {
        var cell = row[i]
        const column_name = this.sql_column_names[i]
        const type = columns_hash[column_name].type
        var css = type + ' '
        if (type == 'boolean' && cell !== '' && cell !== null) {
          var value = null
          if (
            [
              adminium_column_options[column_name].boolean_true,
              'true',
              'True',
              'TRUE',
              'yes',
              't',
              '1'
            ].indexOf(cell) !== -1
          )
            value = true
          if (
            [
              adminium_column_options[column_name].boolean_false,
              'false',
              'False',
              'FALSE',
              'no',
              'f',
              '0'
            ].indexOf(cell) !== -1
          )
            value = false
          if (value == null) {
            this.error(
              `Data integrity check: unknown value '${cell}' for boolean column ${column_name}`
            )
            return false
          } else {
            row[i] = value
            css += `${value}class`
          }
        }
        if (cell == '' || cell == null) {
          css += 'nilclass'
          if (['text', 'string'].indexOf(type) !== -1)
            cell = cell == null ? 'NULL' : 'empty string'
          else if (column_name !== primary_key) {
            cell = 'NULL'
            row[i] = null
          }
        }
        if (column_name == primary_key) {
          if (cell == '')
            cell =
              "<i class='fa fa-star' /><span class='label label-success'>new</span>"
          else this.update_rows.push(index)
        }
        $('<td>').addClass(css).html(cell).appendTo(tr)
      }
    }
    $('.items-list').removeClass('hidden')
    return true
  }

  detectColumnName(name) {
    if (adminium_column_options[name]) {
      this.sql_column_names.push(name)
      return
    } else {
      for (var key in adminium_column_options) {
        if (adminium_column_options[key].displayed_column_name == name) {
          this.sql_column_names.push(key)
          return
        }
      }
    }
    throw `unknown column name '${name}' for table ${this.table}`
  }

  perform() {
    if (!this.readyToImport) return alert('Sorry. Not ready to import')
    if (this.importing) return alert('Sorry. Already importing')
    this.importing = true
    this.processing('Importing your data')
    $.ajax({
      type: 'POST',
      url: `/resources/${this.table}/perform_import`,
      data: { data: JSON.stringify(this.data) },
      success: data => this.performCallback(data),
      error: data => this.errorCallback(data)
    })
  }

  performCallback(data) {
    this.importing = false
    if (data.error) this.error(data.error)
    else {
      $('.importHeader').removeClass('panel-danger').addClass('panel-success')
      $('.status').empty()
      this.toggleStartImport('import-success', 'Step 3 of 3')
    }
  }

  errorCallback(data) {
    this.importing = false
    this.error(
      'Sorry, but an unexpected error occurred, please contact us so we can work this out.'
    )
  }
}

$(() => {
  new ImportManager()
})
