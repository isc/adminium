class window.Gravatar

  @picture: (email, size) ->
    "http://www.gravatar.com/avatar/#{md5(email)}.jpg?d=blank&s=#{size || 50}"

  @profile: (email) ->
    "http://www.gravatar.com/#{md5(email)}"

  @findAll: ->
    emailCells = $("td[data-column-name='email']")
    return if emailCells.length is 0
    $("<th>").insertAfter $('th.checkboxes')
    for elt in emailCells
      here = $(elt).parent('tr').find('.click_checkbox')
      value = $(elt).text()
      image = if value.indexOf('@') isnt -1
        "<a href='#{@profile(value)}' target='_blank'><img src='#{@picture(value)}' /></a>"
      else
        ""
      td = $("<td>#{image}</td>")
      td.insertAfter(here)

$ ->
  Gravatar.findAll()