class ApplicationController < ActionController::Base

  include RequestRateLimit
  hide_action :within_window, :window_new, :while_restrained, :request_restrained?

  before_action :request_able_required

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

private

  def request_able_required
    return unless request_restrained?
    redirect_to(static_index_path, alert: 'Your access is now suspended due to a rapid series of recent requests')
  end
end
