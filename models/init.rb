
configure :development do
  Mongoid.database = Mongo::Connection.new(ENV['MONGO_HOST'], ENV['MONGO_PORT']).db(ENV['MONGO_DB'])
  Mongoid.database.authenticate(ENV['MONGO_USER'],ENV['MONGO_PASS'])
end
configure :production do
  uri =  URI.parse(ENV['MONGOHQ_URL'])
  Mongoid.database = Mongo::Connection.new(uri.host, uri.port).db(uri.path.gsub(/^\//, ''))
  Mongoid.database.authenticate(uri.user, uri.password)
end
require_relative 'users'
