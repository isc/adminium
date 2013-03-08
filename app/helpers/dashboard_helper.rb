module DashboardHelper

  def display_a_tip
    tip = ['welcome', 'basic_search', 'editing', 'enumerable', 'export_import', 'displayed_record', 'advanced_search', 'serialized', 'relationships'].last
    content_for :tip do
      render partial: "/docs/tips/#{tip}"
    end
    @small_title = true
    render partial: 'displayed_tip'
  end

  def tip_title title
    @tip_title = title
  end

end