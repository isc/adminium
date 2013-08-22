class AddonProvisioning
  
  constructor: ->
    @modal = $("#create-addon-modal")
    @modalBody = @modal.find(".modal-body")
    return if @modal.length == 0
    $("a[data-name][data-app-id]").click @showModal
    $("a[data-plan]").click @provision

  showModal: (evt) =>
    elt = $(evt.currentTarget)
    @modal.modal("show")
    @modalBody.find('> div').hide()
    @modalBody.find(".step1").show()
    $("a[data-plan]").data('name', elt.data('name'))
    $("a[data-plan]").data('app-id', elt.data('app-id'))

  provision: (evt) =>
    elt = $(evt.currentTarget)
    name = elt.data('name')
    app_id = elt.data('app-id')
    plan = elt.data('plan')
    @modalBody.find('> div').hide()
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
      @errorCallback()
  
  errorCallback: =>
    @modalBody.find("> div").hide()
    @modalBody.find(".error").show()

$ ->
  new AddonProvisioning()