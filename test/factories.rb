FactoryBot.define do
  factory :account do
    owner_email 'john.doe@email.com'
    db_url { $TEST_DATABASE_CONN_SPEC }
    plan Account::Plan::STARTUP
  end

  factory :user do
    email 'john.doe@emai.com'
  end

  factory :collaborator do
    account
    user
    is_administrator true
    email 'blabla@adasd.com'
  end

  factory :role do
    name 'Read only'
  end

  factory :time_chart_widget do
    account
    table :users
    columns :created_at
  end

  factory :table_widget do
    account
    table :users
  end

  factory :search do
    account
    table :users
    conditions []
  end

  factory :user_from_test do
    pseudo 'Michel'
  end

  factory :comment_from_test do
    title 'My Comment'
  end

  factory :group_from_test do
    name 'Administrators'
    level 37
  end

  factory :role_from_test do
  end

  factory :role_user_from_test do
  end

  factory :document_from_test do
  end

  factory :uploaded_file_from_test do
  end
end
