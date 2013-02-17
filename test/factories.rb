conn_spec = ActiveRecord::Base.configurations['fixture']

FactoryGirl.define do
  factory :account do
    owner_email 'john.doe@email.com'
    db_url "#{conn_spec['adapter']}://#{conn_spec['username']}@#{conn_spec['host']}/#{conn_spec['database']}"
  end

  factory :user_from_test do
    pseudo 'Michel'
  end

  factory :comment_from_test do
    title "My Comment"
    association :user, factory: :user_from_test
  end

end