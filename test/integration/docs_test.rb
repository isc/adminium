require 'test_helper'

class DocsTest < ActionDispatch::IntegrationTest
  test 'landing' do
    visit root_path
  end

  test 'docs index' do
    visit docs_path
  end

  test 'show doc page' do
    visit keyboard_shortcuts_docs_path
  end
end
