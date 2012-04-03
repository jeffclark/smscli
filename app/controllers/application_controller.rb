class ApplicationController < ActionController::Base
  protect_from_forgery
	Time.zone = Smscli::Application.config.time_zone
end
