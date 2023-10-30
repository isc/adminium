$ ->
  $('#cancel_tip').on 'ajax:complete', (et, e) ->
    if JSON.parse(e.responseText)
      $("#welcome-modal .modal-footer").html("<p class='alert alert-info'>Okay, tips will not appear anymore</p>")
      setTimeout () ->
        $("#welcome-modal").modal('hide')
      , 1500
