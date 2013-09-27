conn_spec = ActiveRecord::Base.configurations["fixture-#{TEST_ADAPTER}"]
ActiveRecord::Base.establish_connection conn_spec
ActiveRecord::Schema.verbose = false
version = 24
# if ActiveRecord::Migrator.current_version != version
  ActiveRecord::Base.connection.tables.each do |table|
    ActiveRecord::Base.connection.drop_table table
  end
  ActiveRecord::Schema.define(:version => version) do
    create_table :users do |t|
      t.string :pseudo, :first_name, :last_name
      t.integer :group_id, :age
      t.datetime :activated_at
      t.column :column_with_time_zone, 'timestamp with time zone'
      t.boolean :admin
      t.string :role
      t.integer :kind, default: 37
      t.integer :user_profile_id
      t.date :birthdate
      t.string :time_zone, :country
      t.binary :file
      t.decimal :Average_Price_Online__c
      t.boolean :Awesome_Person__c
      t.time :daily_alarm
      t.column :nicknames, 'character varying[]'
      t.timestamps
    end
    create_table :groups do |t|
      t.string :name
      t.integer :level, null: false
      t.timestamps
    end
    create_table :documents do |t|
      t.datetime :created_at
      t.datetime :updated_at

      t.date :start_date, :end_date, :delete_on
      t.text :description
      t.datetime :some_datetime
      t.string :alpha_2, :alpha_2, :file
      t.integer :range_1, :range_2
      t.boolean :digital
    end
    create_table :comments do |t|
      t.string :title, :default => ""
      t.text :comment
      t.references :commentable, polymorphic: true
      t.references :user
      t.timestamps
    end
    create_table :user_profiles do |t|
      t.date :birthdate
      t.string :email
    end
    create_table :posts do |t|
      t.string :title, :author
      t.text :body
    end
    create_table :roles do |t|
      t.string :name
      t.timestamps
    end
    create_table :roles_users, id: false do |t|
      t.references :role
      t.references :user
    end
  end
# end


# load some models

class UserFromTest < ActiveRecord::Base
  self.table_name = 'users'
end
class CommentFromTest < ActiveRecord::Base
  self.table_name = 'comments'
end
class GroupFromTest < ActiveRecord::Base
  self.table_name = 'groups'
end
class RoleFromTest < ActiveRecord::Base
  self.table_name = 'roles'
end
class RoleUserFromTest < ActiveRecord::Base
  self.table_name = 'roles_users'
end

ActiveRecord::Base.establish_connection ActiveRecord::Base.configurations[Rails.env]