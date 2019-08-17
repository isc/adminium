require 'test_helper'

class DocsTest < ActionDispatch::IntegrationTest
  test 'browsing landing and documentation page' do
    visit root_path
    save_screenshot 'landing_page'
    click_link 'the docs'
    save_screenshot 'documentation_index'
  end

  test 'show doc page' do
    visit keyboard_shortcuts_docs_path
  end
end
