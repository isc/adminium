class @NullifiableInput
  
  @setup: (path, bulkEdit) ->
    $(path).each (index, elt) ->
      new NullifiableInput($(elt), bulkEdit)
  
  constructor: (input, bulkEdit, @type) ->
    @bulkEditMode = bulkEdit
    @input = input 
    match = input.get(0).name.match(/\[(.*)\](\[\d\])*/)
    return unless match
    @column_name = match[1]
    @type ||= columns_hash[@column_name].type if columns_hash[@column_name]
    return if @type isnt 'string' and @type isnt 'text'
    @controls = input.parents('.controls')
    title_n = "Will save a NULL value if selected"
    title_e = "Will save an empty string if selected"
    @btns = $("<div class='null_btn' title='#{title_n}'>null</div><div class='empty_string_btn selected' title='#{title_e}'>empty string</div>")
    @btns.tooltip()
    hidden_input_name = input.get(0).name.replace("[", "_nullify_settings[")
    @hidden_input = $("<input name='#{hidden_input_name}' value='empty_string' type='hidden'></input>")
    @controls.append(@btns).append(@hidden_input)
    @empty_string_btn = @controls.find(".empty_string_btn")
    @null_btn = @controls.find(".null_btn")
    @input.on 'keyup', @displaySwitchEmptyValueLink
    @setBtnPositions()
    @toggleBtns()
    @btns.click (evt) =>
      @switchEmptyInputValue $(evt.currentTarget), true
      false
    if @bulkEditMode
      @unselectBoth()
    else
      @switchEmptyInputValue @null_btn, false if input.data('null-value')
  
  displaySwitchEmptyValueLink: =>
    @toggleBtns()
  
  toggleBtns: =>
    show = @input.val().length is 0
    @unselectBoth() if show and @bulkEditMode
    @btns.toggleClass('active', show)
    
  setBtnPositions: =>
    return if @input.length is 0
    left = @input.position().left + @input.width() - @empty_string_btn.width() - 2
    top = @input.position().top
    @empty_string_btn.css('left', left)
    @null_btn.css('left', left - @null_btn.width() - 11)
  
  switchEmptyInputValue: (link, user_action) =>
    @input.focus() if user_action
    return @unselectBoth() if @bulkEditMode and link.hasClass 'selected'
    @btns.removeClass 'selected'
    link.addClass 'selected'
    value = if link.hasClass 'empty_string_btn' then 'empty_string' else 'null'
    @hidden_input.val(value)

  unselectBoth: =>
    @btns.removeClass('selected')
    @hidden_input.val('')