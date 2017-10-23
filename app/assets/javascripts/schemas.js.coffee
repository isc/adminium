@SchemasCtrl = ['$scope', ($scope) ->

  $scope.table_name = ''

  $scope.columns = []

  $scope.addColumn = ->
    $scope.columns.push({name: null, type: 'integer', index: null, null: true, default: null});

  $scope.remove = (index) ->
    $scope.columns.splice index, 1

  $scope.reset = ->
    $scope.table_name = ""
    $scope.columns = [{name: 'id', null: false, unique: false, primary: true, type: 'integer', default: null},
     {name: '', null: true, unique: false, primary: false, type: 'integer', primary: false, default: null}]
    $("#create-table-modal").modal('hide')
]

$ ->
  $("form#create_table").on 'ajax:before', ->
    $("#create-table-modal").modal('show')
    $("#create-table-modal .s").hide()
    $("#create-table-modal .before").show()

  $("form#create_table").on 'ajax:error', (evt) ->
    $("#create-table-modal .s").hide()
    $("#create-table-modal .error").show().find('p').html("Something unusual happened, we've been notified, you can open a ticket if you want to get in touch with us to know more about this issue and its resolving")
  $("form#create_table").on 'ajax:success', (evt, data) ->
    $("#create-table-modal .s").hide()
    if data.error
      $("#create-table-modal .error").show().find('p').html(data.error)
    else
      $("#create-table-modal .success").show()

  $(".rename_column").on 'click', (evt) ->
    column_name = $(evt.currentTarget).parents('th').data('value')
    $("#rename-column").modal("show")
    $("#rename-column input[name=column_name], #rename-column input[name=new_column_name]").val(column_name)

  $(".change_column_type").on 'click', (evt) ->
    column_name = $(evt.currentTarget).data('column-name')
    $("#change-column-type input[name=column_name]").val(column_name)
    $("#change-column-type").modal("show")
