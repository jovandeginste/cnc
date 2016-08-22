require 'faraday'
require 'base64'
require 'cnc/user'
require 'json'

module Cnc
  class Client
    attr_accessor :server, :user, :ssl_params, :server_public
    def initialize(server, user, params = {})
      self.server = server
      self.user = user
      self.server_public = params[:server_public]
      self.ssl_params = params[:ssl_params] || {}
    end

    def self.create_simple_query(*methods)
      methods.each do |method|
        define_method method do
          puts "Sending simple query '/#{method}'"
          query_server("/#{method}")
        end
      end
    end

    def self.create_simple_post(*methods)
      methods.each do |method|
        define_method method do |payload|
          puts "Sending simple post '/#{method}', payload: #{payload.inspect}"
          post_server("/#{method}", payload)
        end
      end
    end

    create_simple_query :ping, :tokens
    create_simple_post :execute

    def get_token
      url = '/generate_token'
      status, body = query_server(url, {}, false)
      return body
    end

    def query_server(url, headers = {}, authenticated = true)
      headers = headers.clone
      @connection ||= Faraday.new("http://#{self.server}", :ssl => ssl_params)

      headers['X-User'] = self.user.name
      if authenticated
        token = [Time.now.to_i, self.get_token].join(':')
        enc_token = Base64::encode64(self.user.encrypt(token))

        headers['X-Token'] = enc_token
      end

      begin
        result = @connection.get(url, {}, headers)
      rescue Faraday::SSLError => e
        puts "SSL connection could not be established"
      end

      status, body = result.status, result.body
      puts "[#{status}] #{body}"
      return status, body
    end

    def post_server(url, payload, headers = {}, authenticated = true)
      headers = headers.clone
      @connection ||= Faraday.new("http://#{self.server}", :ssl => ssl_params)

      headers['X-User'] = self.user.name
      if authenticated
        token = [Time.now.to_i, self.get_token].join(':')
        enc_token = Base64::encode64(self.user.encrypt(token))

        headers['X-Token'] = enc_token
      end

      parameters = {
        payload: Base64::encode64(self.server_encrypt(payload.to_json)),
      }

      begin
        result = @connection.post(url, parameters, headers)
      rescue Faraday::SSLError => e
        puts "SSL connection could not be established"
      end

      status, body = result.status, result.body
      puts "[#{status}] #{body}"
      return status, body
    end

    def server_encrypt(string)
      return self.server_public.public_encrypt(string)
    end
  end
end
