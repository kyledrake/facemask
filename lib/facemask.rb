require 'rubygems'
require 'net/http'
require 'digest/md5'
require 'cgi' unless defined? Rack
require 'json' unless defined? JSON
require 'hashie'

module Facemask
  
  FB_URL = "http://api.facebook.com/restserver.php"
  FB_API_VERSION = "1.0"
  
  class BadJSONDataError < StandardError
    # Error that happens when facebook sends back bad JSON 
    def initialize(returned_data)
      super "Facebook returned bad JSON data - #{returned_data}"
    end
  end

  class FaceBookError < StandardError
    # Error that happens during a facebook call.
    def initialize(error_code, error_msg)
        super "Facebook error #{error_code}: #{error_msg}"
    end
  end

  class Session
    attr_accessor :api_key, :secret_key, :session_key, :retry_attempts, :logger, :uid
    
    def initialize(opts = {})
      raise 'api_key and secret_key are required' unless opts[:api_key] && opts[:secret_key]
      @api_key        = opts[:api_key]
      @secret_key     = opts[:secret_key]
      @session_key    = opts[:session_key]
      @retry_attempts = opts[:retry_attempts] || 0
      @logger         = opts[:logger]
      @uid = opts[:uid]
    end
    
    def call(meth, arguments = {})
      arguments.merge! :session_key => @session_key if @session_key
      request = Request.new @api_key, @secret_key, @retry_attempts, @logger
      request.call meth, arguments
    end
  end
  
  def self.call(opts = {})
    raise 'api_key, secret_key method are required' unless opts[:api_key] && opts[:secret_key] && opts[:method]
    request = Request.new opts[:api_key], opts[:secret_key], (opts[:retry_attempts] || 0), opts[:logger]
    request.call opts[:method], opts[:arguments]
  end
  
  class Request
    def initialize(api_key, secret_key, retry_attempts=0, logger=nil)
      @api_key = api_key
      @secret_key = secret_key
      @retry_attempts = retry_attempts
      @logger = logger
    end
    
    def call(meth, arguments = {})
      
      custom_format = true if arguments[:format]
      arguments = {:api_key => @api_key,
                   :call_id => Time.now.tv_sec.to_s,
                   :format => 'JSON', 
                   :v => FB_API_VERSION, 
                   :method => meth}.merge! arguments

      arguments[:sig] = sign arguments

      @logger.puts "Facemask punches #{arguments[:method]} #{arguments.inspect}" if @logger
      
      attempt = 0
      begin
        response = Net::HTTP.post_form URI.parse(FB_URL), arguments
      rescue SocketError, Errno::ECONNRESET, EOFError => err
        attempt += 1 && retry if attempt < @retry_attempts
        raise
        # raise IOError.new( "Cannot connect to the facebook server: " + err )
      rescue
        raise
      end
      custom_format ? response.body : self.json_parse(response.body)
    end
    
    def json_parse(body)
      unescaped_attempt = false
      @logger.puts "Facemask receives #{data.inspect}" if @logger
      
      begin
        data = JSON.parse body
        data.collect! {|datum| Hashie::Mash.new datum } if data.is_a?(Array) && data.length > 0 && data[0].is_a?(Hash)
        raise FaceBookError.new(data["error_code"] || 1, data["error_msg"]) if data.include?("error_msg")
      rescue JSON::ParserError => ex
        return (body == 'true') if %w{true false}.include?(body) # Hack for Facebook boolean API calls with BAD JSON.
        return body unless unescaped_body = body[/\A"(.*)"\z/m,1]
        unescaped_attempt = true
        body = unescaped_body.gsub('\\', '')
        retry
        raise BadJSONDataError, "Facebook returned invalid JSON: \"#{body}\""
      end

      data.is_a?(Hash) ? Hashie::Mash.new(data) : data
    end

    def sign(arguments)
      arguments_string = ''
      arguments.sort {|a,b| a[0].to_s <=> b[0].to_s}.each {|kv| arguments_string << kv[0].to_s << "=" << kv[1]}
      Digest::MD5.hexdigest arguments_string + @secret_key
    end
    
  end

  module Utils
    def self.verify_signature(secret, arguments)
        signature = arguments.delete "fb_sig"
        return false if signature.nil?
        signed = {}
        arguments.each { |k, v| signed[$1] = v if k =~ /^fb_sig_(.*)/ }
        arg_string = String.new
        signed.sort.each { |kv| arg_string << kv[0] << "=" << kv[1] }
        Digest::MD5.hexdigest(arg_string + secret) == signature ? true : false
    end

    def self.login_url(api_key, options={})
      login_url = "http://api.facebook.com/login.php?api_key=#{api_key}"
      login_url << "&next=#{defined?(Rack) ? Rack::Utils.escape(options[:next]) : CGI.escape(options[:next])}" if options[:next]
      login_url << "&canvas" if options[:canvas]
      login_url
    end
  end
  
end