$ ->
  for feature in $('.feature-description')
    id = $(feature).attr('id')
    title = $(feature).find('h2').text()
    li = $("<li><a href='##{id}'>#{title}</a></li>")
    li.insertAfter($('#features'))

  $("#cancel_tip").bind 'ajax:complete', (et, e) ->
    if JSON.parse(e.responseText)
      $("#welcome-modal .modal-footer").html("<p class='alert alert-info'>Okay, tips will not appear anymore</p>")
      setTimeout () ->
        $("#welcome-modal").modal('hide')
      , 1500
