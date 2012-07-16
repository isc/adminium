jQuery ->
  # $(".alert-message").alert()
  # $(".tabs").button()
  # $(".carousel").carousel()
  # $(".dropdown-toggle").dropdown()
  # $(".tab").tab "show"
  # $(".tooltip").tooltip()
  # $(".typeahead").typeahead()
  $('span[rel=tooltip], button[rel=tooltip], a[rel*=tooltip]').tooltip()
  $("a.text-more, span.text-more").popover()
  $('.datepicker').datepicker onClose: (dateText, inst) ->
    $("##{inst.id}_1i").val(inst.selectedYear)
    $("##{inst.id}_2i").val(inst.selectedMonth + 1)
    $("##{inst.id}_3i").val(inst.selectedDay)
  sh_highlightDocument()
  $('form.simple_form textarea').wysihtml5 html: true, parserRules: {
              tags: {
                  "b":  {},
                  "i":  {},
                  "br": {},
                  "ol": {},
                  "ul": {},
                  "li": {},
                  "h1": {},
                  "h2": {},
                  "h3": {},
                  "h4": {},
                  "blockquote": {},
                  "u": 1,
                  "img": {
                      "check_attributes": {
                          "width": "numbers",
                          "alt": "alt",
                          "src": "url",
                          "height": "numbers"
                      }
                  },
                  "a":  {
                      set_attributes: {
                          # target: "_blank",
                          # rel:    "nofollow"
                      },
                      check_attributes: {
                          href:   "url" # important to avoid XSS
                      }
                  }
              }
          }