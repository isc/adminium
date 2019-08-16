# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).

account = Account.create! name: 'doctolib-development', plan: 'complimentary',
                          db_url: "postgresql://#{ENV['USER']}@localhost/doctolib-development"
user = User.create! email: 'contact@ivanschneider.fr', provider: 'google_oauth2', name: 'Ivan Schneider'
Collaborator.create! user: user, account: account, email: user.email, is_administrator: true, kind: user.provider
