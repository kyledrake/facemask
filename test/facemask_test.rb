require 'test/helper'

API_KEY = ''
SECRET_KEY = ''
SESSION = ''
PAGE_ID = '' # If you're not an Admin of this page, you'll need to change the test below so it will pass.
FB_USER_ID = ''

raise 'Missing API_KEY and/or SECRET_KEY' unless API_KEY && SECRET_KEY

class FacemaskTest < Test::Unit::TestCase
  
  context 'A Facebook session' do
    setup do
      @facebook_session = Facemask::Session.new :api_key => API_KEY,
                                                :secret_key => SECRET_KEY,
                                                :session_key => SESSION,
                                                :user_id => FB_USER_ID
    end
    
    test 'users.getLoggedInUser should return successfully' do
      result = @facebook_session.call 'users.getLoggedInUser'
      assert result.is_a?(String)
      assert result.to_i > 0
    end
    
    test 'should call friends.get and return an array' do
      results = @facebook_session.call 'Friends.get'
      assert results.is_a? Array
      assert results.length > 0
      assert results[0].to_i > 0
    end
    
    test 'should return a boolean for boolean call, and not get caught by invalid JSON returns from boolean calls on Facebook' do
      result = @facebook_session.call 'Pages.isAdmin', 'page_id' => PAGE_ID
      assert result == true
    end
    
    test 'should return raw JSON if JSON format is directly specified' do
      results = @facebook_session.call 'Friends.get'
      results_raw = @facebook_session.call 'Friends.get', :format => 'JSON'
      assert results_raw.is_a?(String)
      assert results == JSON.parse(results_raw)
    end
    
    test 'should not create Hashie object if return is array' do
      results = @facebook_session.call 'Friends.get'
      assert results.is_a?(Array)
    end
    
    test 'Should return Hashie objects within array if array contains hashes' do
      results = @facebook_session.call 'Photos.getAlbums', :uid => FB_USER_ID
      assert results.is_a?(Array)
      assert results.length > 0 # The profile pics should show up at the very least.
      assert results[0].is_a?(Hashie::Mash)
    end
    
    test 'should not create Hashie object if return is string' do
      results = @facebook_session.call 'users.getLoggedInUser'
      assert results.is_a?(String)
    end
    
    test 'should create Hashie object if return is Hash' do
      results = @facebook_session.call 'Admin.getAppProperties', :properties => ['app_id', 'application_name'].to_json
      assert results.is_a?(Hashie::Mash)
      assert results.app_id.is_a?(Fixnum)
      assert results.application_name.is_a?(String)
    end
    
    test 'should return XML if format is XML' do
      results = @facebook_session.call 'Friends.get', :format => 'xml'
      returned_at_least_one_response_element = false
      returned_uids = true
      REXML::Document.new(results).root.each_recursive do |element|
        returned_at_least_one_response_element = true if element.name == 'Friends_get_response_elt'
        returned_uids = false if element.text.to_s.to_i == 0 && element.name != 'Friends_get_response_elt'
      end
      assert returned_uids
      assert returned_at_least_one_response_element
    end
    
    test 'should return the login url' do
      login_url = Facemask::Utils.login_url(API_KEY)
      assert login_url == "http://api.facebook.com/login.php?api_key=#{API_KEY}"
    end
    
    test 'should return the login url with next url even if escaped' do
      next_url = 'http://apps.facebook.com/farmexplosion'
      login_url = Facemask::Utils.login_url API_KEY, :next => next_url
      login_url_escaped = Facemask::Utils.login_url API_KEY, :next => CGI.escape(next_url)
      assert login_url == "http://api.facebook.com/login.php?api_key=#{API_KEY}&next=#{CGI.escape next_url}"
      assert login_url == "http://api.facebook.com/login.php?api_key=#{API_KEY}&next=#{CGI.escape next_url}"
    end
    
  end
end