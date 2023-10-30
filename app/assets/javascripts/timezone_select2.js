$(() => {
  const format = (state) => $('<span>').html(state.text.replace(')', '</b>)').replace('(GMT', '(GMT<b>'))
  $('.timezone_select2').select2({ templateResult: format, placeholder: '(GMT+00:00) UTC' })
})
