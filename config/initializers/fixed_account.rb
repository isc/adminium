if Rails.env.development?
  account = Account.first || Account.create
  FIXED_ACCOUNT = account.id
end
