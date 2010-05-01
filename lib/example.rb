require 'rubygems'
require 'lib/facemask.rb'

API_KEY = ''
SECRET_KEY = ''
SESSION_KEY = ''
LOGGER = nil # Need logging? Pass STDOUT or anything that receives puts()
UID = ''
RETRY_ATTEMPTS = 0

# Sessions
facebook_session = Facemask::Session.new :api_key => API_KEY, 
                                         :secret_key => SECRET_KEY,
                                         :session_key => SESSION_KEY,
                                         :logger => STDOUT,
                                         :retry_attempts => 0
response = facebook_session.call 'Friends.get', :uids => UID

# One-off
response = Facemask.call :api_key => API_KEY,
                         :secret_key => SECRET_KEY,
                         :method => 'Friends.get',
                         :options => {:logger => LOGGER, :retry_attempts => RETRY_ATTEMPTS},
                         :arguments => {:uids => UID, :session_key => SESSION_KEY}

# Direct
request = Facemask::Request.new API_KEY, SECRET_KEY, RETRY_ATTEMPTS, LOGGER
response = request.call 'Friends.get', :uids => UID, :session_key => SESSION_KEY
