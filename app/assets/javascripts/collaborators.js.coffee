$ ->
  $('#new_collaborator').live 'ajax:before', ->
    input = $(this).find('input[type=email]')
    $('<li>').text(input.val()).appendTo('#collaborators')
  $('#new_collaborator').live 'ajax:complete', ->
    $(this).find('input[type=email]').val('')
  $('#collaborators a').live 'ajax:complete', ->
    $(this).closest('li').remove()