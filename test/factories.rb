FactoryGirl.define do
  factory :account do
    owner_email 'john.doe@email.com'
    db_url 'postgresql://ivan@localhost/adminium-fixture'
  end
end
