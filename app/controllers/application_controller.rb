class ApplicationController < ActionController::Base

  include RequestRateLimit

  before_action :request_able_required

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

private

  rescue_from RequestRateLimit::Restrained do
    redirect_to(root_path, alert: 'Your access is now restrained due to an excessive number of recent requests')
  end
end
