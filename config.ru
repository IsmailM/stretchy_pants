require 'sinatra'

root = File.dirname(__FILE__)

# env.rb is a local dev configuration file (MongoHQ, etc)
if File.exists?(File.join(root,'env.rb'))
  require File.join(root, 'env.rb')
end

require File.join(root, 'app')
run MyApp.new
