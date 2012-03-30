$ ->
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