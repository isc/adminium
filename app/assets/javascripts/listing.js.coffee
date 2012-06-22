class BulkActions
  checkbox_selector: '.items-list tbody input[type=checkbox]'

  constructor: ->
    $("#bulk-edit-modal").on 'hide', =>
      $("#bulk-edit-modal").html($(".loading_modal").html())
    $("#bulk-edit-modal").on 'shown', =>
      $("#bulk-edit-modal").html($(".loading_modal").html())
      item_ids = ""
      for item in $("#{@checkbox_selector}:checked")
        item_ids += "record_ids[]=#{$(item).closest('tr').data('item-id')}&"
      path=$("#bulk-edit-modal").attr("data-remote-path")
      $.get "#{path}?#{item_ids}", (data) =>
        $("#bulk-edit-modal").html(data)
        $('.datepicker').datepicker onClose: (dateText, inst) ->
          $("##{inst.id}_1i").val(inst.selectedYear)
          $("##{inst.id}_2i").val(inst.selectedMonth + 1)
          $("##{inst.id}_3i").val(inst.selectedDay)

    @form = $('.bulk-destroy')
    $(@checkbox_selector).click => @formVisibility()
    @form.submit =>
      items = $("#{@checkbox_selector}:checked")
      return false unless confirm "Are you sure you want to trash the #{items.length} selected items ?"
      for item in items
        item_id = $(item).closest('tr').data('item-id')
        $('<input>').attr('type': 'hidden', 'name': 'item_ids[]').val(item_id).appendTo(@form)
    $(".click_checkbox").click (e) =>
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

  constructor: ->
    [@assocSelect, @columnSelect] = [$('select.select-custom-assoc'), $('select.select-custom-column')]
    @addButton = $('.custom-column button')
    @associationSelection()
    @columnSelection()
    @customColumnAdd()

  associationSelection: ->
    @assocSelect.change (elt) =>
      assocSelect = $(elt.currentTarget)
      columnSelect = assocSelect.siblings(".select-custom-column")
      addButton = assocSelect.siblings("button")
      if assocSelect.val()
        $.get assocSelect.data().columnsPath, table: assocSelect.val(), (data) =>
          $('<option>').appendTo columnSelect
          for column in data
            $('<option>').text(column).val(column).appendTo columnSelect
      else
        columnSelect.empty()
        addButton.attr('disabled', 'disabled')

  columnSelection: ->
    @columnSelect.change (elt) =>
      columnSelect = $(elt.currentTarget)
      addButton = columnSelect.siblings("button")
      if columnSelect.val()
        addButton.removeAttr('disabled')
      else
        addButton.attr('disabled', 'disabled')

  customColumnAdd: ->
    @addButton.click (elt) =>
      addButton = $(elt.currentTarget)
      assocSelect = addButton.siblings(".select-custom-assoc")
      columnSelect = addButton.siblings(".select-custom-column")
      ul = addButton.parents(".custom-column").siblings("ul")
      type = ul.attr("data-type")
      value = "#{assocSelect.text()}.#{columnSelect.val()}"
      label = $('<label>').text(value.replace(".", " "))
      input = $('<input>').attr('type': 'checkbox', 'checked': 'checked', 'name':"#{type}_columns[]", 'value':value)
      icon = $('<i>').addClass('icon-resize-vertical')

      $('<li>').append(input).append(label).append(icon).
        addClass('setting_attribute').appendTo ul
      false

class ColumnSettings
  constructor: ->
    $(".column_settings").click ->
      column_name = $(this).attr("rel")
      path = $("#column-settings").attr("data-remote-path") + "?column=#{column_name}"
      $("#column-settings").html($(".loading_modal").html())
      $("#column-settings").modal('show')
      $.get path, (data) =>
        $("#column-settings").html(data)

class UIListing
  constructor: ->
    $('span.label span.remove').click ->
      if $(this).data('param-kind')
        window.location.href = window.location.href.replace(new RegExp("#{$(this).data('param-kind')}=.*?(&|$)"), '')
      else
        window.location.href = window.location.href.replace($(this).data('param'), '')
    if $('.breadcrumb').length > 0
      $('.breadcrumb').jscrollspy
        min: $('.breadcrumb').offset().top,
        max: $(document).height(),
        onEnter: (element, position) ->
          $(".breadcrumb").addClass('subnav-fixed')
        ,
        onLeave: (element, position) ->
          $(".breadcrumb").removeClass('subnav-fixed')


$ ->
  new BulkActions()
  new CustomColumns()
  new UIListing()
  new ColumnSettings()