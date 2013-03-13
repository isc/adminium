$ ->
  # $(".alert-message").alert()
  # $(".tabs").button()
  # $(".carousel").carousel()
  # $(".dropdown-toggle").dropdown()
  # $(".tab").tab "show"
  # $(".tooltip").tooltip()
  # $(".typeahead").typeahead()
  $('span[rel=tooltip], button[rel=tooltip], a[rel*=tooltip], i[rel=tooltip]').tooltip()
  $("a.text-more, span.text-more, i.text-more").popover()
  $('.datepicker').datepicker
    weekHeader: "Week"
    showWeek: true
    altField: $("#generic_account_4_document_range_1")
    onSelect: (dateText, inst) ->
      $("##{inst.id}_1i").val(inst.selectedYear)
      $("##{inst.id}_2i").val(inst.selectedMonth + 1)
      $("##{inst.id}_3i").val(inst.selectedDay)
  sh_highlightDocument()
  tags = ["a", "abbr", "acronym", "address", "applet", "area", "article", "aside", "audio", "b", "base", "basefont", "bdi", "bdo", "bgsound", "big", "blink", "blockquote", "body", "br", "button", "canvas", "caption", "center", "cite", "code", "col", "colgroup", "command", "data", "datalist", "dd", "del", "details", "dfn", "dir", "div", "dl", "dt", "em", "embed", "fieldset", "figcaption", "figure", "font", "footer", "form", "frame", "frameset", "h1", "h2", "h3", "h4", "h5", "h6", "head", "header", "hgroup", "hr", "html", "i", "iframe", "img", "input", "ins", "isindex", "kbd", "keygen", "label", "legend", "li", "link", "listing", "main", "map", "mark", "marquee", "menu", "meta", "meter", "nav", "nobr", "noframes", "noscript", "object", "ol", "optgroup", "option", "output", "p", "param", "plaintext", "pre", "progress", "q", "rp", "rt", "ruby", "s", "samp", "script", "section", "select", "small", "source", "spacer", "span", "strike", "strong", "style", "sub", "summary", "sup", "table", "tbody", "td", "textarea", "tfoot", "th", "thead", "time", "title", "tr", "track", "tt", "u", "ul", "var", "video", "wbr", "xmp"]
  parserRules = {tags: {}}
  parserRules.tags[tag] = {} for tag in tags
  $('form.simple_form textarea').wysihtml5 html: true, parserRules: parserRules
