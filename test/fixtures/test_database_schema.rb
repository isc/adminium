conn_spec = ActiveRecord::Base.configurations['fixture']
ActiveRecord::Base.establish_connection conn_spec
ActiveRecord::Schema.verbose = false
version = 11
if ActiveRecord::Migrator.current_version != version
  ActiveRecord::Base.connection.tables.each do |table|
    ActiveRecord::Base.connection.drop_table table
  end
  ActiveRecord::Schema.define(:version => version) do
    create_table :users do |t|
      t.string :pseudo, :first_name, :last_name
      t.integer :group_id, :age
      t.datetime :activated_at
      t.boolean :admin
      t.integer :user_profile_id
      t.date :birthdate
      t.timestamps
    end
    create_table :groups do |t|
      t.string :name
      t.timestamps
    end
    create_table :comments do |t|
      t.string :title, :default => ""
      t.text :comment
      t.references :commentable, :polymorphic => true
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
end


# load some models

class UserFromTest < ActiveRecord::Base
    self.table_name = 'users'
  end
class CommentFromTest < ActiveRecord::Base
  self.table_name = 'comments'
end

ActiveRecord::Base.establish_connection ActiveRecord::Base.configurations[Rails.env]