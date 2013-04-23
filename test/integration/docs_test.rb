require 'test_helper'

class DocsTest < ActionDispatch::IntegrationTest
  
  test "homepage" do
    visit root_path
  end
  
  test "docs index" do
    visit docs_path
  end
  
  test "show doc page" do
    visit doc_path(:keyboard_shortcuts)
  end
  
end