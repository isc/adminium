class window.AutocompleteAssociationsForm

  @setup: =>
    for search_input in $("input[data-autocomplete-url]")
      new AutocompleteAssociationsForm($(search_input))

  constructor: (search_input) ->
    return if search_input.data('autocomplete-association') is 'done'
    control = search_input.closest('.adminium-association')
    @hidden_input = control.find('input[type=hidden]')
    @single_record_area = control.find('.single-record')
    @single_record_value = control.find('.single-record input')
    @selected_records_area = control.find('.multiple-records')
    @spinner = control.find('.fa-refresh')
    @list = control.find('ul')
    search_input.on 'keyup', @keyUp
    @single_record_area.find('a.clear-selection').on 'click', @clearSelected
    @url = search_input.data('autocomplete-url')
    @current_requests = 0
    search_input.data('autocomplete-association', 'done')

  clearSelected: =>
    @single_record_area.find('.input-group-addon i').addClass('invisible')
    @single_record_value.val('null')
    @hidden_input.val('')
    false

  keyUp: (evt) =>
    value = $(evt.currentTarget).val()
    return if @query is value.toLowerCase()
    @query = value.toLowerCase()
    clearTimeout(@timeoutId)
    @timeoutId = setTimeout @search, 300

  search: =>
    @current_requests += 1
    query = @query
    return @list.html('') unless query.length
    @spinner.removeClass('invisible')
    $.ajax
      url: "#{@url}&search=#{query}"
      complete: =>
        @current_requests -= 1
        @current_requests = 0 if @current_requests < 0
        @spinner.toggleClass('invisible', @current_requests is 0)
      success: (data) =>
        @list.html('')
        for record in data.results
          text = record.adminium_label.toString().toLowerCase()
          if text.indexOf(query) isnt -1
            text = text.replace(query, "<span class='highlight'>#{query}</span>")
          else
            attrs = []
            for name, value of record
              continue unless value
              value = value.toString().toLowerCase()
              if value.indexOf(query) isnt -1
                attrs.push "<i class='text-muted'>#{name}=</i>#{value.replace(query, "<span class='bg-success'>#{query}</span>")}"
            text += " <span>#{attrs.join(" ")}</span>" if attrs.length > 0
          li = $("<li>").html(text).data('label', record.adminium_label).data('record_pk', record[data.primary_key]).appendTo(@list)
          li.on 'click', @selectRecord

  selectRecord: (evt) =>
    li = $(evt.currentTarget)
    if @single_record_area.length
      @hidden_input.val li.data('record_pk')
      @single_record_value.val li.data('label')
      @single_record_area.find('.input-group-addon i').removeClass('invisible')
    else
      label = $('<label>')
      input = $('<input type="checkbox" checked="checked">').
        attr(name: @selected_records_area.data('input-name')).val(li.data('record_pk')).appendTo(label)
      label.append(" #{li.data('label')}")
      label.appendTo(@selected_records_area)
    li.siblings('.bg-info').removeClass('bg-info')
    li.addClass('bg-info')

AutocompleteAssociationsForm.setup()
