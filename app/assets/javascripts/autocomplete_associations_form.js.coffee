class AutocompleteAssociationsForm

  @setup: =>
    for search_input in $("input[data-autocomplete-url]")
      new AutocompleteAssociationsForm($(search_input))

  constructor: (search_input) ->
    control = search_input.parents('div.controls')
    @hidden_input = control.find('input[type=hidden]')
    @record_selected_area = control.find('.record_selected')
    @record_selected_value = control.find('.record_selected span')
    @spinner = control.find('.icon-refresh')
    @list = control.find('ul')
    @search_input = search_input
    @search_input.on 'keyup', @keyUp
    @record_selected_area.find('.icon-remove-sign').on 'click', @clearSelected
    @url = search_input.data('autocomplete-url')
    @current_requests = 0

  clearSelected: =>
    @record_selected_area.toggle(false)
    @record_selected_value.text('')
    @hidden_input.val('')

  keyUp: (evt) =>
    value = $(evt.currentTarget).val()
    return if @query == value
    @query = value
    clearTimeout(@timeoutId)
    @timeoutId = setTimeout @search, 300

  search: () =>
    @current_requests += 1
    @spinner.toggleClass('loading', true)
    query = @query.toLowerCase()
    $.ajax
      url: "#{@url}?search=#{query}"
      complete: =>
        @current_requests -= 1
        @current_requests = 0 if @current_requests < 0
        @spinner.toggleClass('loading', @current_requests != 0)
      success: (data) =>
        @list.html('')
        for record in data
          text = record.adminium_label.toLowerCase()
          if text.indexOf(query) isnt -1
            text = text.replace(query, "<span class='highlight'>#{query}</span>")
          else
            attrs = []
            for name, value of record
              continue unless value
              value = value.toString().toLowerCase()
              if value.indexOf(query) isnt -1
                attrs.push "<i>#{name}=</i>#{value.replace(query, "<span class='highlight'>#{query}</span>")}"
            text += "<span class='other_attrs'>#{attrs.join(" ")}</span>" if attrs.length > 0
          li = $("<li>").html(text).data('label', record.adminium_label).data('record_id', record.id).appendTo(@list)
          li.on 'click', @selectRecord

  selectRecord: (evt) =>
    li = $(evt.currentTarget)
    @hidden_input.val li.data('record_id')
    @record_selected_value.text li.data('label')
    @record_selected_area.toggle(true)
    @record_selected_area.find('i').toggle(false)
    setTimeout =>
      @record_selected_area.find('i').toggle(true)
    , 25
    li.siblings('.selected').removeClass('selected')
    li.addClass('selected')

$ ->
  AutocompleteAssociationsForm.setup()