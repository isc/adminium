task :populate => :environment do
  ActiveRecord::Base.establish_connection 'fixture'
  class Post < ActiveRecord::Base
  end
  Post.populate 100 do |post|
    post.title = Faker::Lorem.sentence
    post.author = Faker::Name.name
    post.body = Faker::Lorem.paragraphs
  end
end
