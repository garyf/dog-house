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
  # after the waiting period has passed, requests are unrestrained

  def within_window(sec_now)
    window_count = session[:window_count]
    if window_count >= WINDOW_LIMIT
      session[:request_restrained] = true
      session[:sec_restrained] = sec_now # impose a wait of WINDOW_SECONDS duration
    else
      session[:window_count] += 1
    end
  end

  def window_new(sec_now)
    session[:sec_start] = sec_now
    session[:window_count] = 0
  end

  def restrained(sec_now)
    sec_restrained = session[:sec_restrained]
    elapsed = sec_now - sec_restrained
    if elapsed > RESTRAIN_SECONDS
      session[:request_restrained] = false
      session[:sec_restrained] = nil
      window_new(sec_now)
    end
  end

  def request_restrained?
    sec_now = Time.zone.now.to_i
    sec_start = session[:sec_start]
    if sec_start
      elapsed = sec_now - sec_start
      if elapsed < WINDOW_SECONDS
        within_window(sec_now)
      elsif session[:request_restrained]
        restrained(sec_now)
      else
        window_new(sec_now)
      end
    else
      window_new(sec_now)
    end
    session[:request_restrained]
  end

  class Restrained < StandardError
  end

  def request_able_required
    raise Restrained if request_restrained?
  end
end
