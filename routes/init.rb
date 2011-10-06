# Load all of our route files
routes_root = File.dirname(__FILE__)
Dir["#{routes_root}/*.rb"].each {|file| require file }
