class MyApp < Sinatra::Base

  use Warden::Manager do |manager|
    manager.default_strategies :password
    manager.failure_app = MyApp
  end

  Warden::Manager.serialize_into_session{ |user| user.id }
  Warden::Manager.serialize_from_session{ |id| User.find(id) }

  Warden::Manager.before_failure do |env,opts|
    # Sinatra can be picky about the method used to authenticate
    # so to be sure everything works, let's specify it here.
    env['REQUEST_METHOD'] = "POST"
  end

  Warden::Strategies.add(:password) do
    def valid?
      params['user']["email"] || params['user']["password"]
    end

    def authenticate!
      u = User.authenticate(params['user']["email"], params['user']["password"])
      u.nil? ? fail!("Could not log in") : success!(u)
    end
  end

  def warden_handler
    env['warden']
  end

  # Check to make sure user is authenticated and bounce to login if not
  def check_authentication
    unless warden_handler.authenticated?
      session[:crumb_path] = env['PATH_INFO']
      redirect '/login'
    end
  end

  def check_superuser
    unless env['warden'].user.admin?
      flash[:notice] = "You do not have permission to access that function"
      redirect '/'
    end
  end

  def current_user
    warden_handler.user
  end

  # Send mail based to users with a new password.
  # Expects to send a multi-part email (text/html)
  #
  # takes a hash of settings like so:
  #  data = {
  #          :to        => 'user@sinatra.org',
  #          :from      => settings.mail_from,
  #          :subject   => settings.mail_subject,
  #          :plaintext => "Regrets, I've had a few",
  #          :html      => "<h1>I did it my way</h1>",
  #          :sent      => Time.now
  #        }
  def send_mail(data)
    mail = Mail.new do
      to data[:to]
      from data[:from]
      subject data[:subject]
      text_part do
        body data[:plaintext]
      end
      html_part do
        content_type 'text/html; charset=UTF-8'
        body data[:html]
      end
    end
    mail.deliver!
  end

  get '/logout' do
    warden_handler.logout
    redirect '/'
  end

  get '/login' do
    haml :"users/login_form"
  end

  post '/login/?' do
    @form = params['user']
    if env['warden'].authenticate
      if session[:crumb_path]
        redirect session[:crumb_path]
      else
        redirect '/'
      end
    else
      flash[:error] = "There was a problem logging in"
      haml :"users/login_form"
    end
  end

  post '/session' do
    warden_handler.authenticate!
    if warden_handler.authenticated?
      redirect session[:crumb_path]
    else
      redirect '/login'
    end
  end

  get '/forgot_pass' do
    haml :"users/forgot_pass"
  end

  post '/forgot_pass' do
    @form = params['user']
    if @form['email']
      if user = User.first(:conditions => {:email => @form['email']})
        random_password = Array.new(10).map { (65 + rand(58)).chr }.join

        # HEREDOC for plaintext email message, feel free to get funky here
        @text = <<-TEXT.gsub(/^ {6}/, '')
          Hi #{User.name}, you requested a new password for Snappy Sinatra App.
          New password: #{random_password}

          Thanks, Mgmt.
          TEXT

          # HEREDOC for HTML email message, feel free to get funky here
          @html = <<-HTML.gsub(/^ {6}/, '')
          <h2>Hi #{User.name}</h2>
          <p>You requested a new password for Snappy Sinatra App.</p>
          <p><strong>New password:</strong> #{random_password}</p>
          <p>Thanks, Mgmt.</p>
          HTML

          mail = {
            :to        => @form['email'],
            :from      => settings.mail_from,
            :subject   => settings.mail_subject,
            :plaintext => @text,
            :html      => @html,
            :sent      => Time.now
          }

          # Set two fields on model to trigger automatic bcrypting of the new password
          user.password = user.password_confirmation = random_password

          if user.valid?
            user.save!
            send_mail(mail)
            flash[:success] = "A new password has been mailed to you. Please check your inbox and the Ministry of Junk Mail."
            redirect '/login'
          end
          flash[:error] = "There was a problem generating a new password for you. Contact the authorities."
          redirect '/forgot_pass'
      end
    end
    flash[:error] = "That user could not be found"
    redirect '/forgot_pass'
  end

  get '/profile' do
    @user = User.first(:conditions =>{:id => env['warden'].user.id})
    if @user.nil?
      flash[:error] = "Could not find that profile"
      redirect '/'
    end
    haml :"/users/profile"
  end

  # Allow users to update password
  # We check against the old one, and if matches we update
  # and then force the user to login with the new password
  post '/profile' do
    @user = User.first(:conditions =>{:id => env['warden'].user.id})
    @form = params['user']
    user = User.authenticate(@user.email, @form['old_password'])
    if user.nil?
      flash[:error] = "Password incorrect - could not update"
      redirect '/profile'
    end
    user.update_attributes(@form)
    if user.valid?
      flash[:success] = 'Your password has been updated'
      redirect "/logout"
    else
      @errors = user.errors
    end
    haml :"/users/profile"
  end

  get '/users' do
    @users = User.find(:all)
    haml :"users/index"
  end

  get '/users/add' do
    haml :"users/add"
  end

  post '/users/add' do
    @form = params['user']
    user = User.new(@form)
    user.password = @form['password']
    if user.valid?
      user.save!
      redirect '/users'
    else
      @errors = user.errors
    end
    haml :"users/add"
  end

  get '/users/edit/:id' do
    user = User.first(:conditions =>{:id => params[:id]})
    if user.nil?
      flash[:error] = "Could not find user"
      redirect '/users'
    end
    @form = user.attributes
    haml :"users/edit"
  end

  post '/users/edit' do
    @form = params['user']
    @form.delete_if {|key, value| value.empty? }
    if @form['admin'] && @form['admin'] == 'on'
      @form['admin'] = 1
    end

    if @form['_id']
      user = User.first(:conditions => {:id => @form['_id']})
      user.update_attributes(@form)
      if user.valid?
        flash[:success] = 'User has been updated'
        redirect "/users"
      else
        @errors = user.errors
      end
      haml :"users/edit"
    end
  end

  get '/users/destroy/:id' do
    check_authentication
    user = User.first(:conditions => {:id => params[:id]})
    flash[:notice] = "User #{user.name}/#{user.id} was destroyed."
    user.destroy
    redirect "/users"
  end

end
