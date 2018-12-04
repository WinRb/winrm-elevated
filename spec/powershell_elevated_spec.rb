describe 'powershell elevated runner', integration: true do
  describe 'ipconfig' do
    subject(:output) { elevated_shell.run('ipconfig') }
    it { should have_exit_code 0 }
    it { should have_stdout_match(/Windows IP Configuration/) }
    it { should have_no_stderr }
  end

  describe 'ipconfig as Service' do
    subject(:output) do
      elevated_shell.username = 'System'
      elevated_shell.password = nil
      elevated_shell.run('ipconfig')
    end
    it { should have_exit_code 0 }
    it { should have_stdout_match(/Windows IP Configuration/) }
    it { should have_no_stderr }
  end

  describe 'echo \'hello world\' using apostrophes' do
    subject(:output) { elevated_shell.run("echo 'hello world'") }
    it { should have_exit_code 0 }
    it { should have_stdout_match(/hello world/) }
    it { should have_no_stderr }
  end

  describe 'ipconfig with incorrect argument -z' do
    subject(:output) { elevated_shell.run('ipconfig 127.0.0.1 -z') }
    it { should have_exit_code 1 }
  end

  describe 'Math area calculation' do
    subject(:output) do
      cmd = <<-COMMAND
        $diameter = 4.5
        $area = [Math]::pow([Math]::PI * ($diameter/2), 2)
        Write-Host $area
      COMMAND
      elevated_shell.run(cmd)
    end
    it { should have_exit_code 0 }
    it { should have_stdout_match(/49.9648722805149/) }
    it { should have_no_stderr }
  end

  describe 'ipconfig with a block' do
    subject(:stdout) do
      outvar = ''
      elevated_shell.run('ipconfig') do |stdout, _stderr|
        outvar << stdout
      end
      outvar
    end
    it { should match(/Windows IP Configuration/) }
  end

  describe 'capturing output from Write-Host and Write-Error' do
    subject(:output) do
      script = <<-COMMAND
      Write-Host 'Hello'
      $host.ui.WriteErrorLine(', world!')
      COMMAND

      @captured_stdout = ''
      @captured_stderr = ''
      elevated_shell.run(script) do |stdout, stderr|
        @captured_stdout << stdout if stdout
        @captured_stderr << stderr if stderr
      end
    end

    it 'should have stdout' do
      expect(output.stdout).to eq("Hello\r\n")
      expect(output.stdout).to eq(@captured_stdout)
    end

    it 'should have stderr' do
      expect(output.stderr).to eq(", world!\r\n")
      expect(output.stderr).to eq(@captured_stderr)
    end

    it 'should have output' do
      expect(output.output).to eq("Hello\r\n, world!\r\n")
    end
  end
end
