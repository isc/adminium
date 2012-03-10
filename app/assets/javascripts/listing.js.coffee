$ ->
  $('span.label span.remove').click ->
    window.location.href = unescape(window.location.href).replace($(this).data('param'), '')
