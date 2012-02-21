$(autolinkQueryResults)

function autolinkQueryResults(){
  $('.table td').each(function(){
    text = $(this).text()
    if (text.match(/^\S+@\S+\.\S+$/))
      $(this).html("<a target=\"_blank\" href=\"mailto:" + text + "\">" + text + "</a>")
    else {
      if (text.match(/((http|ftp|https):\/\/)?[\w\-_]+(\.[\w\-_]+)+([\w\-\.,@?^=%&amp;:\/~\+#]*[\w\-\@?^=%&amp;\/~\+#])?/)){
        if (!text.match('://'))
          link = 'http://' + text
        else
          link = text
        $(this).html("<a target=\"_blank\" href=\"" + link + "\">" + text + "</a>")
      }
    }
  })
}
