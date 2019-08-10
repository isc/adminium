require 'test_helper'

class ResourcesTest < ActionDispatch::IntegrationTest
  def setup
    @account = login
  end

  test 'index on non existing table' do
    visit resources_path(:shablagoos)
    assert_equal dashboard_path, current_path
    assert_text 'The table shablagoos cannot be found.'
  end

  test 'index on resources for users table' do
    FixtureFactory.new :user
    visit resources_path(:users)
    assert_selector 'table.items-list'
    assert_selector 'th a', text: 'First name'
    save_screenshot 'resources_index.png'
    click_link_with_title 'Listing settings'
    open_accordion 'Displayed columns', selector: 'label', text: 'Check / uncheck all'
    within('#listing_columns_list') { uncheck 'First name' }
    save_screenshot 'listing_settings_modal.png'
    click_button 'Save settings'
    assert_no_selector 'th a', text: 'First name'
  end

  test 'index with limited permissions' do
    user = create :user
    role = create :role
    collaborator = create :collaborator, user: user, account: @account, is_administrator: false, roles: [role]
    page.set_rack_session user: user.id, collaborator: collaborator.id
    visit resources_path(:users)
    assert_text "You haven't the permission to perform index on users"
    role.update permissions: {'users' => {'read' => '1'}}
    visit resources_path(:users)
    assert_text 'No records were found.'
  end

  test 'index for users table asking for a page too far' do
    FixtureFactory.new :user
    visit resources_path(:users, page: 37)
    assert_text 'You are looking for results on page 37, but your query only has 1 result page'
  end

  test 'sorted index by column asc and desc' do
    FixtureFactory.new(:user, pseudo: 'Alberto')
    FixtureFactory.new(:user, pseudo: 'Zoé')
    visit resources_path(:users)
    first('a[title="Sort by Pseudo A → Z"]').click
    assert_equal 'Zoé', find('.items-list tr:nth-child(2) td[data-column-name=pseudo]').text
    first('a[title="Sort by Pseudo Z → A"]').click
    assert_equal 'Alberto', find('.items-list tr:nth-child(2) td[data-column-name=pseudo]').text
  end

  test 'search a string in columns' do
    FixtureFactory.new(:user, first_name: 'Johnny', last_name: 'Haliday', role: 'singer')
    FixtureFactory.new(:user, first_name: 'Mariah', last_name: 'Carey', role: 'singer')
    FixtureFactory.new(:user, first_name: 'Johnny', last_name: 'Deep', role: 'actor')
    visit resources_path(:users)
    fill_in 'search_input', with: 'Johnny'
    find('form.navbar-left button').click
    assert_text 'Haliday'
    assert_text 'Deep'
    assert_no_text 'Carey'
    save_screenshot 'resources_index_with_search.png'

    fill_in 'search_input', with: 'Johnny singer'
    find('form.navbar-left button').click
    assert_text 'Haliday'
    assert_no_text 'Deep'
    assert_no_text 'Carey'
  end

  test 'search on integer columns' do
    FixtureFactory.new(:user, first_name: 'Johnny', last_name: 'Haliday', age: 61, group_id: 3)
    FixtureFactory.new(:user, first_name: 'Mariah', last_name: 'Carey', age: 661, group_id: 5)
    visit resources_path(:users)
    fill_in 'search_input', with: '61'
    find('form.navbar-left button').click
    assert_text 'Haliday'
    assert_no_text 'Carey'

    visit resources_path(:users, where: {group_id: 5})
    assert_text 'Carey'
    assert_no_text 'Haliday'
    fill_in 'search_input', with: '61'
    find('form.navbar-left button').click
    assert_no_text 'Carey'
    assert_no_text 'Haliday'
    find('.alert-info .close').click
    assert_text 'Carey'
    assert_no_text 'Haliday'
  end

  test 'search with where on a range date weekly' do
    somedate = 10.weeks.ago
    FixtureFactory.new(:user, first_name: 'Johnny', activated_at: somedate)
    FixtureFactory.new(:user, first_name: 'Mariah', activated_at: somedate + 1.week)
    FixtureFactory.new(:user, first_name: 'Gilles', activated_at: somedate - 1.week)
    visit resources_path(:users, where: {activated_at: somedate.beginning_of_week}, grouping: 'weekly')
    assert_text 'Where weekly activated_at is'
    assert_text '1 record'
    assert_text 'Johnny'
    first('a[title="Sort by Last name A → Z"]').click
    assert_text 'Where weekly activated_at is' # grouping param is conserved when changing order
  end

  test 'where on a full date' do
    FixtureFactory.new(:user, first_name: 'Johnny', activated_at: '2016-06-17 13:47:01')
    visit resources_path(:users, where: {activated_at: '2016-06-17 13:47:01'})
    assert_text '1 record'
  end

  test 'exclude clause' do
    FixtureFactory.new(:user, first_name: 'Johnny', last_name: 'Haliday', age: 61, group_id: 3)
    FixtureFactory.new(:user, first_name: 'Mariah', last_name: 'Carey', age: 661, group_id: 5)
    visit resources_path(:users, exclude: {group_id: 3})
    assert_text 'Mariah'
    assert_no_text 'Johnny'
    assert_text 'Where group_id is not 3'
    visit resources_path(:users, exclude: {group_id: 3, first_name: 'Mariah'})
    assert_text 'No records were found.'
    visit resources_path(:users, exclude: {created_at: 'null'})
    assert_text 'Mariah'
  end

  test 'links on index for polymorphic belongs to' do
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

  test 'link on index for polymorphic belongs to with label column setup' do
    user = FixtureFactory.new(:user, pseudo: 'Ralph').factory
    comment = FixtureFactory.new(:comment, commentable_type: 'User', commentable_id: user.id).factory
    Resource.any_instance.stubs(:label_column).returns 'pseudo'
    visit resources_path(:comments)
    assert_equal 'Ralph',
      find("tr[data-item-id=\"#{comment.id}\"] a[href=\"#{resource_path :users, user}\"]").text
  end

  test 'creating a comment (polymorphic belongs_to)' do
    visit resources_path(:comments)
    click_link_with_title 'Create a new row'
    # FIXME: not ideal support for polymorphic belongs_to in the form at the moment
    assert_selector 'input[type=number][name="comments[commentable_id]"]'
    save_screenshot 'resources_new.png'
  end

  test 'save new' do
    visit new_resource_path(:users)
    fill_in 'Pseudo', with: 'Bobulus'
    assert_selector 'select[name="users[time_zone]"]'
    click_button 'Save'
    assert_text 'successfully created'
    assert_equal 'Bobulus', find('td[data-column-name=pseudo]').text
  end

  test 'failed save due to value out of range for db' do
    visit new_resource_path(:users)
    fill_in 'Age', with: '123123123183829384728832'
    click_button 'Save'
    assert_selector '.alert.alert-danger'
    assert_text 'New User'
    assert has_field?('Age', with: '123123123183829384728832')
    save_screenshot 'resources_update_failed.png'
  end

  test 'failed save due to invalid cast' do
    visit new_resource_path(:users)
    fill_in 'Token', with: '2323'
    click_button 'Save'
    assert_selector '.alert.alert-danger'
    assert_text 'New User'
    assert has_field?('Token', with: '2323')
  end

  test 'failed save due to nil value' do
    visit new_resource_path(:groups)
    execute_script("$('form.resource-form').attr('novalidate', true)")
    click_button 'Save'
    assert_selector '.alert.alert-danger'
    assert_text 'New Group'
  end

  test 'save new and create another' do
    visit new_resource_path(:users)
    fill_in 'Pseudo', with: 'Bobulus'
    click_button 'Save and create another'
    assert_text 'New User'
  end

  test 'save new and continue editing' do
    visit new_resource_path(:users)
    fill_in 'Pseudo', with: 'Bobulus'
    click_button 'Save and continue editing'
    assert_equal 'Bobulus', find('input[type=text][name="users[pseudo]"]').value
  end

  test 'save the date' do
    visit new_resource_path(:documents)
    click_button 'Save'
    assert_equal 'null', find('td[data-column-name=start_date]').text
  end

  test 'custom column has_many' do
    user = FixtureFactory.new(:user).factory
    2.times { FixtureFactory.new :comment, user_id: user.id }
    FixtureFactory.new(:user)
    stub_resource_columns listing: %i(has_many/comments/user_id)
    visit resources_path(:users)
    has_many_comments_path = resources_path(:comments, where: {user_id: user.id})
    assert_selector "tr[data-item-id=\"#{user.id}\"] td.hasmany a[href=\"#{has_many_comments_path}\"]", text: '2'
    find('th[data-column-name="has_many/comments/user_id"]').hover
    click_link 'Sort by Comments count 9 → 0'
    assert_selector 'table.items-list tbody tr:first-child td.hasmany a', text: '2'
  end

  test 'permissions for custom column belongs_to and label column' do
    FixtureFactory.new(:comment, user_id: FixtureFactory.new(:user, pseudo: 'bob', first_name: 'Robert').factory.id)
    stub_resource_columns listing: %i(user_id user_id.pseudo)
    Resource.any_instance.stubs(:label_column).returns 'first_name'
    visit resources_path(:comments)
    assert_selector 'td', text: 'bob'
    assert_selector 'a', text: 'Robert'
    user = create :user
    role = create :role, permissions: {'comments' => {'read' => '1'}, 'users' => {'read' => '1'}}
    collaborator = create :collaborator, user: user, account: @account, is_administrator: false, roles: [role]
    page.set_rack_session user: user.id, collaborator: collaborator.id
    visit resources_path(:comments)
    assert_selector 'td', text: 'bob'
    assert_selector 'a', text: 'Robert'
    role.update permissions: {'comments' => {'read' => '1'}}
    visit resources_path(:comments)
    assert_no_selector 'td', text: 'bob'
    assert_no_selector 'a', text: 'Robert'
  end

  test 'filter by enum label from a custom column' do
    FixtureFactory.new(:comment, title: 'Funny joke', user_id:
      FixtureFactory.new(:user, pseudo: 'InternGuy', role: 'noob').factory.id)
    FixtureFactory.new(:comment, title: 'You are fired', user_id:
      FixtureFactory.new(:user, pseudo: 'BossMan', role: 'admin').factory.id)
    stub_resource_columns listing: %w(title user_id.role)
    Resource.any_instance.stubs(:enum_values_for).returns nil
    Resource.any_instance.stubs(:enum_values_for).with(:role)
      .returns 'admin' => {'label' => 'Chef'}, 'noob' => {'label' => 'Débutant'}
    visit resources_path(:comments)
    assert_text 'Funny joke'
    assert_text 'You are fired'
    assert_selector 'a', text: 'Débutant'
    assert_selector 'a', text: 'Chef'
    click_link 'Chef'
    assert_text 'You are fired'
    assert_no_text 'Funny joke'
  end

  test 'sort by custom column belongs_to' do
    FixtureFactory.new(:comment, user_id: FixtureFactory.new(:user, pseudo: 'bob').factory.id)
    FixtureFactory.new(:comment, user_id: FixtureFactory.new(:user, pseudo: 'zob').factory.id)
    stub_resource_columns listing: %w(user_id.pseudo)
    Resource.any_instance.stubs(:default_order).returns 'user_id.pseudo'
    visit resources_path(:comments)
    assert_equal %w(bob zob), all('table.items-list tr td:last-child').map(&:text)
    first('a[title="Sort by User > Pseudo Z → A"]').click
    assert_equal %w(zob bob), all('table.items-list tr td:last-child').map(&:text)
  end

  test 'custom column belongs_to which is a foreign_key to another belongs_to' do
    group = FixtureFactory.new(:group, name: 'Adminators').factory
    FixtureFactory.new(:comment, user_id: FixtureFactory.new(:user, group_id: group.id).factory.id)
    stub_resource_columns listing: %w(user_id.group_id)
    generic = Generic.new @account
    resource = Resource.new generic, :groups
    resource.label_column = 'name'
    resource.save
    generic.cleanup
    visit resources_path(:comments)
    assert_equal 'Adminators', find("td.foreignkey a[href=\"#{resource_path(:groups, group)}\"]").text
  end

  test 'destroy from show' do
    user = FixtureFactory.new(:user).factory
    visit resource_path(:users, user)
    save_screenshot 'resources_show.png'
    accept_alert { click_link_with_title 'Destroy' }
    assert_selector '.alert-success', text: 'successfully destroyed'
    visit resource_path(:users, user)
    assert_equal resources_path(:users), current_path
    assert_text 'does not exist'
  end

  test 'destroy from index' do
    FixtureFactory.new(:user, pseudo: 'ToDelete').factory
    visit resources_path(:users)
    assert_text 'ToDelete'
    accept_alert { click_link 'Destroy' }
    assert_text 'successfully destroyed'
    assert_no_text 'ToDelete'
  end

  test 'clone from show' do
    user = FixtureFactory.new(:user, pseudo: 'Cloned Boy', age: 5).factory
    visit resource_path(:users, user)
    click_link_with_title 'Clone'
    click_button 'Save'
    assert_equal 'Cloned Boy', find('td[data-column-name=pseudo]').text
    assert_equal '5', find('td[data-column-name=age]').text
    assert_equal user.id + 1, find('div[data-table=users]')['data-item-id'].to_i
  end

  test 'update from edit' do
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

  test 'update on composite primary key' do
    role = FixtureFactory.new(:role, name: 'Boss').factory
    noob_role = FixtureFactory.new(:role, name: 'Noob').factory
    user = FixtureFactory.new(:user, pseudo: 'Booob').factory
    role_user = FixtureFactory.new(:role_user, role_id: role.id, user_id: user.id).factory
    visit edit_resource_path(:roles_users, "#{role_user.role_id},#{role_user.user_id}")
    select "Role ##{noob_role.id}"
    click_button 'Save'
    assert_equal resource_path(:roles_users, "#{noob_role.id},#{role_user.user_id}"), current_path
  end

  test 'failed update' do
    user = FixtureFactory.new(:user).factory
    out_of_range_int = '3241234234141234'
    visit edit_resource_path(:users, user)
    fill_in 'Age', with: out_of_range_int
    click_button 'Save'
    assert_selector '.alert.alert-danger'
    assert_text "Edit User ##{user.id}"
    assert_equal out_of_range_int, find('input[type=number][name="users[age]"]').value
  end

  test 'export rows' do
    FixtureFactory.new(:user, pseudo: 'bobleponge')
    visit resources_path(:users)
    click_link_with_title 'Export rows'
    assert_selector '.modal'
    save_screenshot 'export.png'
    click_button 'Export records to CSV'
    # FIXME: https://collectiveidea.com/blog/archives/2012/01/27/testing-file-downloads-with-capybara-and-chromedriver
    assert_text 'bobleponge'
  end

  test 'show with belongs_to association' do
    group = FixtureFactory.new(:group).factory
    user = FixtureFactory.new(:user, group_id: group.id).factory
    visit resource_path(:users, user)
    click_link "Group ##{group.id}"
    assert_equal resource_path(:groups, group), current_path
  end

  test 'show with polymorphic belongs_to association' do
    user = FixtureFactory.new(:user, pseudo: 'Bobby').factory
    comment = FixtureFactory.new(:comment, commentable_id: user.id, commentable_type: 'User').factory
    Resource.any_instance.stubs(:label_column).returns 'pseudo'
    visit resource_path(:comments, comment)
    assert_equal 'Bobby', find("a[href=\"#{resource_path :users, user.id}\"]").text
  end

  test 'show with belongs_to association with label_column set' do
    Resource.any_instance.stubs(:label_column).returns 'name'
    group = FixtureFactory.new(:group, name: 'Admins').factory
    user = FixtureFactory.new(:user, group_id: group.id).factory
    visit resource_path(:users, user)
    click_link 'Admins'
    assert_equal resource_path(:groups, group), current_path
  end

  test 'show with has_many association' do
    group = FixtureFactory.new(:group).factory
    2.times { FixtureFactory.new(:user, group_id: group.id) }
    FixtureFactory.new :user
    visit resource_path(:groups, group)
    click_link_with_title 'Create a new associated User'
    assert_equal new_resource_path(:users), current_path

    visit resource_path(:groups, group)
    click_link '2'
    assert_equal resources_path(:users), current_path
    assert_text '2 records'
  end

  test 'polymorphic has many association' do
    document = FixtureFactory.new(:document).factory
    FixtureFactory.new(:comment, comment: 'ComCom', commentable_id: document.id, commentable_type: 'Document').factory
    visit resource_path(:documents, document)
    click_link_with_title 'Show settings'
    open_accordion 'Polymorphic associations', selector: 'label', text: 'comments as commentable'
    check 'comments as commentable'
    click_button 'Save settings'
    click_link '1'
    assert_text 'ComCom'
    assert_text 'Where commentable_type is Document'
  end

  test 'bulk edit' do
    users = Array.new(2) {FixtureFactory.new(:user, age: 34, role: 'Developer', last_name: 'Johnson', kind: 7).factory}
    visit bulk_edit_resources_path(:users, record_ids: users.map(&:id))
    fill_in 'Age', with: '37'
    fill_in 'Role', with: 'CTO'
    click_button 'Update 2 Users'
    assert_text 'Bulk Edit'
    visit resources_path(:users)
    users.each do |user|
      assert_equal '37', find("tr[data-item-id=\"#{user.id}\"] td[data-column-name=age]").text
      assert_equal 'CTO', find("tr[data-item-id=\"#{user.id}\"] td[data-column-name=role]").text
      assert_equal 'Johnson', find("tr[data-item-id=\"#{user.id}\"] td[data-column-name=last_name]").text
      assert_equal '7', find("tr[data-item-id=\"#{user.id}\"] td[data-column-name=kind]").text
    end
  end

  test 'bulk edit on a single resource' do
    user = FixtureFactory.new(:user, age: 34, role: 'Developer').factory
    visit bulk_edit_resources_path(:users, record_ids: [user.id])
    fill_in 'Age', with: '37'
    click_button "Update Users ##{user.id}"
    visit resources_path(:users)
    assert_equal '37', find("tr[data-item-id=\"#{user.id}\"] td[data-column-name=age]").text
  end

  test 'bulk update and nullify settings' do
    # FIXME: add the time_zone to the mix and it gets stuck for 2 or 3 seconds in default_input_type
    stub_resource_columns form: %i(last_name first_name age role), listing: %i(last_name first_name age role)
    names = %w(John Jane)
    Array.new(2) do |i|
      FixtureFactory.new(:user, age: 34, role: 'Developer', last_name: 'Johnson', first_name: names[i]).factory
    end
    visit resources_path(:users)
    assert_text 'Johnson', count: 2
    find('thead input[type=checkbox]').click
    click_link_with_title 'Edit selected rows'
    fill_in 'Age', with: 55
    all('.empty_string_btn')[0].click # click on empty string button for last name column
    all('.null_btn')[2].click # click null button for role column
    find_field('Last name').click # to avoid having the tooltips in the screenshot
    assert_no_selector '.tooltip'
    save_screenshot 'resources_bulk_edit.png'
    click_on 'Update 2 Users'
    assert_no_text 'Johnson'
    assert_selector 'td[data-column-name="role"]', text: 'null'
    assert_selector 'td[data-column-name="last_name"]', text: 'empty string'
    assert_text 'John'
    assert_text 'Jane'
  end

  test 'edit and display time and date column' do
    stub_resource_columns form: %i(daily_alarm birthdate), listing: %i(daily_alarm birthdate),
                          show: %i(daily_alarm birthdate)
    visit new_resource_path(:users)
    find('#users_daily_alarm_4i').select '08'
    select '37'
    find('#users_birthdate').set '5/5/2013'
    click_button 'Save'
    assert_equal '08:37', find('td[data-column-name=daily_alarm]').text
    assert_equal 'May 05, 2013', find('td[data-column-name=birthdate]').text
  end

  test 'update date time column with time zone configuration' do
    @account.update database_time_zone: 'UTC', application_time_zone: 'Helsinki'
    stub_resource_columns form: [:activated_at], show: [:activated_at]
    user = FixtureFactory.new(:user).factory
    visit edit_resource_path(:users, user.id)
    fill_in 'Activated at', with: '01/01/2013'
    find('#users_activated_at_4i').select '22'
    find('#users_activated_at_5i').select '12'
    click_button 'Save'
    assert_equal '2013-01-01 22:12:00', find('td[data-column-name="activated_at"]')['data-raw-value']
  end

  test 'field with a database default' do
    stub_resource_columns form: [:kind]
    visit new_resource_path(:users)
    assert_selector 'input[name="users[kind]"][value="37"]'
  end

  test 'display of datetime depending on time zone conf' do
    stub_resource_columns listing: %i(column_with_time_zone activated_at)
    user = FixtureFactory.new(:user).factory
    ActiveRecord::Base.establish_connection Rails.configuration.test_database_conn_spec
    ActiveRecord::Base.connection.execute "update users set activated_at = '2012-10-09 05:00:00' where id = #{user.id}"
    ActiveRecord::Base.connection.execute(
      "update users set column_with_time_zone = '2012-10-09 05:00:00 +1000' where id = #{user.id}"
    )
    ActiveRecord::Base.establish_connection ActiveRecord::Base.configurations['test']
    visit resources_path(:users)
    cell = find('td[data-column-name="activated_at"]')
    assert_equal '2012-10-09 05:00:00', cell['data-raw-value']
    assert_equal 'October 09, 2012 05:00', cell.text
    cell = find('td[data-column-name="column_with_time_zone"]')
    assert_equal '2012-10-08 19:00:00', cell['data-raw-value']
    assert_equal 'October 08, 2012 19:00', cell.text
    @account.update database_time_zone: 'Hawaii', application_time_zone: 'Berlin'
    visit resources_path(:users)
    cell = find('td[data-column-name="activated_at"]')
    assert_equal '2012-10-09 17:00:00', cell['data-raw-value']
    cell = find('td[data-column-name="column_with_time_zone"]')
    assert_equal '2012-10-08 21:00:00', cell['data-raw-value']
  end

  test 'edit and update a pg array column' do
    stub_resource_columns form: [:nicknames], show: [:nicknames]
    user = FixtureFactory.new(:user).factory
    visit edit_resource_path(:users, user.id)
    click_link 'Plain text area'
    fill_in 'Nicknames', with: '["Bob" "Bobby"]'
    click_button 'Save'
    assert_selector '.alert.alert-danger'
    fill_in 'Nicknames', with: '["Bob", "Bobby"]'
    click_button 'Save'
    assert_no_selector '.alert.alert-danger'
    assert_equal '["Bob", "Bobby"]', find('td[data-column-name="nicknames"]')['data-raw-value']
    click_link_with_title 'Edit'
    click_on 'Rich text editor'
    assert_text 'Plain text area'
  end

  test 'date fields with default' do
    generic = Generic.new @account
    generic.db.alter_table(:documents) do
      set_column_default :some_datetime, Sequel::CURRENT_TIMESTAMP
      set_column_default :delete_on, Sequel::CURRENT_DATE
    end
    visit new_resource_path(:documents)
    v = Date.current.to_s
    assert_equal v, find('input#documents_delete_on').value
    assert_equal v, find('input#documents_some_datetime').value
    generic.cleanup
  end

  test 'search on a string array column' do
    stub_resource_columns listing: %i(nicknames pseudo), search: %i(nicknames)
    FixtureFactory.new(:user, nicknames: %w(Bob Bobby Bobulus), pseudo: 'Pierre')
    FixtureFactory.new(:user, nicknames: %w(Bob Rob), pseudo: 'Jacques')
    visit resources_path(:users)
    assert_text 'Pierre'
    assert_text 'Jacques'
    fill_in 'search_input', with: 'Bobulus'
    find('form.navbar-left button').click
    assert_text 'Pierre'
    assert_no_text 'Jacques'
    fill_in 'search_input', with: 'Bob Bobby'
    find('form.navbar-left button').click
    assert_text 'Pierre'
    assert_no_text 'Jacques'
  end

  test 'hstore show, edit and update' do
    document = FixtureFactory.new(:document, metadata: {size: 123, path: '/tmp/file.txt'}).factory
    stub_resource_columns form: %i(metadata), show: %i(metadata)
    visit resource_path(:documents, document)
    assert_selector 'th', text: 'path'
    assert_selector 'td', text: '/tmp/file.txt'
    assert_selector 'th', text: 'size'
    assert_selector 'td', text: '123'
    click_link_with_title 'Edit'
    find('input[value="/tmp/file.txt"]').set '/tmp/file.mdown'
    click_button 'Save'
    assert_selector 'td', text: '/tmp/file.mdown'
  end

  test 'link to download for binary column' do
    uploaded_file = FixtureFactory.new(:uploaded_file, filename: 'test.txt', data: 'A' * 37).factory
    visit resources_path(:uploaded_files)
    click_link 'Download (37 Bytes)'
    # FIXME: https://collectiveidea.com/blog/archives/2012/01/27/testing-file-downloads-with-capybara-and-chromedriver
    # assert_equal uploaded_file.data, page.body
    visit resource_path(:uploaded_files, uploaded_file)
    click_link 'Download (37 Bytes)'
    # assert_equal uploaded_file.data, page.body
  end
end
