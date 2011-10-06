# Stretchy Pants #

**An off-the-shelf, ready-to-go project template for Ruby web-apps with user
management/authentication built-in. Uses the following projects:**

* Sinatra
* Mongoid
* Warden
* Mail
* Compass / HAML / SASS
* HTML5 Boilerplate

No fancy generators or slick Rakefiles, just clone, point Mongoid towards your MongoDB (local or MongoHQ) and *commence to hacking*. Slim it down or stuff it with pork, **Stretchy Pants** can adjust to fit.

Stretchy Pants is **Heroku Enabled**, and will look for MongoHQ info when deployed.

## env.rb ##

The application will look for a file called `env.rb` where we stash information specific to your app, such as:

	ENV['MONGO_HOST']    = '127.0.0.1'
	ENV['MONGO_PORT']    = '27017'
	ENV['MONGO_DB']      = 'stretchy_pants'
	ENV['MONGO_USER']    = 'boss_tweed'
	ENV['MONGO_PASS']    = 'singlemaltwhisky'
	ENV['PASSWORD_SALT'] = 'sha256_hash_of_something' # IMPORTANT

If you deploy to Heroku you can set these using the Heroku Gem: [http://devcenter.heroku.com/articles/config-vars](http://devcenter.heroku.com/articles/config-vars)