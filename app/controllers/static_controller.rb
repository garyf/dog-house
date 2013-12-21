class StaticController < ApplicationController

  skip_before_action :request_able_required

  def index
  end
end
