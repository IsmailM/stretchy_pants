class User
  include Mongoid::Document
  include Mongoid::Timestamps
  include BCrypt

  validates_presence_of :name, :email
  validates_format_of :email, :with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i, :message => "must be a valid email address"
  validates_length_of :password, :minimum => 8, :maximum => 48, :message => "must be between 8 and 48 characters", :if => "password_changed?"
  validates_confirmation_of :password, :if => "password_changed?", :message => "and confirmation didn't match"

  field :email
  field :name
  field :password
  field :admin, :type => Boolean, :default => false

  before_create :hash_password
  before_update :check_and_hash_password

  # BCrypt needs to do some ops on the hash to compare
  # https://github.com/codahale/bcrypt-ruby/blob/master/lib/bcrypt.rb#L149
  def self.authenticate (email, password)
    if user = first(:conditions => {:email => email})
      db_pass = Password.new(user.password)
      if db_pass == password
        return user
      end
      nil
    end
    nil
  end

  protected


  def password_changed
    if self.password.nil?
      return false
    end
    puts self.password
    return true
  end

  def check_and_hash_password
    if self.password_confirmation
      if self.password_confirmation == self.password
        self.password = Password.create(self.password)
      end
    end
  end

  # Use BCrypt to apply hella hashing to passwords before creating
  def hash_password
    self.password = Password.create(self.password)
  end

end
