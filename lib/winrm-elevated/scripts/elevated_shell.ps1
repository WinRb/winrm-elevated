$username = '<%= username %>'
$password = '<%= password %>'
$script_file = '<%= script_path %>'

$interactive = '<%= interactive_logon %>'
$pass_to_use = $password
$logon_type = 1
$logon_type_xml = "<LogonType>Password</LogonType>"
if($pass_to_use.length -eq 0) {
  $pass_to_use = $null
  $logon_type = 5
  $logon_type_xml = ""
}
if($interactive -eq 'true') {
  $logon_type = 3
  $logon_type_xml = "<LogonType>InteractiveTokenOrPassword</LogonType>"
}

$task_name = "WinRM_Elevated_Shell"
$out_file = [System.IO.Path]::GetTempFileName()
$err_file = [System.IO.Path]::GetTempFileName()

$task_xml = @'
<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.2" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
  <Principals>
    <Principal id="Author">
      <UserId>{username}</UserId>
      {logon_type}
      <RunLevel>HighestAvailable</RunLevel>
    </Principal>
  </Principals>
  <Settings>
    <MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy>
    <DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>
    <StopIfGoingOnBatteries>false</StopIfGoingOnBatteries>
    <AllowHardTerminate>true</AllowHardTerminate>
    <StartWhenAvailable>false</StartWhenAvailable>
    <RunOnlyIfNetworkAvailable>false</RunOnlyIfNetworkAvailable>
    <IdleSettings>
      <StopOnIdleEnd>false</StopOnIdleEnd>
      <RestartOnIdle>false</RestartOnIdle>
    </IdleSettings>
    <AllowStartOnDemand>true</AllowStartOnDemand>
    <Enabled>true</Enabled>
    <Hidden>false</Hidden>
    <RunOnlyIfIdle>false</RunOnlyIfIdle>
    <WakeToRun>false</WakeToRun>
    <ExecutionTimeLimit>PT24H</ExecutionTimeLimit>
    <Priority>4</Priority>
  </Settings>
  <Actions Context="Author">
    <Exec>
      <Command>cmd</Command>
      <Arguments>{arguments}</Arguments>
    </Exec>
  </Actions>
</Task>
'@

$arguments = "/c powershell.exe -executionpolicy bypass -NoProfile -File $script_file &gt; $out_file 2&gt;$err_file"

$task_xml = $task_xml.Replace("{arguments}", $arguments)
$task_xml = $task_xml.Replace("{username}", $username)
$task_xml = $task_xml.Replace("{logon_type}", $logon_type_xml)

$schedule = New-Object -ComObject "Schedule.Service"
$schedule.Connect()
$task = $schedule.NewTask($null)
$task.XmlText = $task_xml
$folder = $schedule.GetFolder("\")
$folder.RegisterTaskDefinition($task_name, $task, 6, $username, $pass_to_use, $logon_type, $null) | Out-Null

$registered_task = $folder.GetTask("\$task_name")
$registered_task.Run($null) | Out-Null

$timeout = 10
$sec = 0
while ( (!($registered_task.state -eq 4)) -and ($sec -lt $timeout) ) {
  Start-Sleep -s 1
  $sec++
}

function SlurpOutput($file, $cur_line, $out_type) {
  if (Test-Path $file) {
    get-content $file | select -skip $cur_line | ForEach {
      $cur_line += 1
      if ($out_type -eq 'err') {
        $host.ui.WriteErrorLine("$_")
      } else {
        $host.ui.WriteLine("$_")
      }
    }
  }
  return $cur_line
}

$err_cur_line = 0
$out_cur_line = 0
do {
  Start-Sleep -m 100
  $out_cur_line = SlurpOutput $out_file $out_cur_line 'out'
  $err_cur_line = SlurpOutput $err_file $err_cur_line 'err'
} while (!($registered_task.state -eq 3))

# We'll make a best effort to clean these files
# But a reboot could possibly end the task while the process
# still runs and locks the file. If we can't delete we don't want to fail
try { Remove-Item $out_file -ErrorAction Stop } catch {}
try { Remove-Item $err_file -ErrorAction Stop } catch {}
try { Remove-Item $script_file -ErrorAction Stop } catch {}

$exit_code = $registered_task.LastTaskResult
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($schedule) | Out-Null

exit $exit_code
