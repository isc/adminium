$ ->
  format = (object) ->
    text = object.text.replace(')', '</b>)</span>')
    text = text.replace('(GMT', '<span class="timezoneselect_format">(GMT<b>')
    return text
  $('.timezone_select2').select2({matcher: adminiumSelect2Matcher, formatResult: format, formatResult: format, placeholder: '(GMT+00:00) UTC'})