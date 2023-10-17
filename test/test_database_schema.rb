test_adapter = ENV['adapter'] || ENV['ADAPTER'] || 'postgres'
Rails.configuration.test_database_conn_spec =
  if ENV['CI']
    ActiveRecord::Base.connection.execute 'create database "adminium-fixture"'
    conn_spec = ENV['DATABASE_URL'].split('/')
    conn_spec[-1] = 'adminium-fixture'
    conn_spec.join('/')
  else
    conn_spec = ActiveRecord::Base.configurations.find_db_config("fixture-#{test_adapter}").configuration_hash
    "#{conn_spec[:adapter]}://#{conn_spec[:username]}@#{conn_spec[:host]}/#{conn_spec[:database]}"
  end

ActiveRecord::Base.establish_connection Rails.configuration.test_database_conn_spec
ActiveRecord::Schema.verbose = false
ActiveRecord::Base.connection.tables.each { |table| ActiveRecord::Base.connection.drop_table table }

ActiveRecord::Schema.define(version: 30) do
  enable_extension :hstore
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
    t.string :time_zone
    t.binary :file
    t.decimal :Average_Price_Online__c
    t.boolean :Awesome_Person__c
    t.time :daily_alarm
    t.uuid :token
    t.column :nicknames, 'character varying[]'
    t.timestamps null: true
  end
  create_table :groups do |t|
    t.string :name
    t.integer :level, null: false
    t.timestamps null: true
  end
  create_table :documents do |t|
    t.datetime :created_at
    t.datetime :updated_at

    t.date :start_date, :end_date, :delete_on
    t.text :description
    t.datetime :some_datetime
    t.string :alpha_2, :alpha_3, :file
    t.integer :range_1, :range_2
    t.boolean :digital
    t.hstore :metadata
  end
  create_table :comments do |t|
    t.string :title, default: ''
    t.text :comment
    t.references :commentable, polymorphic: true
    t.references :user
    t.timestamps null: true
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
    t.timestamps null: true
    t.jsonb :metadata
  end
  create_table :roles_users, id: false do |t|
    t.references :role
    t.references :user
  end
  create_table :uploaded_files do |t|
    t.string :filename
    t.binary :data
  end
end

class UserFromTest < ApplicationRecord
  self.table_name = 'users'
end
class CommentFromTest < ApplicationRecord
  self.table_name = 'comments'
end
class GroupFromTest < ApplicationRecord
  self.table_name = 'groups'
end
class RoleFromTest < ApplicationRecord
  self.table_name = 'roles'
end
class RoleUserFromTest < ApplicationRecord
  self.table_name = 'roles_users'
end
class DocumentFromTest < ApplicationRecord
  self.table_name = 'documents'
end
class UploadedFileFromTest < ApplicationRecord
  self.table_name = 'uploaded_files'
end

ActiveRecord::Base.establish_connection ActiveRecord::Base.configurations.find_db_config(Rails.env)
