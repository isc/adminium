class @FixedTableHeader
  
  constructor: ->
    if window.environment == 'development'
      console.log('FixedTableHeader activated only in dev for now')
    else
      return
    return if $('table.items-list').length == 0
    for elt in $('table.items-list thead th')
      width =  $(elt).width()
      $(elt).attr('style', "width:#{width}px !important")
    w = $('table.items-list thead').width()
    @header = $('table.items-list thead').clone()
    $('body').append(@header)
    @header.css('width', w).addClass('header-fixed')
    @header.hide()
    @checking = false
    @currentTopValue = 0
    @lastTopValue = 0
    @header.jscrollspy
      min: $('.breadcrumb').offset().top
      max: () -> $(document).height()
      onEnter: (element, position) =>
        @header.show()
      onLeave: (element, position) =>
        @header.hide()
    @header.on 'scrollTick', @check
  
  check: (evt, o) =>
    return if o.position.top == @currentTopValue
    @currentTopValue = o.position.top
    @header.removeClass('appear').css('-webkit-transform': "translate(0px, 0px)")
    return if @checking
    @checking = true
    @lastTopValue = o.position.top
    setTimeout () =>
      @checking = false
      if (@lastTopValue == @currentTopValue)
        @header.css('top', $(".breadcrumb").position().top)
        breadcrumb_height = $(".breadcrumb").height()
        @header.css('-webkit-transform': "translate(0px, #{breadcrumb_height}px)").addClass('appear')
      else
        @check(null, o)
    , 200
  