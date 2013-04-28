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
    [@assocSelect, @columnSelect] = [root.find('select.select-custom-assoc'), root.find('select.select-custom-column')]
    @addButton = root.find('.custom-column button')
    @associationSelection()
    @columnSelection()
    @customColumnAdd()

  associationSelection: ->
    @assocSelect.change (elt) =>
      @type = @assocSelect.find('option:selected').closest('optgroup').attr('label')
      if @assocSelect.val()
        if @type is 'belongs_to'
          $.get @assocSelect.data().columnsPath, table: @assocSelect.val(), (data) =>
            @columnSelect.empty().removeAttr('disabled')
            $('<option>').appendTo @columnSelect
            for column in data
              $('<option>').text(column).val(column).appendTo @columnSelect
        else
          @columnSelect.attr('disabled', 'disabled')
          @addButton.removeAttr('disabled')
      else
        @columnSelect.empty()
        @addButton.attr('disabled', 'disabled')

  columnSelection: ->
    @columnSelect.change (elt) =>
      if @columnSelect.val()
        @addButton.removeAttr('disabled')
      else
        @addButton.attr('disabled', 'disabled')

  customColumnAdd: ->
    @addButton.click (elt) =>
      ul = @addButton.parents(".custom-column").siblings("ul")
      type = ul.attr("data-type")
      if @type is 'belongs_to'
        option = @assocSelect.find('option:selected')
        value = "#{option.val()}.#{@columnSelect.val()}"
        text = "#{option.text()}'s #{@columnSelect.val()}"
      else
        value = "has_many/#{@assocSelect.val()}"
        text = @assocSelect.find('option:selected').text()
      label = $('<label>').text(text)
      input = $('<input>').attr('type': 'checkbox', 'checked': 'checked', 'name':"#{type}_columns[]", 'value':value)
      icon = $('<i>').addClass('icon-resize-vertical')
      $('<li>').append(input).append(label).append(icon).
        addClass('setting_attribute').appendTo ul
      false

class ColumnSettings

  constructor: ->
    $.fn.wColorPicker.defaultSettings['onSelect'] = (color) ->
      this.settings.target.val(color)

    $(".column_settings").click (evt) =>
      @column_name = $(evt.currentTarget).closest('.column_header').data('column-name')
      @column_name ||= $(evt.currentTarget).closest('th').next().data('column-name')
      remoteModal '#column-settings', {column: @column_name}, =>
        @setupEnumConfigurationPanel()

  setupEnumConfigurationPanel: =>
    $("#is_enum").click @toggleEnumConfigurationPanel
    $('.template_line a').click @addNewEmptyLine
    $('.color').each () ->
      $(this).wColorPicker
        target: $(this).siblings('input')
        initColor: $(this).data('color')

  toggleEnumConfigurationPanel: (evt) =>
    checked = $(evt.currentTarget)[0].checked
    $("table.enum_details_area tbody tr:not(.template_line)").remove()
    if (checked)
      $('.loading_enum').show().parents(".modal-body").scrollTop(1000)
      $.getJSON $(evt.currentTarget).data('values-url'), column_name:@column_name, (data) =>
        $('.enum_details_area').show()
        for value in data
          $('.template_line input[type=text]').val(value)
          @addNewEmptyLine()
        $('.loading_enum').hide().parents(".modal-body").scrollTop(1000)
    else
      $('.enum_details_area').hide()

  addNewEmptyLine: =>
    line = $('.template_line').clone()
    line.removeClass('template_line')
    line.find('a').remove()
    $('.template_line').before(line)
    $('.template_line input').val('')
    color = line.find('.color').html('')
    color.wColorPicker({target:color.siblings('input')})
    previous_id = $('.template_line').data('line-identifer')
    new_id = parseInt(previous_id) + 1
    $('.template_line').data('line-identifer', new_id)
    for input in $('.template_line input:not(._wColorPicker_customInput)')
      $(input).attr('name', $(input).attr('name').replace(previous_id, new_id))
    $('.template_line input').eq(1).focus()

class UIListing
  constructor: ->
    $('span.label span.remove, i.remove').click ->
      if $(this).data('param-kind')
        location.href = location.href.replace(new RegExp("[&?]#{$(this).data('param-kind')}=.*?(&|$)"), '')
      else
        location.href = location.href.replace(new RegExp("#{$(this).data('param')}&?"), '')
    if $('.breadcrumb').length > 0
      $('.breadcrumb').jscrollspy
        min: $('.breadcrumb').offset().top,
        max: () -> $(document).height(),
        onEnter: (element, position) ->
          $(".breadcrumb").addClass('subnav-fixed')
        ,
        onLeave: (element, position) ->
          $(".breadcrumb").removeClass('subnav-fixed')

$ ->
  new BulkActions()
  new CustomColumns('#displayed-columns_pane')
  new CustomColumns('#select-exported-fields_pane')
  new UIListing()
  new ColumnSettings()
