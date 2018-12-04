# encoding: UTF-8
require 'date'

version = File.read(File.expand_path('../VERSION', __FILE__)).strip

Gem::Specification.new do |s|
  s.platform = Gem::Platform::RUBY
  s.name = 'winrm-elevated'
  s.version = version
  s.date = Date.today.to_s

  s.author = ['Shawn Neal']
  s.email = ['sneal@sneal.net']
  s.homepage = 'https://github.com/WinRb/winrm-elevated'

  s.summary = 'Ruby library for running commands as elevated'
  s.description = <<-EOF
    Ruby library for running commands via WinRM as elevated through a scheduled task
  EOF
  s.license = 'Apache-2.0'

  s.files = Dir.glob('{bin,lib,spec}/**/*') + %w[LICENSE README.md]
  s.require_path = 'lib'
  s.rdoc_options = %w(-x test/ -x examples/)
  s.extra_rdoc_files = %w(README.md LICENSE)

  s.required_ruby_version = '>= 1.9.0'
  s.add_runtime_dependency 'winrm', '~> 2.0'
  s.add_runtime_dependency 'winrm-fs', '~> 1.0'
  s.add_development_dependency 'rake', '>= 10.3', '< 13'
  s.add_development_dependency 'rspec', '~> 3.2'
  s.add_development_dependency 'rubocop', '~> 0.28'
end
