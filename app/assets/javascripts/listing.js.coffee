class BulkActions
  checkbox_selector: '.items-list tbody input[type=checkbox]'

  constructor: ->
    @setupBulkEdit()
    @setupBulkDestroy()
    @setupBulkCheckbox()

  setupBulkEdit: ->
    $("#bulk-edit-modal").on 'hide', =>
      $("#bulk-edit-modal").html($(".loading_modal").html())
    $("#bulk-edit-modal").on 'shown', =>
      $("#bulk-edit-modal").html($(".loading_modal").html())
      item_ids = ""
      for item in $("#{@checkbox_selector}:checked")
        item_ids += "record_ids[]=#{$(item).closest('tr').data('item-id')}&"
      path = $("#bulk-edit-modal").attr("data-remote-path")
      $.get "#{path}?#{item_ids}", (data) =>
        $("#bulk-edit-modal").html(data)
        AutocompleteAssociationsForm.setup()
        $('.datepicker').datepicker onClose: (dateText, inst) ->
          $("##{inst.id}_1i").val(inst.selectedYear)
          $("##{inst.id}_2i").val(inst.selectedMonth + 1)
          $("##{inst.id}_3i").val(inst.selectedDay)

  setupBulkDestroy: ->
    $('.bulk-destroy').submit =>
      items = $("#{@checkbox_selector}:checked")
      return false unless confirm "Are you sure you want to trash the #{items.length} selected items ?"
      for item in items
        item_id = $(item).closest('tr').data('item-id')
        $('<input>').attr('type': 'hidden', 'name': 'item_ids[]').val(item_id).appendTo('.bulk-destroy')

  setupBulkCheckbox: ->
    $(@checkbox_selector).click => @formVisibility()
    $('.click_checkbox').click (e) =>
      $(e.target).find("input[type=checkbox]").click()
      e.stopPropagation()
      @formVisibility()
    $('.items-list thead input[type=checkbox]').click (e) =>
      if e.target.checked
        $(@checkbox_selector).attr('checked', 'checked')
      else
        $(@checkbox_selector).removeAttr('checked')
      @formVisibility()

  formVisibility: ->
    if $("#{@checkbox_selector}:checked").length is 0
      $(".bulk-action").hide()
    else
      $(".bulk-action").show()#.css('display', 'inline-block')
    $("table.items-list input:checked").parents("tr").addClass("checked")
    $("table.items-list input:not(:checked)").parents("tr").removeClass("checked")

class CustomColumns

  constructor: (root) ->
    root = $(root)
    @columnSelect = root.find('select.select-custom-column')
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
    label = $('<label>').text(text)
    input = $('<input>').attr('type': 'checkbox', 'checked': 'checked', 'name':"#{ul.data('type')}_columns[]", 'value':value)
    icon = $('<i class="fa fa-arrows-v">')
    $('<li>').append(input).append(label).append(icon).addClass('setting_attribute').appendTo ul

class ColumnSettings

  constructor: ->
    $.fn.wColorPicker.defaultSettings['onSelect'] = (color) ->
      this.settings.target.val(color)
    $('.column_settings').click (evt) =>
      [@column_name, table, view] = if (header = $(evt.currentTarget).closest('.column_header')).length
        [header.data('column-name'), header.data('table-name'), 'listing']
      else
        [$(evt.currentTarget).closest('th').attr('title'), $('.item-attributes').data('table'), 'show']
      remoteModal '#column-settings', {column: @column_name, table: table, view: view}, @setupEnumConfigurationPanel

  setupEnumConfigurationPanel: =>
    $("#is_enum").click @toggleEnumConfigurationPanel
    $('.template_line a').click @addNewEmptyLine
    $('.color').each ->
      $(this).wColorPicker
        target: $(this).siblings('input')
        initColor: $(this).data('color')

  toggleEnumConfigurationPanel: (evt) =>
    checked = $(evt.currentTarget)[0].checked
    $("table.enum_details_area tbody tr:not(.template_line)").remove()
    if (checked)
      $('.loading_enum').show().parents(".modal-body").scrollTop(1000)
      $.getJSON $(evt.currentTarget).data('values-url'), column_name: @column_name, (data) =>
        $('.enum_details_area').show()
        for value in data
          $('.template_line input[type=text]').val(value)
          @addNewEmptyLine()
        $('.loading_enum').hide().parents(".modal-body").scrollTop(1000)
    else
      $('.enum_details_area').hide()

  nextDefaultColor: =>
    index = $("table.enum_details_area .color").length
    colors = ['#2a8bcc', '#86b558', '#ffb650', '#d15b47', '#9585bf', '#a0a0a0', '#555555', '#d6487e', '#6fb3e0', '#892e65', '#2e8965', '#996666']
    if index > 1 && (index) < colors.length
      colors[index - 2]
    else
      '#0000FF'

  addNewEmptyLine: =>
    line = $('.template_line').clone()
    line.removeClass('template_line')
    line.find('a').remove()
    $('.template_line').before(line)
    $('.template_line input').val('')
    color = line.find('.color').html('')
    
    color.wColorPicker({target:color.siblings('input'), initColor: @nextDefaultColor()})
    previous_id = $('.template_line').data('line-identifer')
    new_id = parseInt(previous_id) + 1
    $('.template_line').data('line-identifer', new_id)
    for input in $('.template_line input:not(._wColorPicker_customInput)')
      $(input).attr('name', $(input).attr('name').replace(previous_id, new_id))
    $('.template_line input').eq(1).focus()

class UIListing
  
  adjustTableHeight: ->
    $('.content').height(window.innerHeight - $('.content').offset().top - 37)

  constructor: ->
    if $('.content').length
      @adjustTableHeight()
      window.onresize = @adjustTableHeight
    $('span.label span.remove, i.remove').click ->
      if $(this).data('param-kind')
        location.href = location.href.replace(new RegExp("([&?])#{$(this).data('param-kind')}=.*?(&|$)"), '$1')
      else
        escapeRegExp = (str) ->
          str.replace(/[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/g, "\\$&")
        location.href = location.href.replace(new RegExp("#{escapeRegExp $(this).data('param')}&?"), '')

$ ->
  new BulkActions()
  new CustomColumns('#displayed-columns_pane')
  new CustomColumns('#select-exported-fields_pane')
  new UIListing()
  new ColumnSettings()
  new FixedTableHeader()
