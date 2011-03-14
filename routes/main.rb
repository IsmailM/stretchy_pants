class MyApp < Sinatra::Application

	# get '/stylesheets/:name.css' do
	#   content_type 'text/css', :charset => 'utf-8'
	#   scss(:"stylesheets/#{params[:name]}", Compass.sass_engine_options )
	# end

	get '/' do
		@test = User.find(:all)
		@page_title = "Welcome"
		haml :index
	end

	not_found do
		"Uh, 404. It seems that we can't find what you're looking for."
	end

	error do
		"Something that shouldn't have occurred did."
	end

end
