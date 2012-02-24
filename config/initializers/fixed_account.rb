if Rails.env.development?
  begin
    account = Account.first || Account.create
    FIXED_ACCOUNT = account.id
  rescue
    puts "Failed to set FIXED_ACCOUNT const"
  end
end
