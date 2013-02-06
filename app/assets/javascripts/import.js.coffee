class window.ImportManager

  constructor: ->
    return unless document.getElementById('import_file')
    window.importManager = this
    document.getElementById('import_file').addEventListener('change', @handleFileSelect, false);
    @table = $(".items-list").data("table")
    $("#select-file .btn").on 'click', ->
      $("#import_file").click()
    $("#perform-import").on 'click', @perform
    dropZone = document.getElementById('select-file');
    dropZone.addEventListener 'dragover', @handleDragOver, false
    dropZone.addEventListener 'drop', @handleFileDrop, false

  handleDragOver: (evt) ->
    evt.stopPropagation();
    evt.preventDefault();
    evt.dataTransfer.dropEffect = 'copy'

  handleFileDrop: (evt) =>
    evt.stopPropagation();
    evt.preventDefault();
    @selectFiles evt.dataTransfer.files

  handleFileSelect: (evt) =>
    @selectFiles evt.target.files

  selectFiles: (files) =>
    @disableImport()
    file = files[0]
    $(".file-info").show()
    $(".file-info span").html("<b>#{file.name}</b> <i>(#{file.size} bytes)</i> last modified date on #{file.lastModifiedDate}")
    reader = new FileReader()
    reader.onload = @readFile
    reader.readAsText(file)

  disableImport: =>
    @readyToImport = false
    $(".items-list thead tr, .items-list tbody").html('')
    $("#perform-import").hide()
    $(".file-info").hide()
    $(".importable_rows").hide()
    $(".file-description").removeClass('alert-info alert-danger')

  error: (msg, details) =>
    $(".file-description").removeClass("alert-info").addClass("alert-danger")
    details = if details then "(#{details})" else ""
    $(".status").html("<i class='icon icon-ban-circle' /><b>#{msg}</b> #{details}")

  readFile: (evt) =>
    try
      @rows = $.csv.toArrays(evt.target.result);
    catch e
      @error("We couldn't parse your File, be sure to provide a CSV File", e.message)
      return
    header = @rows.shift()
    @sql_column_names = []
    $(".importable_rows").show()
    $(".importable_rows span").text(@rows.length)
    try
      for name in header
        @detectColumnName(name)
    catch e
      @error('column name resolution failed', e)
      return
    @preview()
    @enableImport()

  enableImport: =>
    @readyToImport = true
    $("#perform-import").val("Import #{@rows.length} rows into #{@table}").show()
    $(".file-description").addClass('alert-info')
    $(".status").html("<i class='icon  icon-ok-sign' /> <u>ready to import</u>. Review this list and validate at the end of the page")

  preview: () ->
    $(".items-list").hide()
    $("<th>").appendTo($(".items-list thead tr"))
    for name in @sql_column_names
      $("<th>").addClass('column_header').text(name).appendTo($(".items-list thead tr"))
    for row, index in @rows
      tr = $("<tr>").appendTo($(".items-list tbody"))
      $("<td class='importIndex'>").text("#{index+1}").appendTo(tr)
      for cell, i in row
        column_name = @sql_column_names[i]
        sql_type = columns_hash[column_name].sql_type
        css = sql_type + ' '
        if sql_type == 'boolean' && cell != '' && cell != null
          value = null
          value = true if [adminium_column_options[column_name].boolean_true, 'true', 'True', 'TRUE', 'yes', 't', '1'].indexOf(cell) isnt -1
          value = false if [adminium_column_options[column_name].boolean_false, 'false', 'False', 'FALSE', 'no', 'f', '0'].indexOf(cell) isnt -1
          if value is null
            error("data integrity check: unknown value '#{cell}' for boolean column #{column_name}")
            return
          else
            row[i] = value
            css += "#{value}class"
        if cell == '' || cell == null
          css += "nilclass"
          cell = if cell == null then 'NULL' else 'empty string'
        $('<td>').addClass(css).text(cell).appendTo(tr)
    $(".items-list").show()

  detectColumnName: (name) =>
    if adminium_column_options[name]
      @sql_column_names.push name
      return
    else
      for key, data of adminium_column_options
        if data.displayed_column_name == name
          @sql_column_names.push key
          return
    throw("unknown column name '#{name}' for table #{@table}")

  perform: =>
    if !@readyToImport
      alert('sorry. not ready to import')
      return
    if @importing
      alert('sorry. already importing')
      return
    @importing = true
    $('#perform-import').hide()
    $.ajax
      type: 'POST',
      url: "/resources/#{@table}/perform_import"
      data: {headers:@sql_column_names, rows:@rows}
      success: @performCallback
      error: @errorCallback
    window.location.href ="#"
    $(".status").html('<div class="progress progress-striped active"><div class="bar" style="width: 100%;"></div></div>importing rows')

  performCallback: (data) =>
    @importing = false
    if data.error
      @error(data.error)
    else
      @success()

  success: =>
    $(".file-description").removeClass("alert-info").addClass('alert-success')
    $(".status").html("your data has been imported, <a>click here to see it</a>")
    $(".status a").attr('href', $("#select-file").data('import-result-path'))


  errorCallback: (data) =>
    @importing = false
    @error('sorry, but an unexpected error occured, please contact us so we can work this out.')

$ ->
  new ImportManager()