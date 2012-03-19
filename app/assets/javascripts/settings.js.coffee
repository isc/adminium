$ ->
  $('#settings ul').sortable()
  $("ul.filters span.btn").live 'click', ->
    $(this).parent('li').remove()
  $("#new_filter").bind 'change', (event) ->
    column_name = $("#new_filter option:selected").val()
    table = $("#new_filter").attr("data-table")
    $.get "/settings/#{table}?column_name=#{column_name}", (resp) ->
      $("<li>").append(resp).appendTo($(".filters"))
  setupValidations()
  setupEnumValues()
  
  
setupValidations = ->
  $('#validations a.btn').click ->
    val = $('#validations select:eq(0)').val()
    text = "#{$('#validations select:eq(0) option:selected').text()} #{$('#validations select:eq(1) option:selected').text()}"
    $('<li>').text(text).appendTo('#validations ul')
    
setupEnumValues = ->
  $('#enum_value_column_name').change ->
    $.getJSON $(this).data('values-url'), column_name:this.value, (data) ->
      text = ("#{value}: " for value in data).join("\n")
      $('#enum_value_values').val(text)
  $('#enum-values_pane button').click ->
    [column, values] = [$('#enum_value_column_name').val(), $('#enum_value_values').val()]
    $('<tr>').append($('<td>').text(column)).append($('<td>').text(values)).appendTo('#enum-values_pane table')
    $('#enum-values_pane .params')
      .append($('<input type="hidden">').attr(name:'enum_values[][column_name]', value:column))
      .append($('<input type="hidden">').attr(name:'enum_values[][values]', value:values))
    false
