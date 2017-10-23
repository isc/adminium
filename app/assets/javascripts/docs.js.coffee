$ ->
  for feature in $('.feature-description').toArray().reverse()
    id = $(feature).attr('id')
    title = $(feature).find('h3').text()
    li = $("<li><a href='##{id}'>#{title}</a></li>")
    li.insertAfter($('#features'))

  $('#cancel_tip').on 'ajax:complete', (et, e) ->
    if JSON.parse(e.responseText)
      $("#welcome-modal .modal-footer").html("<p class='alert alert-info'>Okay, tips will not appear anymore</p>")
      setTimeout () ->
        $("#welcome-modal").modal('hide')
      , 1500
