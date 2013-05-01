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
  
  test "missing db url page" do
    login
    visit missing_db_url_docs_path
  end
  
end