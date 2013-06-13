# encoding: UTF-8
require 'test_helper'

class ResourcesTest < ActionDispatch::IntegrationTest
  
  def setup
    FixtureFactory.clear_db
    @account = login
  end
  
  test "index on non existing table" do
    visit resources_path(:shablagoos)
    assert_equal dashboard_path, page.current_path
    assert page.has_content?("The table shablagoos cannot be found.")
  end
  
  test "index on resources for users table" do
    FixtureFactory.new :user
    visit resources_path(:users)
    assert page.has_css?('table.items-list')
    assert page.has_css?('th a', text: 'First name')
    uncheck 'First name'
    click_button 'Save settings'
    assert !page.has_css?('th a', text: 'First name')
  end
  
  test "index for users table asking for a page too far" do
    FixtureFactory.new :user
    visit resources_path(:users, page: 37)
    assert page.has_content?("You are looking for results on page 37, but your query only has 1 result page")
  end
  
  test "sorted index by column asc and desc" do
    FixtureFactory.new(:user, pseudo: 'Alberto' )
    FixtureFactory.new(:user, pseudo: 'Zoé' )
    visit resources_path(:users)
    find('a[title="Sort by Pseudo A &rarr; Z"]').click
    assert_equal 'Zoé', find(".items-list tr:nth-child(2) td[data-column-name=pseudo]").text
    find('a[title="Sort by Pseudo Z &rarr; A"]').click
    assert_equal 'Alberto', find(".items-list tr:nth-child(2) td[data-column-name=pseudo]").text
  end
  
  test "search a string in columns" do
    FixtureFactory.new(:user, first_name: 'Johnny', last_name: 'Haliday', role: 'singer')
    FixtureFactory.new(:user, first_name: 'Mariah', last_name: 'Carey', role: 'singer')
    FixtureFactory.new(:user, first_name: 'Johnny', last_name: "Deep", role: "actor")
    visit resources_path(:users)
    fill_in 'search_input', with: "Johnny"
    click_button 'search_btn'
    assert page.has_content? 'Haliday'
    assert page.has_content? 'Deep'
    assert page.has_no_content? 'Carey'
    
    fill_in 'search_input', with: "Johnny singer"
    click_button 'search_btn'
    assert page.has_content? 'Haliday'
    assert page.has_no_content? 'Deep'
    assert page.has_no_content? 'Carey'
  end
  
  test "search on integer columns" do
    FixtureFactory.new(:user, first_name: 'Johnny', last_name: 'Haliday', age: 61, group_id: 3)
    FixtureFactory.new(:user, first_name: 'Mariah', last_name: 'Carey', age: 661, group_id: 5)
    visit resources_path(:users)
    fill_in 'search_input', with: "61"
    click_button 'search_btn'
    assert page.has_content? 'Haliday'
    assert page.has_no_content? 'Carey'
    
    visit resources_path(:users, where: {group_id: 5})
    assert page.has_content? 'Carey'
    assert page.has_no_content? 'Haliday'
    fill_in 'search_input', with: '61'
    click_button 'search_btn'
    assert page.has_no_content? 'Carey'
    assert page.has_no_content? 'Haliday'
  end
  
  test "links on index for polymorphic belongs to" do
    user = FixtureFactory.new(:user).factory
    group = FixtureFactory.new(:group).factory
    first = FixtureFactory.new(:comment, commentable_type: 'User', commentable_id: user.id).factory
    second = FixtureFactory.new(:comment, commentable_type: 'Group', commentable_id: group.id).factory
    visit resources_path(:comments)
    assert_equal "User ##{user.id}",
      find("tr[data-item-id=\"#{first.id}\"] a[href=\"#{resource_path :users, user}\"]").text
    assert_equal "Group ##{group.id}",
      find("tr[data-item-id=\"#{second.id}\"] a[href=\"#{resource_path :groups, group}\"]").text
  end
  
  test "link on index for polymorphic belongs to with label column setup" do
    user = FixtureFactory.new(:user, pseudo: 'Ralph').factory
    comment = FixtureFactory.new(:comment, commentable_type: 'User', commentable_id: user.id).factory
    Resource::Base.any_instance.stubs(:label_column).returns 'pseudo'
    visit resources_path(:comments)
    assert_equal 'Ralph',
      find("tr[data-item-id=\"#{comment.id}\"] a[href=\"#{resource_path :users, user}\"]").text
  end
  
  test "creating a comment (polymorphic belongs_to)" do
    visit resources_path(:comments)
    link = find('a[title="Create a new row"]')
    link.click()
    # FIXME not ideal support for polymorphic belongs_to in the form at the moment
    assert page.has_css?('input[type=number][name="comments[commentable_id]"]')
  end

  test "save new" do
    visit new_resource_path(:users)
    fill_in 'Pseudo', with: 'Bobulus'
    assert page.has_css?('select[name="users[country]"]')
    assert page.has_css?('select[name="users[time_zone]"]')
    click_button 'Save'
    assert page.has_content?('successfully created')
    assert_equal 'Bobulus', find('td[data-column-name=pseudo]').text
  end
  
  test "failed save due to value out of range for db" do
    return if TEST_ADAPTER == 'mysql'
    visit new_resource_path(:users)
    fill_in 'Age', with: '123123123183829384728832'
    click_button 'Save'
    assert page.has_css?('.alert.alert-error')
    assert page.has_content?('New User')
    assert_equal '123123123183829384728832', find('input[type=number][name="users[age]"]').value
  end
  
  test "failed save due to invalid cast" do
    visit new_resource_path(:users)
    fill_in 'Age', with: 'va bien te faire mettre'
    click_button 'Save'
    assert page.has_css?('.alert.alert-error')
    assert page.has_content?('New User')
    assert_equal 'va bien te faire mettre', find('input[type=number][name="users[age]"]').value
  end
  
  test "failed save due to nil value" do
    visit new_resource_path(:groups)
    click_button 'Save'
    assert page.has_css?('.alert.alert-error')
    assert page.has_content?('New Group')
  end

  test "save new and create another" do
    visit new_resource_path(:users)
    fill_in 'Pseudo', with: 'Bobulus'
    click_button 'Save and create another'
    assert page.has_content?("New User")
  end
  
  test "save new and continue editing" do
    visit new_resource_path(:users)
    fill_in 'Pseudo', with: 'Bobulus'
    click_button 'Save and continue editing'
    assert_equal 'Bobulus', find('input[type=text][name="users[pseudo]"]').value
  end

  test "save the date" do
    visit new_resource_path(:documents)
    click_button 'Save'
    assert_equal 'null', find('td[data-column-name=start_date]').text
  end

  test "custom column has_many" do
    user = FixtureFactory.new(:user).factory
    2.times { FixtureFactory.new :comment, user_id: user.id }
    FixtureFactory.new(:user)
    stub_resource_columns listing: [:'has_many/comments']
    visit resources_path(:users)
    assert page.has_css?("tr[data-item-id=\"#{user.id}\"] td.hasmany a", text: '2')
    find('a[title="Sort by Comments count 9 &rarr; 0"]').click
    assert page.has_css?("table.items-list tbody tr:first-child td.hasmany a", text: '2')
  end

  test "custom column belongs_to" do
    FixtureFactory.new(:comment, user_id: FixtureFactory.new(:user, pseudo: 'bob').factory.id)
    stub_resource_columns listing: ['users.pseudo']
    visit resources_path(:comments)
    assert page.has_css?('td', text: 'bob')
  end
  
  test "sort by custom column belongs_to" do
    FixtureFactory.new(:comment, user_id: FixtureFactory.new(:user, pseudo: 'bob').factory.id)
    FixtureFactory.new(:comment, user_id: FixtureFactory.new(:user, pseudo: 'zob').factory.id)
    stub_resource_columns listing: ['users.pseudo']
    Resource::Base.any_instance.stubs(:default_order).returns 'users.pseudo'
    visit resources_path(:comments)
    assert_equal %w(bob zob), page.all('table.items-list tr td:last-child').map(&:text)
    find('a[title="Sort by Users.pseudo Z &rarr; A"]').click
    assert_equal %w(zob bob), page.all('table.items-list tr td:last-child').map(&:text)
  end
  
  test "custom column belongs_to which is a foreign_key to another belongs_to" do
    group = FixtureFactory.new(:group, name: 'Adminators').factory
    FixtureFactory.new(:comment, user_id: FixtureFactory.new(:user, group_id: group.id).factory.id)
    stub_resource_columns listing: ['users.group_id']
    generic = Generic.new @account
    resource = Resource::Base.new generic, :groups
    resource.label_column = 'name'
    resource.save
    generic.cleanup
    visit resources_path(:comments)
    assert_equal 'Adminators', find("td.foreignkey a[href=\"#{resource_path(:groups, group)}\"]").text
  end
  
  test "destroy from show" do
    user = FixtureFactory.new(:user).factory
    visit resource_path(:users, user)
    destroy_url = find("a[data-method=delete]")['href']
    Capybara.current_session.driver.delete destroy_url
    visit Capybara.current_session.driver.response.location
    visit resource_path(:users, user)
    assert_equal resources_path(:users), page.current_path
    assert page.has_content?("does not exist")
  end
  
  test "clone from show" do
    user = FixtureFactory.new(:user, pseudo: "Cloned Boy", age: 5).factory
    visit resource_path(:users, user)
    find("a[title=Clone]").click()
    click_button "Save"
    assert_equal "Cloned Boy", find('td[data-column-name=pseudo]').text
    assert_equal "5", find('td[data-column-name=age]').text
    assert_equal user.id + 1, find('div[data-table=users]')['data-item-id'].to_i
  end
  
  test "update from edit" do
    user = FixtureFactory.new(:user, pseudo: 'Bob', age: 36).factory
    visit edit_resource_path(:users, user)
    assert_equal 'Bob', find('input[type=text][name="users[pseudo]"]').value
    assert_equal '36', find('input[type=number][name="users[age]"]').value
    fill_in 'Pseudo', with: 'Bobulus'
    fill_in 'Age', with: '37'
    click_button 'Save'
    assert_equal 'Bobulus', find('td[data-column-name=pseudo]').text
    assert_equal '37', find('td[data-column-name=age]').text
  end
  
  test "update on composite primary key" do
    role = FixtureFactory.new(:role, name: 'Boss').factory
    noob_role = FixtureFactory.new(:role, name: 'Noob').factory
    user = FixtureFactory.new(:user, pseudo: 'Booob').factory
    role_user = FixtureFactory.new(:role_user, role_id: role.id, user_id: user.id).factory
    visit edit_resource_path(:roles_users, "#{role_user.role_id},#{role_user.user_id}")
    select "Role ##{noob_role.id}"
    click_button 'Save'
    assert_equal resource_path(:roles_users, "#{noob_role.id},#{role_user.user_id}"), current_path
  end
  
  test "failed update" do
    return if TEST_ADAPTER == 'mysql'
    user = FixtureFactory.new(:user).factory
    out_of_range_int = '3241234234141234'
    visit edit_resource_path(:users, user)
    fill_in 'Age', with: out_of_range_int
    click_button 'Save'
    assert page.has_css?('.alert.alert-error')
    assert page.has_content?("Editing User ##{user.id}")
    assert_equal out_of_range_int, find('input[type=number][name="users[age]"]').value
  end
  
  test "validate uniqueness on update" do
    FixtureFactory.new(:user, pseudo: 'Rob')
    user = FixtureFactory.new(:user, pseudo: 'Bob').factory
    Resource::Base.any_instance.stubs(:validations).returns [{'validator' => 'validates_uniqueness_of', 'column_name' => 'pseudo'}]
    visit edit_resource_path(:users, user)
    fill_in 'Pseudo', with: 'Rob'
    click_button 'Save'
    assert_match "Rob has already been taken.", find('.alert.alert-error').text
    fill_in 'Pseudo', with: 'Robert'
    click_button 'Save'
    assert page.has_css?('.alert.alert-success')
  end
  
  test "export rows" do
    FixtureFactory.new(:user, pseudo: "bobleponge")
    visit resources_path(:users)
    click_button 'Export 1 users to csv'
    assert page.has_content?('bobleponge')
  end
  
  test "show with belongs_to association" do
    group = FixtureFactory.new(:group).factory
    user = FixtureFactory.new(:user, group_id: group.id).factory
    visit resource_path(:users, user)
    click_link "Group ##{group.id}"
    assert_equal resource_path(:groups, group), page.current_path
  end
  
  test "show with polymorphic belongs_to association" do
    user = FixtureFactory.new(:user, pseudo: 'Bobby').factory
    comment = FixtureFactory.new(:comment, commentable_id: user.id, commentable_type: 'User').factory
    Resource::Base.any_instance.stubs(:label_column).returns 'pseudo'
    visit resource_path(:comments, comment)
    assert_equal "Bobby", find("a[href=\"#{resource_path :users, user.id}\"]").text
  end
  
  test "show with belongs_to association with label_column set" do
    Resource::Base.any_instance.stubs(:label_column).returns 'name'
    group = FixtureFactory.new(:group, name: 'Admins').factory
    user = FixtureFactory.new(:user, group_id: group.id).factory
    visit resource_path(:users, user)
    click_link 'Admins'
    assert_equal resource_path(:groups, group), page.current_path
  end
  
  test "show with has_many association" do
    group = FixtureFactory.new(:group).factory
    2.times { FixtureFactory.new(:user, group_id: group.id) }
    FixtureFactory.new :user
    visit resource_path(:groups, group)
    click_link 'Create a new associated User'
    assert_equal new_resource_path(:users), page.current_path
    
    visit resource_path(:groups, group)
    click_link '2'
    assert_equal resources_path(:users), page.current_path
    assert page.has_content?('2 records')
  end
  
  test "bulk edit" do
    users = 2.times.map { FixtureFactory.new(:user, age: 34, role: 'Developer', last_name: 'Johnson', kind: 7).factory }
    visit bulk_edit_resources_path(:users, record_ids: users.map(&:id))
    fill_in 'Age', with: '37'
    fill_in 'Role', with: 'CTO'
    click_button 'Update 2 Users'
    visit resources_path(:users)
    users.each do |user|
      assert_equal '37', find("tr[data-item-id=\"#{user.id}\"] td[data-column-name=age]").text
      assert_equal 'CTO', find("tr[data-item-id=\"#{user.id}\"] td[data-column-name=role]").text
      assert_equal 'Johnson', find("tr[data-item-id=\"#{user.id}\"] td[data-column-name=last_name]").text
      assert_equal '7', find("tr[data-item-id=\"#{user.id}\"] td[data-column-name=kind]").text
    end
  end
  
  test "bulk edit on a single resource" do
    user = FixtureFactory.new(:user, age: 34, role: 'Developer').factory
    visit bulk_edit_resources_path(:users, record_ids: [user.id])
    fill_in 'Age', with: '37'
    click_button "Update Users ##{user.id}"
    visit resources_path(:users)
    assert_equal '37', page.find("tr[data-item-id=\"#{user.id}\"] td[data-column-name=age]").text
  end
  
  test "edit and display time and date column" do
    stub_resource_columns form: [:daily_alarm, :birthdate], listing: [:daily_alarm, :birthdate],
      show: [:daily_alarm, :birthdate]
    visit new_resource_path(:users)
    find('#users_daily_alarm_4i').select "08"
    select '37'
    find('#users_birthdate_1i').set '2013'
    find('#users_birthdate_2i').set '5'
    find('#users_birthdate_3i').set '22'
    click_button 'Save'
    assert_equal '08:37', find('td[data-column-name=daily_alarm]').text
    assert_equal 'May 22, 2013', find('td[data-column-name=birthdate]').text
  end
  
  test "update date time column with time zone configuration" do
    @account.update_attributes database_time_zone: 'UTC', application_time_zone: 'Helsinki'
    stub_resource_columns form: [:activated_at], show: [:activated_at]
    user = FixtureFactory.new(:user).factory
    visit edit_resource_path(:users, user.id)
    find('#users_activated_at_1i').set '2013'
    find('#users_activated_at_2i').set '6'
    find('#users_activated_at_3i').set '3'
    find('#users_activated_at_4i').select '22'
    find('#users_activated_at_5i').select '12'
    click_button 'Save'
    assert_equal '2013-06-03 22:12:00', find('td[data-column-name="activated_at"]')['data-raw-value']
  end
  
  test "field with a database default" do
    stub_resource_columns form: [:kind]
    visit new_resource_path(:users)
    assert page.has_css?('input[name="users[kind]"][value="37"]')
  end
  
  test "display of datetime depending on time zone conf" do
    stub_resource_columns listing: [:column_with_time_zone, :activated_at]
    user = FixtureFactory.new(:user).factory
    ActiveRecord::Base.establish_connection ActiveRecord::Base.configurations["fixture-#{TEST_ADAPTER}"]
    ActiveRecord::Base.connection.execute "update users set activated_at = '2012-10-09 05:00:00' where id = #{user.id}"
    ActiveRecord::Base.connection.execute "update users set column_with_time_zone = '2012-10-09 05:00:00 +1000' where id = #{user.id}"
    ActiveRecord::Base.establish_connection ActiveRecord::Base.configurations['test']
    visit resources_path(:users)
    cell = find('td[data-column-name="activated_at"]')
    assert_equal '2012-10-09 05:00:00', cell['data-raw-value']
    assert_equal 'October 09, 2012 05:00', cell.text
    cell = find('td[data-column-name="column_with_time_zone"]')
    assert_equal '2012-10-08 19:00:00', cell['data-raw-value']
    assert_equal 'October 08, 2012 19:00', cell.text
    @account.update_attributes database_time_zone: 'Hawaii', application_time_zone: 'Berlin'
    visit resources_path(:users)
    cell = find('td[data-column-name="activated_at"]')
    assert_equal '2012-10-09 17:00:00', cell['data-raw-value']
    cell = find('td[data-column-name="column_with_time_zone"]')
    assert_equal '2012-10-08 21:00:00', cell['data-raw-value']
  end
  
  test "edit and update a pg array column" do
    stub_resource_columns form: [:nicknames], show: [:nicknames]
    user = FixtureFactory.new(:user).factory
    visit edit_resource_path(:users, user.id)
    fill_in 'Nicknames', with: '["Bob" "Bobby"]'
    click_button 'Save'
    assert page.has_css?('.alert.alert-error')
    fill_in 'Nicknames', with: '["Bob", "Bobby"]'
    click_button 'Save'
    assert !page.has_css?('.alert.alert-error')
    assert_equal '["Bob", "Bobby"]', find('td[data-column-name="nicknames"]')['data-raw-value']
  end
  
  test "search on a string array column" do
    stub_resource_columns listing: [:nicknames, :pseudo], search: [:nicknames]
    FixtureFactory.new(:user, nicknames: "{Bob, Bobby, Bobulus}", pseudo: 'Pierre')
    FixtureFactory.new(:user, nicknames: "{Bob, Rob}", pseudo: 'Jacques')
    visit resources_path(:users)
    assert page.has_content?('Pierre')
    assert page.has_content?('Jacques')
    fill_in 'search_input', with: 'Bobulus'
    click_button 'search_btn'
    assert page.has_content?('Pierre')
    assert page.has_no_content?('Jacques')
    fill_in 'search_input', with: 'Bob Bobby'
    click_button 'search_btn'
    assert page.has_content?('Pierre')
    assert page.has_no_content?('Jacques')
  end
  
  def stub_resource_columns value
    [:serialized, :show, :form, :listing, :search].each do |key|
      value[key] = [] unless value.has_key? key
    end
    Resource::Base.any_instance.stubs(:columns).returns value
  end

end
