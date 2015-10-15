# Runs PowerShell commands as elevated over Windows Remote Management (WinRM) via a scheduled task
[![Gem Version](https://badge.fury.io/rb/winrm-elevated.svg)](http://badge.fury.io/rb/winrm-elevated)

## Running commands elevated
```ruby
require 'winrm'
require 'winrm-elevated'

service = WinRM::WinRMWebService.new(...
elevated_runner = WinRM::Elevated::Runner.new(service)
result = elevated_runner.powershell_elevated('dir', 'Administrator', 'password')
puts "Std out: #{result.output}"
```


## Troubleshooting

If you're having trouble, first of all its most likely a network or WinRM configuration
issue. Take a look at the [WinRM gem troubleshooting](https://github.com/WinRb/WinRM#troubleshooting)
first.

## Contributing

1. Fork it.
2. Create a branch (git checkout -b my_feature_branch)
3. Run the unit and integration tests (bundle exec rake integration)
4. Commit your changes (git commit -am "Added a sweet feature")
5. Push to the branch (git push origin my_feature_branch)
6. Create a pull requst from your branch into master (Please be sure to provide enough detail for us to cipher what this change is doing)

### Running the tests

We use Bundler to manage dependencies during development.

```
$ bundle install
```

Once you have the dependencies, you can run the unit tests with `rake`:

```
$ bundle exec rake spec
```

To run the integration tests you will need a Windows box with the WinRM service properly configured. Its easiest to use the Vagrant Windows box in the Vagrantilfe of this repo.

1. Create a Windows VM with WinRM configured (see above).
2. Copy the config-example.yml to config.yml - edit this file with your WinRM connection details.
3. Run `bundle exec rake integration`

## WinRM-elevated Authors
* Shawn Neal (https://github.com/sneal)

[Contributors](https://github.com/WinRb/winrm-elevated/graphs/contributors)
