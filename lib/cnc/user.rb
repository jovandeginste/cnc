require 'securerandom'
require 'base64'

module Cnc
  class User
    class << self
      def user_hash
        @users ||= {}
      end

      def users
        self.user_hash.values
      end

      def find(username)
        self.user_hash[username]
      end

      def add_user(user)
        self.user_hash[user.name] = user
      end

      def verify_user(user, token)
        return nil if user.nil? or token.nil? or token.empty?

        decrypt_token = user.decrypt(Base64::decode64(token))
        return nil if decrypt_token.nil?

        timestamp, provided_token = decrypt_token.split(':')
        return nil if timestamp.nil? or provided_token.nil? or timestamp.empty? or provided_token.empty?
        return nil unless (-15..60).include?(Time.now.to_i - timestamp.to_i)

        return user if user.verify_token(provided_token)
        return nil
      end

      def generate_token(user)
        return "invalid username" if user.nil?

        new_token = user.generate_token
        return new_token
      end

    end

    attr_accessor :name, :real_name, :public_key, :private_key

    def initialize(name, attributes = {})
      self.name = name
      self.real_name = attributes[:real_name]
      self.public_key = attributes[:public_key]
      self.private_key = attributes[:private_key]

      self.class.add_user(self)
    end

    def full_tokens
      @tokens ||= {}
    end

    def tokens
      self.sanitize_tokens
      self.full_tokens.keys
    end

    def generate_token
      self.sanitize_tokens
      new_token = SecureRandom.base64
      timestamp = Time.now.to_i

      self.full_tokens[new_token] = timestamp
      return new_token
    end

    def sanitize_tokens
      self.full_tokens.delete_if{|token, stamp|
        Time.now.to_i > stamp + 60
      }
    end

    def decrypt(string)
      begin
        return self.public_key.public_decrypt(string)
      rescue
        return nil
      end
    end

    def encrypt(string)
      self.private_key.private_encrypt(string)
    end

    def verify_token(token)
      if self.tokens.include?(token)
        self.full_tokens.delete(token)
        return true
      end
      return false
    end
  end
end
