const makeSortable = (selector) => {
  const table = $(selector)
  if (!table.length) return
  table.on('click', 'th', (e) => {
    order = $(e.currentTarget).data('order') || 'desc'
    orderMul = order === 'desc' ? -1 : 1
    $(e.currentTarget).data('order', order === 'desc' ? 'asc' : 'desc')
    index = $(e.currentTarget).prevAll().length
    const rows = table.find('tbody tr').map((_, tr) => tr.cloneNode(true))
    rows.sort((e1, e2) => {
      const td1 = $(e1).find('td').eq(index)
      const td2 = $(e2).find('td').eq(index)
      const v1 = index === 1 ? td1.text() : Number(td1.data('value'))
      const v2 = index === 1 ? td2.text() : Number(td2.data('value'))
      return v1 > v2 ? -1 * orderMul : 1 * orderMul
    })
    table.find('tbody').empty()
    rows.each((_, row) => table.find('tbody').append(row))
  })
}
$(() => makeSortable('.table-sortable'))
