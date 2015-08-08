class window.ImportManager

  limit: 1500

  constructor: ->
    return unless $('#import_file').length
    window.importManager = this
    document.getElementById('import_file').addEventListener('change', @handleFileSelect, false)
    @table = $(".items-list").data("table")
    $("#select-file .btn").on 'click', ->
      $("#import_file").click()
    $("#perform-import").on 'click', @perform
    $(".file-info a.change").click @disableImport
    dropZone = $('body')[0]
    dropZone.addEventListener 'dragover', @handleDragOver, false
    dropZone.addEventListener 'drop', @handleFileDrop, false
    $('.importHeader').jscrollspy
        min: $('.importHeader .btn').offset().top,
        max: -> $(document).height(),
        onEnter: (element, position) ->
          $(".importHeader").addClass('subnav-fixed')
        ,
        onLeave: (element, position) ->
          $(".importHeader").removeClass('subnav-fixed')
    if !$.isFunction(FileReader)
      @error("html5-incompatibility", "Your browser is missing some HTML5 support required for this import feature (FileReader is not defined)")

  handleDragOver: (evt) ->
    evt.stopPropagation()
    evt.preventDefault()
    evt.dataTransfer.dropEffect = 'copy'

  handleFileDrop: (evt) =>
    evt.stopPropagation()
    evt.preventDefault()
    @selectFiles evt.dataTransfer.files

  handleFileSelect: (evt) =>
    @selectFiles evt.target.files

  selectFiles: (files) =>
    $('.importHelp').hide()
    @disableImport()
    file = files[0]
    $(".file-info").show()
    $(".file-info span.filename").html("<b>#{file.name}</b> <i>(#{file.size} bytes)</i>")
    reader = new FileReader()
    reader.onload = @readFile
    @processing('loading file locally')
    Analytics.importEvent('loading-file')
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
    $("#processing .hint").html(msg)

  toggleStartImport: (name) ->
    $(".importHeader .span3").hide()
    $("##{name}").show()

  error: (tracker_code, msg, details) =>
    @toggleStartImport('select-file')
    $(".importHeader").toggleClass("fail", true)
    details = if details then "(#{details})" else ""
    $(".status").html("<i class='fa fa-ban' /> <b>#{msg}</b> #{details}").show()
    Analytics.importEvent 'error', tracker_code

  notice: (msg) =>
    $('.status').html(msg)

  readFile: (evt) =>
    @processing('parsing your file')
    try
      @detectSeparator(evt.target.result)
      @rows = $.csv.toArrays evt.target.result, {separator: @separator}
    catch e
      return @error("parsing", "We couldn't parse your file, be sure to provide a CSV file", e.message)
    header = @rows.shift()
    @sql_column_names = []
    $(".importable_rows").show()
    $(".importable_rows span").text("#{@rows.length} rows detected")
    try
      @detectColumnName $.trim(name) for name in header
    catch e
      return @error("column_name_resolution", 'column name resolution failed', e)
    @update_rows = []
    @update_ids = []
    @preview()
    @prepareToImport()
    @checkExistenceOfUpdatingRecord() if @checkQuota()
  
  detectSeparator: (text) =>
    seps = {}
    min_pos = 100000
    @separator = ','
    for sep in [',', ';', '\t']
      pos = text.indexOf(sep)
      if pos != -1 && min_pos > pos
        min_pos = pos
        @separator = sep

  checkQuota: =>
    if @rows.length > @limit
      @error("quotas_excedeed", "Too many rows to import", "sorry but for now, you can only import #{@limit} rows at a time")
      return
    true

  checkExistenceOfUpdatingRecord: =>
    if @update_ids.length > 0
      @processing "Checking that every rows to update exist"
      $.ajax
        type: 'POST',
        url: "/resources/#{@table}/check_existence"
        data: {id: @update_ids}
        success: @checkExistenceCallback
        error: @errorCallback
    else
      @checkExistenceCallback()

  checkExistenceCallback: (data={}) =>
    if data.error
      sample = data.ids.slice(0, 6).join(", ")
      sample += "..." if data.ids.length > 6
      @error("update_not_found_ids", "#{data.ids.length} rows that shall be updated were not found :", sample)
    else
      if data.update is false
        @data.create = @data.update
        @data.update = []
        $(".importable_rows span").text("#{@data.create.length} rows will be imported with the specified primary keys.")
      @enableImport()

  prepareToImport: =>
    @data = {create: [], update: [], headers: @sql_column_names}
    pindex = @sql_column_names.indexOf(primary_key)
    for row, index in @rows
      kind = if (@update_rows.indexOf(index) isnt -1) then 'update' else 'create'
      row.splice(pindex, 1) if kind is 'create' && pindex isnt -1
      @update_ids.push row[pindex] if pindex isnt -1 && kind is 'update'
      @data[kind].push row
    text = []
    for kind in ['create', 'update']
      text.push "#{kind} #{@data[kind].length} row#{if @data[kind].length > 1 then 's' else ''}" if @data[kind].length > 0
    $(".importable_rows span").append(": will " + text.join(' and '))

  enableImport: =>
    @readyToImport = true
    $("#perform-import").val("Import #{@rows.length} rows")
    @toggleStartImport('start-import')
    $(".status").html("<i class='fa fa-check' /> Ready to import")

  preview: ->
    $(".items-list").hide()
    $("<th>").appendTo($(".items-list thead tr"))
    for name in @sql_column_names
      $("<th>").addClass('column_header').text(name).appendTo($(".items-list thead tr"))
    for row, index in @rows
      tr = $("<tr>").appendTo($(".items-list tbody"))
      $("<td class='importIndex'>").html("#{index+1}").appendTo(tr)
      for cell, i in row
        column_name = @sql_column_names[i]
        type = columns_hash[column_name].type
        css = type + ' '
        if type is 'boolean' and cell isnt '' and cell isnt null
          value = null
          value = true if [adminium_column_options[column_name].boolean_true, 'true', 'True', 'TRUE', 'yes', 't', '1'].indexOf(cell) isnt -1
          value = false if [adminium_column_options[column_name].boolean_false, 'false', 'False', 'FALSE', 'no', 'f', '0'].indexOf(cell) isnt -1
          if value is null
            error("Data integrity check: unknown value '#{cell}' for boolean column #{column_name}")
            return
          else
            row[i] = value
            css += "#{value}class"
        if cell is '' or cell is null
          css += "nilclass"
          if ['text', 'string'].indexOf(type) isnt -1
            cell = if cell is null then 'NULL' else 'empty string'
          else
            if column_name isnt primary_key
              cell = 'NULL'
              row[i] = null
        if column_name is primary_key
          if cell is ''
            cell = "<i class='fa fa-star' /><span class='label label-success'>new</span>"
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
        if data.displayed_column_name is name
          @sql_column_names.push key
          return
    throw("unknown column name '#{name}' for table #{@table}")

  perform: =>
    return alert('Sorry. Not ready to import') unless @readyToImport
    return alert('Sorry. Already importing') if @importing
    @importing = true
    @processing 'Importing your data'
    Analytics.importEvent('importing', "insert=#{@data.create.length} update=#{@data.update.length}")
    @import_started_at = new Date()
    $.ajax
      type: 'POST',
      url: "/resources/#{@table}/perform_import"
      data: {data: JSON.stringify(@data)}
      success: @performCallback
      error: @errorCallback

  performCallback: (data) =>
    @importing = false
    if data.error
      @error('server-side-detected-error', data.error)
    else
      @success()
      delay = Math.round((new Date() - @import_started_at) / 100) / 10
      Analytics.importEvent('imported', "insert=#{@data.create.length} update=#{@data.update.length} time=#{delay} account=#{adminium_account.name} plan=#{adminium_account.plan}")

  success: =>
    $(".importHeader").removeClass("fail").addClass('success')
    $(".status").empty()
    @toggleStartImport 'import-success'

  errorCallback: (data) =>
    @importing = false
    @error('internal-server-side-error', 'Sorry, but an unexpected error occurred, please contact us so we can work this out.')

$ ->
  new ImportManager()
