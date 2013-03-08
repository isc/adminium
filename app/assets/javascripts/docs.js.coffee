$ ->
  for feature in $('.feature-description')
    id = $(feature).attr('id')
    title = $(feature).find('h2').text()
    li = $("<li><a href='##{id}'>#{title}</a></li>")
    li.insertAfter($('#features'))
    #documentation