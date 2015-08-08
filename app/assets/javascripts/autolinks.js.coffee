autolinkQueryResults = ->
  $('.table td, dl dd').each ->
    text = $(this).text()
    if text.match(/^\S+@\S+\.\S+$/)
      $(this).append("<a target=\"_blank\" title='send a email to this address' href=\"mailto:#{text}\"><i class='fa fa-envelope'></i></a>")
    else
      return if text.match /\d+\.\d+/
      if text.match(/^((http|ftp|https):\/\/)?[\w\-_]+(\.[\w\-_]+)+([\w\-\.,@?^=%&amp;:\/~\+#]*[\w\-\@?^=%&amp;\/~\+#])?$/)
        link = if text.match('://') then text else "http://#{text}"
        $(this).append("<a target=\"_blank\" href=\"#{link}\" title='open a new page to this url'><i class='fa fa-external-link'></i></a>")

$ autolinkQueryResults
