require 'winrm'
require 'winrm-elevated'
require_relative 'matchers'

# Creates a WinRM connection for integration tests
module ConnectionHelper
  def winrm_connection
    WinRM::Connection.new(winrm_config)
  end

  def elevated_shell
    @elevated_shell ||= winrm_connection.shell(:elevated)
  end

  def winrm_config
    unless @winrm_config
      path = File.expand_path("#{File.dirname(__FILE__)}/config.yml")
      unless File.exist?(path)
        path = File.expand_path("#{File.dirname(__FILE__)}/config-example.yml")
      end
      @winrm_config = symbolize_keys(YAML.safe_load(File.read(path)))
      @winrm_config[:endpoint] = ENV['winrm_endpoint'] if ENV['winrm_endpoint']
      @winrm_config[:user] = ENV['winrm_user'] if ENV['winrm_user']
      @winrm_config[:password] = ENV['winrm_password'] if ENV['winrm_password']
    end
    @winrm_config
  end

  def username
    winrm_config[:user]
  end

  def password
    winrm_config[:password]
  end

  def symbolize_keys(hash)
    hash.each_with_object({}) do |(key, value), result|
      new_key = case key
                when String then key.to_sym
                else key
                end
      new_value = case value
                  when Hash then symbolize_keys(value)
                  else value
                  end
      result[new_key] = new_value
      result
    end
  end
end

RSpec.configure do |config|
  config.include(ConnectionHelper)
end
