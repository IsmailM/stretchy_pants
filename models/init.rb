# Setup our DB Connections
#
# We're not using mongoid.yml cause we need to do some Heroku-specific parsing
# to use MongoHQ - user env.rb to setup these vars (and keep them out of scm).
#
configure :development do
  Mongoid.database = Mongo::Connection.new(ENV['MONGO_HOST'], ENV['MONGO_PORT']).db(ENV['MONGO_DB'])
  unless ENV['MONGO_USER'].nil?
  	Mongoid.database.authenticate(ENV['MONGO_USER'],ENV['MONGO_PASS'])
  end
  
end
configure :production do
  uri =  URI.parse(ENV['MONGOHQ_URL'])
  Mongoid.database = Mongo::Connection.new(uri.host, uri.port).db(uri.path.gsub(/^\//, ''))
  Mongoid.database.authenticate(uri.user, uri.password)
end
require_relative 'users'
