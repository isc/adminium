makeSortable = (selector) ->
  return unless (table = $(selector)).length
  table.on 'click', 'th', (e) ->
    order = $(e.currentTarget).data('order') or 'desc'
    orderMul = if order is 'desc' then -1 else 1
    $(e.currentTarget).data('order', if order is 'desc' then 'asc' else 'desc')
    index = $(e.currentTarget).prevAll().length
    rows = (tr.cloneNode(true) for tr in table.find('tbody tr'))
    rows.sort (e1, e2) ->
      [td1, td2] = [$(e1).find('td').eq(index), $(e2).find('td').eq(index)]
      if index is 1
        [v1, v2] = [td1.text(), td2.text()]
      else
        [v1, v2] = [Number(td1.data('value')), Number(td2.data('value'))]
      if v1 > v2
        -1 * orderMul
      else
        1 * orderMul
    table.find('tbody').empty()
    table.find('tbody').get(0).appendChild(row) for row in rows

$ -> makeSortable '.sor'