require 'spec_helper'

describe PeopleController do
  context 'w Time.zone.now' do
    before { Timecop.freeze }
    context '#within_window' do
      before { session[:sec_start] = earlier RequestRateLimit::WINDOW_SECONDS - 1 }
      describe 'w window_count < WINDOW_LIMIT' do
        before do
          session[:window_count] = RequestRateLimit::WINDOW_LIMIT - 1
          get :index
        end
        it do
          expect(session[:window_count]).to eql RequestRateLimit::WINDOW_LIMIT
          expect(session[:request_restrained]).to be nil
        end
      end

      describe 'w window_count == WINDOW_LIMIT' do
        before do
          session[:window_count] = RequestRateLimit::WINDOW_LIMIT
          get :index
        end
        it 'restrain' do
          expect(session[:window_count]).to eql RequestRateLimit::WINDOW_LIMIT
          expect(session[:request_restrained]).to be true
          expect(session[:sec_restrained]).to eql earlier 0
        end
      end
    end

    context '#window_new' do
      before do
        session[:sec_start] = earlier RequestRateLimit::WINDOW_SECONDS
        session[:window_count] = RequestRateLimit::WINDOW_LIMIT - 1
        get :index
      end
      it do
        expect(session[:sec_start]).to eql earlier 0
        expect(session[:window_count]).to eql 0
      end
    end

    context '#while_restrained' do
      before do
        session[:request_restrained] = true
        session[:sec_start] = earlier RequestRateLimit::WINDOW_SECONDS
      end
      describe 'w elapsed == WINDOW_SECONDS' do
        before do
          session[:sec_restrained] = earlier RequestRateLimit::WINDOW_SECONDS
          get :index
        end
        it 'restart the waiting period' do
          expect(session[:request_restrained]).to be true
          expect(session[:sec_restrained]).to eql earlier 0
        end
      end

      describe 'w elapsed > WINDOW_SECONDS' do
        before do
          session[:sec_restrained] = earlier RequestRateLimit::RESTRAIN_SECONDS + 1
          get :index
        end
        it 'start a fresh time window' do
          expect(session[:request_restrained]).to be false
          expect(session[:sec_restrained]).to be nil
          expect(session[:sec_start]).to eql earlier 0
          expect(session[:window_count]).to eql 0
        end
      end
    end
    after { Timecop.return }
  end

  context '#request_restrained?' do
    before do
      @time_0 = Time.zone.local(2013, 12, 20, 8, 0, 0)
      Timecop.freeze @time_0
      get :index
      Timecop.freeze @time_0 + 1
      get :index
      Timecop.freeze @time_0 + 2
      get :index
      Timecop.freeze @time_0 + 3
      get :index
      Timecop.freeze @time_0 + 4
      get :index
      Timecop.freeze @time_0 + 5
      get :index
    end
    it 'w window_count < WINDOW_LIMIT' do
      expect(session[:sec_start]).to eql earlier 5
      expect(session[:window_count]).to eql 5
      expect(session[:request_restrained]).to be nil
    end

    context 'w window_count == WINDOW_LIMIT' do
      before do
        Timecop.freeze @time_0 + 6
        get :index
      end
      it 'restrain' do
        expect(session[:sec_start]).to eql earlier 6
        expect(session[:window_count]).to eql 5
        expect(session[:request_restrained]).to be true
        expect(session[:sec_restrained]).to eql earlier 0
      end

      describe "after waiting #{RequestRateLimit::RESTRAIN_SECONDS} seconds" do
        before do
          @sec_start_to_now = 6 + RequestRateLimit::RESTRAIN_SECONDS
          Timecop.freeze @time_0 + @sec_start_to_now
          get :index
        end
        it 'restart the waiting period'  do
          expect(session[:sec_start]).to eql earlier @sec_start_to_now
          expect(session[:window_count]).to eql 5
          expect(session[:request_restrained]).to be true
          expect(session[:sec_restrained]).to eql earlier 0
        end
      end

      describe "after waiting #{RequestRateLimit::RESTRAIN_SECONDS + 1} seconds" do
        before do
          @sec_start_to_now = 7 + RequestRateLimit::RESTRAIN_SECONDS
          Timecop.freeze @time_0 + @sec_start_to_now
          get :index
        end
        it 'start a fresh time window' do
          expect(session[:sec_start]).to eql earlier 0
          expect(session[:window_count]).to eql 0
          expect(session[:request_restrained]).to be false
          expect(session[:sec_restrained]).to be nil
        end
      end
    end
  end

private

  def earlier(seconds)
    Time.zone.now.to_i - seconds
  end
end
