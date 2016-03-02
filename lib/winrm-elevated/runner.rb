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

require 'winrm'
require 'winrm-fs'

module WinRM
  module Elevated
    # Runs PowerShell commands elevated via a scheduled task
    class Runner
      # Creates a new Elevated Runner instance
      # @param [WinRMWebService] WinRM web service client
      def initialize(winrm_service)
        @winrm_service = winrm_service
        @winrm_file_manager = WinRM::FS::FileManager.new(winrm_service)
        @elevated_shell_path = 'c:/windows/temp/winrm-elevated-shell.ps1'
        @uploaded            = nil
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

        upload_elevated_shell_wrapper_script
        wrapped_script = wrap_in_scheduled_task(script_text, username, password)
        @winrm_service.run_cmd(wrapped_script, &block)
      end

      private

      def upload_elevated_shell_wrapper_script
        return if @uploaded
        with_temp_file do |temp_file|
          @winrm_file_manager.upload(temp_file, @elevated_shell_path)
          @uploaded = true
        end
      end

      def with_temp_file
        file = Tempfile.new(['winrm-elevated-shell', 'ps1'])
        file.write(elevated_shell_script_content)
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

      def wrap_in_scheduled_task(script_text, username, password)
        ps_script = WinRM::PowershellScript.new(script_text)
        "powershell -executionpolicy bypass -file \"#{@elevated_shell_path}\" " \
          "-username \"#{username}\" -password \"#{password}\" -timeout \"#{@winrm_service.timeout}\" " \
          "-encoded_command \"#{ps_script.encoded}\""
      end
    end
  end
end
