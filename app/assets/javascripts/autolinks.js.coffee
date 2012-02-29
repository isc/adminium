autolinkQueryResults = ->
  $('.table td, dl dd').each ->
    text = $(this).text()
    if text.match(/^\S+@\S+\.\S+$/)
      $(this).html("<a target=\"_blank\" href=\"mailto:#{text}\">#{text}</a>")
    else
      return if text.match /\d+\.\d+/
      if text.match(/((http|ftp|https):\/\/)?[\w\-_]+(\.[\w\-_]+)+([\w\-\.,@?^=%&amp;:\/~\+#]*[\w\-\@?^=%&amp;\/~\+#])?/)
        link = if text.match('://') then text else "http://#{text}"
        $(this).html("<a target=\"_blank\" href=\"#{link}\">#{text}</a>")

$ autolinkQueryResults
