$ ->
  $('#settings ul').sortable()
  $("ul.filters span.btn").live 'click', ->
    $(this).parent('li').remove()
  $("#new_filter").bind 'change', (event) ->
    column_name = $("#new_filter option:selected").val()
    table = $("#new_filter").attr("data-table")
    $.get "/settings/#{table}?column_name=#{column_name}", (resp) ->
      $("<li>").append(resp).appendTo($(".filters"))
