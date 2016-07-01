# encoding: UTF-8
#
# Copyright 2015 Shawn Neal <sneal@sneal.net>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'erubis'
require 'winrm'
require 'winrm-fs'
require 'securerandom'

module WinRM
  module Elevated
    # Runs PowerShell commands elevated via a scheduled task
    class Runner
      # Creates a new Elevated Runner instance
      # @param [Shell] a winrm Shell
      def initialize(shell)
        @shell = shell
        @winrm_file_transporter = WinRM::FS::Core::FileTransporter.new(shell)
      end

      # Run a command or PowerShell script elevated without any of the
      # restrictions that WinRM puts in place.
      #
      # @param [String] The command or PS script to wrap in a scheduled task
      # @param [String] The admin user name to execute the scheduled task as
      # @param [String] The admin user password
      #
      # @return [Hash] :stdout and :stderr
      def powershell_elevated(script, username, password, &block)
        # if an IO object is passed read it, otherwise assume the contents of the file were passed
        script_text = script.respond_to?(:read) ? script.read : script

        script_path = upload_elevated_shell_script(script_text)
        wrapped_script = wrap_in_scheduled_task(script_path, username, password)
        @shell.run(wrapped_script, &block)
      end

      private

      def upload_elevated_shell_script(script_text)
        elevated_shell_path = 'c:/windows/temp/winrm-elevated-shell-' + SecureRandom.uuid + '.ps1'
        with_temp_file(script_text) do |temp_file|
          @winrm_file_transporter.upload(temp_file, elevated_shell_path)
        end
        elevated_shell_path
      end

      def with_temp_file(script_text)
        file = Tempfile.new(['winrm-elevated-shell', 'ps1'])
        file.write(script_text)
        file.fsync
        file.close
        yield file.path
      ensure
        file.close
        file.unlink
      end

      def elevated_shell_script_content
        IO.read(File.expand_path('../scripts/elevated_shell.ps1', __FILE__))
      end

      def wrap_in_scheduled_task(script_path, username, password)
        Erubis::Eruby.new(elevated_shell_script_content).result(
          username: username,
          password: password,
          script_path: script_path
        )
      end
    end
  end
end
