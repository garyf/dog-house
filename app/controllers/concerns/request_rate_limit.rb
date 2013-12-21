module RequestRateLimit

  RESTRAIN_SECONDS = 89
  WINDOW_LIMIT = 5
  WINDOW_SECONDS = 21

  # usage:
  #   before_action :request_able_required

  # requests are unrestrained if
  #   - the request count does not exceed the WINDOW_LIMIT
  #   - within a time window having a duration of WINDOW_SECONDS
  # otherwise, if the WINDOW_LIMIT of requests is exceeded
  #   - a 'waiting period' of RESTRAIN_SECONDS begins
  #   - during the waiting period, requests redirect to a static template
  # after the time window or waiting period end,
  # a fresh time window starts upon the next request

  def within_window
    if session[:window_count] >= WINDOW_LIMIT
      session[:request_restrained] = true
      session[:sec_restrained] = @sec_now # impose a wait of RESTRAIN_SECONDS duration
    else
      session[:window_count] += 1
    end
  end

  def window_new
    session[:sec_start] = @sec_now
    session[:window_count] = 0
  end

  def while_restrained
    elapsed = @sec_now - session[:sec_restrained]
    if elapsed > RESTRAIN_SECONDS
      session[:request_restrained] = false
      session[:sec_restrained] = nil
      window_new
    else
      session[:sec_restrained] = @sec_now # restart the waiting period
    end
  end

  def request_restrained?
    @sec_now = Time.zone.now.to_i
    sec_start = session[:sec_start]
    if sec_start
      elapsed = @sec_now - sec_start
      if elapsed < WINDOW_SECONDS
        within_window
      elsif session[:request_restrained]
        while_restrained
      else
        window_new
      end
    else
      window_new
    end
    session[:request_restrained]
  end

  def request_able_required
    return unless request_restrained?
    redirect_to(static_index_path, alert: 'Your access is now suspended due to a rapid series of recent requests')
  end
end
