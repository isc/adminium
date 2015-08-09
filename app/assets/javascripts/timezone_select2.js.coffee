$ ->
  format = (object) ->
    object.text.replace(')', '</b>)').replace('(GMT', '(GMT<b>')
  $('.timezone_select2').select2({matcher: adminiumSelect2Matcher, formatResult: format, placeholder: '(GMT+00:00) UTC'})
