Ruby Mining
===========

Excuse project to learn Ruby and Rails with

$ rails new rubymines -d postgresql --skip-keeps --skip-webpack-install --skip-test --skip-system-test --skip-action-mailer --skip-action-mailbox --skip-action-text --skip-active-job --skip-spring
$ rm -rf rubymines/.git # b/c Rails insists on making a new git repo

Static files in public/ can be accessed directly. Not sure what takes precedence if conflict.

$ bin/rails generate model Game width:integer height:integer mines:integer
$ bin/rails db:migrate
- then check db/schema.rb to see if it swallowed the rest of the db again

$ bin/rails r lib/tasks/generate_games.rb
