# encoding: utf-8
require 'sinatra/base'

module Sinatra
	module FormHelpers
		# Check for form params[] and validation errors
    # setting values and CSS classes accordingly.
    def form_class(name, type)
      @val = ''
      if @form && @form[name]
        if name != 'password'
          @val = @form[name]
        end
      end
      @cls = 'input'
      if type == 'hidden'
        @cls = 'hidden'
      end
      if @errors && @errors["#{name}"]
        @cls += ' error'
      end
    end
	end
	helpers FormHelpers
end
