$ ->
  $('.sidebar-nav .search-query').keyup ->
    value = this.value.toLowerCase()
    $('.sidebar-nav li:not(.nav-header)').each ->
      table = $(this).text().toLowerCase()
      $(this).toggle(!!table.match(value))
