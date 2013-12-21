# Dog House

Dog House is a Ruby module that throttles resource requests within a Rails application.

## How it works

When a first request is made, Dog House marks the start of a time window.
The duration of the time window defaults to 21 seconds.

During that window:

- Additional requests are unrestrained if the request count does not exceed a limit of 5 (configurable)
- If the request count exceeds the limit, a configurable 'waiting period' begins
- Requests during the waiting period redirect to a static template (the dog house)

After the time window or waiting period end, a fresh time window starts upon the next request.

Rather than interacting with PostgreSQL, Dog House stores values within the session.

## Usage

Add these files to your Rails app:

- **/app/controllers/concerns/request\_rate\_limit.rb** 
- **/spec/controllers/concerns/request\_rate\_limit\_spec.rb**

Within your ApplicationController, include the RequestRateLimit module and add a private method to redirect to your desired 'dog house' route, e.g.

``` ruby
include RequestRateLimit

private

rescue_from RequestRateLimit::Restrained do
  redirect_to(static_index_path, alert: 'Your access is now restrained due to an excessive number of recent requests')
end
```

Within those controllers for which you want request throttling:

``` ruby
before_action :request_able_required
```

## Test coverage

Dog House also demonstrates Rspec coverage of a controller concern, using the Timecop gem.

## Demo

For demonstration purposes, Dog House includes a bare-bones Rails 4.0.2 application.
To see Dog House in action requires PostgreSQL. With Ruby 1.9.3 or later and gem bundler installed:

```bash
bundle install
bundle exec rake db:create:all
bundle exec rake db:migrate
rails s
```

## Other approaches

Intentionally, Dog House takes a lightweight approach to rate limiting. Potentially more robust alternatives that use Rack middleware include:

* [rack-attack](https://github.com/kickstarter/rack-attack) by [Kickstarter](https://github.com/kickstarter)
* [rack-throttle](https://github.com/datagraph/rack-throttle) by [Datagraph](github.com/datagraph)

## Why 'Dog House'

When a user's access to the application is restrained, they are effectively in the dog house.
