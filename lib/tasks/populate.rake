task :populate => :environment do
  ActiveRecord::Base.establish_connection 'fixture'
  class Post < ActiveRecord::Base
  end
  class Comment < ActiveRecord::Base
    belongs_to :commentable, :polymorphic => true
    belongs_to :user
  end
  class User < ActiveRecord::Base
  end
  [User, Comment, Post].each(&:delete_all)
  User.populate 80 do |user|
    user.pseudo Faker::Name.name
    user.first_name Faker::Name.first_name
    user.last_name Faker::Name.last_name
  end
  Post.populate 100 do |post|
    post.title = Faker::Lorem.sentence
    post.author = Faker::Name.name
    post.body = Faker::Lorem.paragraphs
  end
  Comment.populate 50 do |comment|
    comment.title = Faker::Lorem.sentence
    comment.comment = Faker::Lorem.paragraphs
  end
  Comment.find_each do |comment|
    comment.commentable = if [true, false].sample
      User.order('random()').first
    else
      Post.order('random()').first
    end
    comment.user = User.order('random()').first
    comment.save
  end
end
