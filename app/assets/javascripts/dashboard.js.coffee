petprojectLimitationPopup = ->
  $('.dashboards.show tr.deactivated a').on 'click', (evt) ->
    $('#upgrade_from_pet_project').modal('show')
    evt.preventDefault()

$ petprojectLimitationPopup
