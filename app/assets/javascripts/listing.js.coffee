class BulkDestroy
  checkbox_selector: '.items-list tbody input[type=checkbox]'

  constructor: ->
    @form = $('.bulk-destroy')
    $(@checkbox_selector).click => @formVisibility()
    @form.submit =>
      items = $("#{@checkbox_selector}:checked")
      return false unless confirm "Are you sure you want to trash #{items.length} items ?"
      for item in items
        item_id = $(item).closest('tr').data('item-id')
        $('<input>').attr('type': 'hidden', 'name': 'item_ids[]').val(item_id).appendTo(@form)
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

$ ->
  new BulkDestroy()
  $('span.label span.remove').click ->
    window.location.href = unescape(window.location.href).replace($(this).data('param'), '')
  $('.breadcrumb').jscrollspy({
    min: $('.breadcrumb').offset().top,
    onEnter: (element, position) ->
      $(".breadcrumb").addClass('subnav-fixed')
    ,
    onLeave: (element, position) ->
      $(".breadcrumb").removeClass('subnav-fixed')
  })

