require 'sinatra/base'
require 'cnc/user'
require 'json'
require 'base64'
require 'tty-command'

module Cnc
  class Server < ::Sinatra::Base
    before do
      user_header = request.env['HTTP_X_USER']
      token_header = request.env['HTTP_X_TOKEN']

      if user_header
        @user = Cnc::User.find(user_header)
      end

      if token_header
        if @user and Cnc::User.verify_user(@user, token_header)
          @verified = true
        else
          @verified = false
          status 403
          body 'Invalid user or token'
          return
        end
      else
        @verified = false
      end

      payload_param = params[:payload]
      if payload_param
        @payload = self.decrypt(Base64::decode64(payload_param))
        if @payload.nil?
          status 403
          body 'You did not use the public key of this server for encryption!'
          return
        else
          begin
            @payload = JSON.parse(@payload)
          rescue
            @payload = nil
            status 403
            body 'Payload was not correctly encoded'
            return
          end
        end
      end
    end

    def decrypt(string)
      @privkey ||= OpenSSL::PKey.read(File.read(self.settings.key_file))

      begin
        return @privkey.private_decrypt(string)
      rescue
        return nil
      end
    end

    def need_verification
      status 403
      body 'Verification needed'
      return
    end

    get '/' do
      "Hello, world!"
    end

    get '/generate_token' do
      return need_verification unless @user
      Cnc::User.generate_token(@user)
    end

    get '/ping' do
      return need_verification unless @verified
      "you are verified to be '#{@user.real_name}'"
    end

    get '/tokens' do
      return need_verification unless @verified

      content_type :json
      @user.tokens.to_json
    end

    post '/execute' do
      return need_verification unless @verified

      command = @payload["command"]

      puts "Command: #{command}"
      begin
        cmd = TTY::Command.new(printer: :null)

        stdout, stderr = cmd.run!(command)
        content_type :json
        body ({
          command: command,
          output: stdout,
          error: stderr,
          }).to_json
        rescue
          "something went wrong"
        end
      end
    end
  end
