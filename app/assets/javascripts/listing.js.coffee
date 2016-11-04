class BulkActions
  checkbox_selector: '.items-list tbody input[type=checkbox]'

  constructor: ->
    @setupBulkEdit()
    @setupBulkDestroy()
    @setupBulkCheckbox()

  setupBulkEdit: ->
    $("#bulk-edit-modal").on 'hide', =>
      $("#bulk-edit-modal").html($(".loading_modal").html())
    $('.bulk-edit').on 'click', =>
      return false if $('.bulk-edit').attr('disabled')
      $("#bulk-edit-modal").html($(".loading_modal").html()).modal('show')
      item_ids = ("record_ids[]=#{$(item).closest('tr').data('item-id')}" for item in $("#{@checkbox_selector}:checked"))
      path = $("#bulk-edit-modal").attr("data-remote-path")
      $.get "#{path}?#{item_ids.join('&')}", (data) =>
        $('#bulk-edit-modal').html(data)
        AutocompleteAssociationsForm.setup()
        initDatepickers()
      false

  setupBulkDestroy: ->
    $('.bulk-destroy').on 'click', =>
      items = $("#{@checkbox_selector}:checked")
      return false unless confirm "Are you sure you want to trash the #{items.length} selected items ?"
      for item in items
        item_id = $(item).closest('tr').data('item-id')
        $('<input>').attr('type': 'hidden', 'name': 'item_ids[]').val(item_id).appendTo('#bulk-destroy-form')
      $('#bulk-destroy-form').submit()
      false

  setupBulkCheckbox: ->
    $(@checkbox_selector).click => @formVisibility()
    $('.items-list thead input[type=checkbox]').click (e) =>
      $(@checkbox_selector).prop('checked', e.target.checked)
      @formVisibility()

  formVisibility: ->
    if $("#{@checkbox_selector}:checked").length is 0
      $('.bulk-destroy, .bulk-edit').attr('disabled', 'disabled')
    else
      $('.bulk-destroy, .bulk-edit').removeAttr('disabled')
    $("table.items-list input:checked").parents('tr').addClass('warning')
    $("table.items-list input:not(:checked)").parents("tr").removeClass('warning')

class CustomColumns

  constructor: (root) ->
    @columnSelect = $(root).find('select.select-custom-column')
    @columnSelect.select2({placeholder: 'Select a column', matcher: adminiumSelect2Matcher}).on 'change', @columnSelected
  
  columnSelected: (object) =>
    column = object.val
    optgroup = $(object.added.element).closest('optgroup')
    ul = optgroup.parents('.custom-column').siblings('ul:not(.master_checkbox)')
    kind = optgroup.data('kind')
    assoc = optgroup.data('name')
    switch kind
      when 'belongs_to'
        value = "#{assoc}.#{column}"
        text = "#{assoc}'s #{column}"
      when 'has_many'
        value = "has_many/#{assoc}"
        text = "#{optgroup.attr('label')} count"
      else
        value = text = column
    label = $('<label>').text(" #{text}")
    input = $('<input>').attr('type': 'checkbox', 'checked': 'checked', 'name':"#{ul.data('type')}_columns[]", 'value':value)
    label.prepend(input)
    icon = $('<i class="fa fa-arrows-v pull-right">')
    $('<li class="list-group-item">').append(label).append(icon).appendTo ul

class ColumnSettings

  constructor: ->
    $('.column_settings').click (evt) =>
      [@column_name, table, view] = if (header = $(evt.currentTarget).closest('.column_header')).length
        [header.data('column-name'), header.data('table-name'), 'listing']
      else
        [$(evt.currentTarget).closest('th').attr('title'), $('.item-attributes').data('table'), 'show']
      remoteModal '#column-settings', {column: @column_name, table: table, view: view}, @setupEnumConfigurationPanel

  setupEnumConfigurationPanel: =>
    $("#is_enum").click @toggleEnumConfigurationPanel
    $('.template_line a').click @addNewEmptyLine

  toggleEnumConfigurationPanel: (evt) =>
    checked = $(evt.currentTarget)[0].checked
    $("table.enum_details_area tbody tr:not(.template_line)").remove()
    if checked
      $('.loading_enum').removeClass('hidden').parents(".modal-body").scrollTop(1000)
      $.getJSON $(evt.currentTarget).data('values-url'), column_name: @column_name, (data) =>
        $('.enum_details_area').removeClass('hidden')
        for value in data
          $('.template_line input[type=text]').val(value)
          @addNewEmptyLine()
        $('.loading_enum').addClass('hidden').parents(".modal-body").scrollTop(1000)
    else
      $('.enum_details_area').addClass('hidden')

  nextDefaultColor: =>
    index = $("table.enum_details_area tr").length
    colors = ['#2a8bcc', '#86b558', '#ffb650', '#d15b47', '#9585bf', '#a0a0a0', '#555555', '#d6487e', '#6fb3e0', '#892e65', '#2e8965', '#996666']
    if index > 1 && (index) < colors.length
      colors[index - 2]
    else
      '#0000FF'

  addNewEmptyLine: =>
    line = $('.template_line').clone().removeClass('template_line')
    line.find('a').remove()
    $('.template_line').before(line)
    $('.template_line input').val('')
    line.find('input[type=color]').val(@nextDefaultColor())
    previous_id = $('.template_line').data('line-identifer')
    new_id = parseInt(previous_id) + 1
    $('.template_line').data('line-identifer', new_id)
    for input in $('.template_line input')
      $(input).attr('name', $(input).attr('name').replace(previous_id, new_id))
    $('.template_line input').eq(1).focus()

class ClickToCopyFixnums
  constructor: ->
    selector = 'td.column.fixnum:not([data-editable])'
    $(selector).each ->
      $(@).attr('data-clipboard-text': @innerText.replace(/,/g, ''), title: 'Click to copy')
    new Clipboard(selector).on 'success', (e) ->
      $(e.trigger).attr(title: 'Copied!').tooltip(trigger: 'manual', container: 'body')
        .on('shown.bs.tooltip', -> setTimeout (=> $(@).attr(title: 'Click to copy').tooltip('destroy')), 1000)
        .tooltip('show')

$ ->
  new BulkActions()
  new CustomColumns('#displayed-columns_pane')
  new CustomColumns('#select-exported-fields_pane')
  new ColumnSettings()
  new ClickToCopyFixnums()