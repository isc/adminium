@AppsCtrl = ['$scope', '$http', ($scope, $http) ->
  $scope.apps = []
  $scope.addonProvisioning = new AddonProvisioning()
  $http.get(window.location.href).success (data) ->
    $scope.apps = data
    $("tr.loading").remove()
  $scope.appSelection = ->
    $scope.selectedApp = @app
    if @app.plan
      console.log('..')
      window.location.href = "/sessions/login_heroku_app?id=#{@app.heroku_id}"
    else
      $scope.addonProvisioning.showModal @app
]

class AddonProvisioning
  
  constructor: ->
    @modal = $("#create-addon-modal")
    @modalBody = @modal.find(".modal-body")
    return if @modal.length == 0
    $("a[data-name][data-app-id]").click @showModal
    $("a[data-plan]").click @provision

  showModal: (app) =>
    @modal.modal("show")
    @modal.find('.modal-body > div, .modal-footer').hide()
    @modal.find(".step1").show()
    $("a[data-plan]").data('name', app.name)
    $("a[data-plan]").data('app-id', app.id)

  provision: (evt) =>
    elt = $(evt.currentTarget)
    name = elt.data('name')
    app_id = elt.data('app-id')
    plan = elt.data('plan')
    @modal.find('.modal-body > div, .modal-footer').hide()
    @modalBody.find('.step2').show()
    @modalBody.find('.step2 h2').text("Installing Adminium on: #{name}")
    @modalBody.find('.step2 h3').text("selected plan: #{plan}")
    $.ajax
      type: 'POST'
      url: "/account"
      data:
        app_id: app_id
        name: name
      success: @submitCallback
      error: @errorCallback
  
  submitCallback: (data) =>
    if data.success
      window.location.href = "/dashboard"
    else
      @errorCallback(data.error)
  
  errorCallback: (msg) =>
    msg ||= "Something went wrong"
    @modal.find('.modal-body > div, .modal-footer').hide()
    @modal.find(".error").show().find("p").text(msg)
