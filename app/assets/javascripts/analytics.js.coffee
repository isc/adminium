class window.Analytics

  @event: (category, action, label, value) ->
    params = ['_trackEvent', category, action, label]
    params.push(value) if value
    if window['_gaq']
      _gaq.push(params)
    else
      console.log(params)

  @importEvent: (action, label, value) ->
    @event('Import', action, label, value)