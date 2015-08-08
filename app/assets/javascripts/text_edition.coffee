class TextEdition
  
  constructor: ->
    @pref = localStorage.getItem('text_edition_preference') || 'rich_text_editor'
    @applyPreference()
    $(document).on 'click', '.text-edition-switch', @switchEditionPreference
  
  applyPreference: ->
    if @pref is 'rich_text_editor'
      @enableRichTextEditor()
    else
      @disableRichTextEditor()
    @addSwitchingLinks()
  
  enableRichTextEditor: ->
    parserRules = {tags: {}}
    parserRules.tags[tag] = {check_attributes: {}} for tag in @fullTagList
    parserRules.tags['a'].check_attributes = {href: 'url', target: 'alt'}
    $('form.resource-form textarea').wysihtml5 html: true, parserRules: parserRules
  
  disableRichTextEditor: ->
    $("iframe.wysihtml5-sandbox, input[name='_wysihtml5_mode']").remove()
    $("body").removeClass("wysihtml5-supported")
    $('.wysihtml5-toolbar').remove()
    $('form.resource-form textarea').css('display', 'block')
  
  addSwitchingLinks: ->
    $('.text-edition-switch').remove()
    text = if @pref is 'rich_text_editor' then '<i class="fa fa-exchange"></i> Plain text area' else '<i class="fa fa-exchange"></i> Rich text editor'
    for textarea in $('form.resource-form textarea')
      $('<a />').html(text).attr('href', '#').insertAfter($(textarea).parent()).addClass('text-edition-switch')
  
  switchEditionPreference: =>
    @pref = if @pref is 'rich_text_editor' then 'plain_text_area' else 'rich_text_editor'
    localStorage.setItem 'text_edition_preference', @pref
    @applyPreference()
    
  
  fullTagList: ["a", "abbr", "acronym", "address", "applet", "area", "article", "aside", "audio", "b", "base", "basefont", "bdi", "bdo", "bgsound", "big", "blink", "blockquote", "body", "br", "button", "canvas", "caption", "center", "cite", "code", "col", "colgroup", "command", "data", "datalist", "dd", "del", "details", "dfn", "dir", "div", "dl", "dt", "em", "embed", "fieldset", "figcaption", "figure", "font", "footer", "form", "frame", "frameset", "h1", "h2", "h3", "h4", "h5", "h6", "head", "header", "hgroup", "hr", "html", "i", "iframe", "img", "input", "ins", "isindex", "kbd", "keygen", "label", "legend", "li", "link", "listing", "main", "map", "mark", "marquee", "menu", "meta", "meter", "nav", "nobr", "noframes", "noscript", "object", "ol", "optgroup", "option", "output", "p", "param", "plaintext", "pre", "progress", "q", "rp", "rt", "ruby", "s", "samp", "script", "section", "select", "small", "source", "spacer", "span", "strike", "strong", "style", "sub", "summary", "sup", "table", "tbody", "td", "textarea", "tfoot", "th", "thead", "time", "title", "tr", "track", "tt", "u", "ul", "var", "video", "wbr", "xmp"]
  
$ -> new TextEdition()
