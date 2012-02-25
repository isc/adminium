jQuery ->
  $('#settings ul').sortable()
  $("#new_filter").bind 'change', (event) ->
    column_name = $("#new_filter option:selected").val()
    table = $("#new_filter").attr("data-table")
    $.get "/settings/#{table}?column_name=#{column_name}", (resp) ->
      $("<li class='form-inline'>").append(resp).appendTo($(".filters"))
