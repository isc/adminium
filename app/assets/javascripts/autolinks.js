const autolinkQueryResults = () => {
  $('.table td, dl dd').each(function(){
    const text = $(this).text()
    if (text.match(/^\S+@\S+\.\S+$/)) {
      $(this).append(` <a target="_blank" title='send an email to this address' href="mailto:${text}"><i class='fa fa-envelope subtle'></i></a>`)
    } else {
      if (text.match(/\d+\.\d+/)) {
        return // Skip processing for numeric patterns with a dot
      }
      if (text.match(/^((http|ftp|https):\/\/)?[\w\-_]+(\.[\w\-_]+)+([\w\-\.,@?^=%&amp;:\/~\+#]*[\w\-\@?^=%&amp;\/~\+#])?$/)) {
        const link = text.match('://') ? text : `http://${text}`
        $(this).append(` <a target="_blank" href="${link}" title='open a new page to this URL'><i class='fa fa-external-link subtle'></i></a>`)
      }
    }
  })
}

$(autolinkQueryResults)
