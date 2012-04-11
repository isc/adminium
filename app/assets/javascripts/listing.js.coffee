class BulkDestroy
  checkbox_selector: '.items-list tbody input[type=checkbox]'

  constructor: ->
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
      @form.hide()
    else
      @form.show().css('display', 'inline-block')

class CustomColumns
  
  constructor: ->
    [@assocSelect, @columnSelect] = [$('.custom-column select:eq(0)'), $('.custom-column select:eq(1)')]
    @addButton = $('.custom-column button')
    @associationSelection()
    @columnSelection()
    @customColumnAdd()
    
  associationSelection: ->
    @assocSelect.change =>
      if @assocSelect.val()
        $.get @assocSelect.data().columnsPath, table: @assocSelect.val(), (data) =>
          $('<option>').appendTo @columnSelect
          for column in data
            $('<option>').text(column).val(column).appendTo @columnSelect
      else
        @columnSelect.empty()
        @addButton.attr('disabled', 'disabled')
        
  columnSelection: ->
    @columnSelect.change =>
      if @columnSelect.val()
        @addButton.removeAttr('disabled')
      else
        @addButton.attr('disabled', 'disabled')
  
  customColumnAdd: ->
    @addButton.click =>
      label = $('<label>').text("#{@assocSelect.val()} #{@columnSelect.val()}")
      input = $('<input>').attr('type': 'checkbox', 'checked': 'checked', 'name':'listing_columns[]', 'value':"#{@assocSelect.val()}.#{@columnSelect.val()}")
      icon = $('<i>').addClass('icon-resize-vertical')
      $('<li>').append(input).append(label).append(icon).
        addClass('setting_attribute').appendTo 'ul#listing_columns_list'
      false

$ ->
  new BulkDestroy()
  new CustomColumns()
  $('span.label span.remove').click ->
    window.location.href = unescape(window.location.href).replace($(this).data('param'), '')
  if $('.breadcrumb').length > 0
    $('.breadcrumb').jscrollspy
      min: $('.breadcrumb').offset().top,
      max: $(document).height(),
      onEnter: (element, position) ->
        $(".breadcrumb").addClass('subnav-fixed')
      ,
      onLeave: (element, position) ->
        $(".breadcrumb").removeClass('subnav-fixed')
