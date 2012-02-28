conn_spec = ActiveRecord::Base.configurations['fixture']
ActiveRecord::Base.establish_connection conn_spec
ActiveRecord::Schema.verbose = false
version = 1
if ActiveRecord::Migrator.current_version != version
  db_name = conn_spec['database']
  ActiveRecord::Base.connection.drop_database db_name
  ActiveRecord::Base.connection.create_database db_name
  ActiveRecord::Schema.define(:version => version) do
    create_table :users do |t|
      t.string :pseudo, :first_name, :last_name
      t.integer :group_id, :age
      t.datetime :activated_at
      t.boolean :admin
      t.integer :user_profile_id
      t.timestamps
    end
    create_table :groups do |t|
      t.string :name
      t.timestamps
    end
    create_table :comments do |t|
      t.string :body
      t.integer :user_id, :post_id
      t.boolean :published
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
  end
end
ActiveRecord::Base.establish_connection ActiveRecord::Base.configurations[Rails.env]