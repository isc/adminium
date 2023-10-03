@AppsCtrl = ['$scope', '$http', ($scope, $http) ->
  $scope.apps = []
  $scope.addonProvisioning = new AddonProvisioning()
  $http.get(window.location.href).success (data) ->
    if data.error
      $('.unauthorized').removeClass('hidden')
    else
      $scope.apps = data.apps
  $scope.installed = ->
    !!@app.plan
    
  $scope.appSelection = ->
    $scope.selectedApp = @app
    if @app.plan
      window.location.href = "/sessions/switch_account?account_id=#{@app.id}"
    else
      $scope.addonProvisioning.showModal @app
]

class AddonProvisioning
  
  constructor: ->
    @modal = $('#create-addon-modal')
    @modalBody = @modal.find('.modal-body')
    return if @modal.length is 0
    $('a[data-name][data-app-id]').click @showModal
    $('a[data-plan]').click @provision

  showModal: (app) =>
    @modal.modal 'show'
    @modal.find('.modal-body > div').hide()
    @modal.find('.step1').show()
    $('a[data-plan]').data(name: app.name, app_id: app.id)

  provision: (evt) =>
    elt = $(evt.currentTarget)
    name = elt.data('name')
    app_id = elt.data('app_id')
    plan = elt.data('plan')
    @modal.find('.modal-body > div').hide()
    @modalBody.find('.step2').show()
    @modalBody.find('.step2 h4').text("Installing Adminium on #{name} with plan #{plan}")
    $.ajax
      type: 'POST'
      url: '/account'
      data:
        app_id: app_id
        name: name
        plan: plan
      success: @submitCallback
      error: @errorCallback
  
  submitCallback: (data) =>
    if data.success
      window.location.href = '/dashboard'
    else
      @errorCallback data.error
  
  errorCallback: (msg) =>
    msg ||= 'Something went wrong'
    @modal.find('.modal-body > div').hide()
    @modal.find('.error').show().find('p').text(msg)
