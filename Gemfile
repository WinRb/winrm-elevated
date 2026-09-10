source 'https://rubygems.org'
gemspec

gem 'bundler-audit', '~> 0.9.3', require: false
gem 'ruby_audit', '~> 3.1', require: false if RUBY_VERSION >= '3.1.0'

gem 'rubocop', require: false

# rake < 13 requires 'ostruct', which was removed from the stdlib in Ruby 4.0
gem 'ostruct', require: false if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('4.0')

# winrm-fs requires 'csv' but does not declare it; csv is no longer a
# default gem on Ruby 3.4+
gem 'csv', require: false
