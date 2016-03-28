module DashboardHelper
  def display_a_tip
    tip = current_account.displayed_next_tip
    return unless tip
    content_for :tip do
      render partial: "/docs/tips/#{tip}"
    end
    render partial: 'displayed_tip'
  end

  def tip_title title
    @tip_title = title
  end
end
