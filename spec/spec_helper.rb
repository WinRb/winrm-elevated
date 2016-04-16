# encoding: UTF-8
require 'winrm'
require 'winrm-elevated'
require_relative 'matchers'

# Creates a WinRM connection for integration tests
module ConnectionHelper
  def winrm_connection
    WinRM::WinRMWebService.new(
      winrm_config['endpoint'],
      winrm_config['auth_type'].to_sym,
      user: username,
      pass: password,
      basic_auth_only: true)
  end

  def elevated_runner
    @elevated_runner ||= WinRM::Elevated::Runner.new(winrm_connection)
  end

  def winrm_config
    unless @winrm_config
      path = File.expand_path("#{File.dirname(__FILE__)}/config.yml")
      unless File.exist?(path)
        path = File.expand_path("#{File.dirname(__FILE__)}/config-example.yml")
      end
      @winrm_config = YAML.load(File.read(path))
      @winrm_config['endpoint'] = ENV['winrm_endpoint'] if ENV['winrm_endpoint']
    end
    @winrm_config
  end

  def username
    winrm_config['options']['user']
  end

  def password
    winrm_config['options']['pass']
  end
end

RSpec.configure do |config|
  config.include(ConnectionHelper)
end
