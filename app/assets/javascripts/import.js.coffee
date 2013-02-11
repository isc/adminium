class window.ImportManager

  constructor: ->
    return unless document.getElementById('import_file')
    window.importManager = this
    document.getElementById('import_file').addEventListener('change', @handleFileSelect, false);
    @table = $(".items-list").data("table")
    $("#select-file .btn").on 'click', ->
      $("#import_file").click()
    $("#perform-import").on 'click', @perform
    $(".file-info a.change").click @disableImport
    dropZone = $('body')[0];
    dropZone.addEventListener 'dragover', @handleDragOver, false
    dropZone.addEventListener 'drop', @handleFileDrop, false
    $('.importHeader').jscrollspy
        min: $('.importHeader .btn').offset().top,
        max: () -> $(document).height(),
        onEnter: (element, position) ->
          $(".importHeader").addClass('subnav-fixed')
        ,
        onLeave: (element, position) ->
          $(".importHeader").removeClass('subnav-fixed')
    if !$.isFunction(FileReader)
      @error("Your browser is missing some HTML5 support required for this import feature (FileReader is not defined)")

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
    $(".file-info span.filename").html("<b>#{file.name}</b> <i>(#{file.size} bytes)</i>")
    reader = new FileReader()
    reader.onload = @readFile
    @processing('loading file locally')
    reader.readAsText(file)

  disableImport: =>
    @readyToImport = false
    $(".items-list thead tr, .items-list tbody").html('')
    @toggleStartImport('select-file')
    $(".file-info").hide()
    @notice ''
    $(".importable_rows").hide()
    $(".importHeader").removeClass("fail success")

  processing: (msg) =>
    @toggleStartImport('processing')
    $(".hint").html(msg)

  toggleStartImport: (name) ->
    $(".importHeader .span3").hide()
    $("##{name}").show()

  error: (msg, details) =>
    @toggleStartImport('select-file')
    $(".importHeader").toggleClass("fail", true)
    details = if details then "(#{details})" else ""
    $(".status").html("<i class='icon icon-ban-circle' /><b>#{msg}</b> #{details}").show()

  notice: (msg) =>
    $('.status').html(msg)

  readFile: (evt) =>
    @processing('parsing your file')
    try
      @rows = $.csv.toArrays(evt.target.result);
    catch e
      @error("We couldn't parse your File, be sure to provide a CSV File", e.message)
      return
    header = @rows.shift()
    @sql_column_names = []
    $(".importable_rows").show()
    $(".importable_rows span").text("#{@rows.length} rows detected")
    try
      for name in header
        @detectColumnName(name)
    catch e
      @error('column name resolution failed', e)
      return
    @update_rows = []
    @update_ids = []
    @preview()
    @prepareToImport()
    @checkExistenceOfUpdatingRecord()

  checkExistenceOfUpdatingRecord: =>
    if @update_ids.length > 0
      @processing "checking that every rows to update exists"
      $.ajax
        type: 'GET',
        url: "/resources/#{@table}/check_existence"
        data: {id: @update_ids}
        success: @checkExistenceCallback
        error: @errorCallback
    else
      @checkExistenceCallback()

  checkExistenceCallback: (data={}) =>
    if (data.error)
      sample = data.ids.slice(0, 6).join(", ")
      sample += "..." if data.ids.length > 6
      @error("#{data.ids.length} rows that shall be update were not found :", sample)
    else
      @enableImport()

  prepareToImport: =>
    @data =
      create: []
      update: []
      headers: @sql_column_names
    pindex = @sql_column_names.indexOf(primary_key)
    for row, index in @rows
      kind = if (@update_rows.indexOf(index) isnt -1) then 'update' else 'create'
      row.splice(pindex, 1) if kind == 'create' && pindex isnt -1
      @update_ids.push row[pindex] if pindex isnt -1 && kind is 'update'
      @data[kind].push row
    text = []
    for kind in ['create', 'update']
      text.push "#{kind} #{@data[kind].length} row#{if @data[kind].length > 1 then 's' else ''}" if @data[kind].length > 0
    $(".importable_rows span").append(": will " + text.join(' and '))

  enableImport: =>
    @readyToImport = true
    $("#perform-import").val("Import #{@rows.length} rows into #{@table}")
    @toggleStartImport('start-import')
    $(".status").html("<i class='icon  icon-ok-sign' /> ready to import")

  preview: () ->
    $(".items-list").hide()
    $("<th>").appendTo($(".items-list thead tr"))
    for name in @sql_column_names
      $("<th>").addClass('column_header').text(name).appendTo($(".items-list thead tr"))
    for row, index in @rows
      tr = $("<tr>").appendTo($(".items-list tbody"))
      $("<td class='importIndex'>").html("#{index+1}").appendTo(tr)
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
          if sql_type == 'character varying(255)'
            cell = if cell == null then 'NULL' else 'empty string'
        if (column_name == primary_key)
          if cell == ''
            cell = "<i class='icon-star' /><span class='label label-success'>new</span>"
          else
            @update_rows.push(index)
        $('<td>').addClass(css).html(cell).appendTo(tr)
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
    @processing('importing your data')
    $.ajax
      type: 'POST',
      url: "/resources/#{@table}/perform_import"
      data: @data
      success: @performCallback
      error: @errorCallback

  performCallback: (data) =>
    @importing = false
    if data.error
      @error(data.error)
    else
      @success()

  success: =>
    $(".importHeader").removeClass("fail").addClass('success')
    $(".status").html("")
    @toggleStartImport 'import-success'

  errorCallback: (data) =>
    @importing = false
    @error('sorry, but an unexpected error occured, please contact us so we can work this out.')

$ ->
  new ImportManager()