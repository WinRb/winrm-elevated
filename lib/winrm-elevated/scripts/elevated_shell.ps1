param([String]$username, [String]$password, [String]$encoded_command)

$task_name = "WinRM_Elevated_Shell"
$out_file = "$env:Temp\winrm_elevated_out.log"
$err_file = "$env:Temp\winrm_elevated_err.log"

if (Test-Path $out_file) {
  del $out_file
}
if (Test-Path $err_file) {
  del $err_file
}

$task_xml = @'
<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.2" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
  <Principals>
    <Principal id="Author">
      <UserId>{username}</UserId>
      <LogonType>Password</LogonType>
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
    <ExecutionTimeLimit>PT2H</ExecutionTimeLimit>
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

$arguments = "/c powershell.exe -EncodedCommand $encoded_command &gt; $out_file 2&gt;$err_file"

$task_xml = $task_xml.Replace("{arguments}", $arguments)
$task_xml = $task_xml.Replace("{username}", $username)

$schedule = New-Object -ComObject "Schedule.Service"
$schedule.Connect()
$task = $schedule.NewTask($null)
$task.XmlText = $task_xml
$folder = $schedule.GetFolder("\")
$folder.RegisterTaskDefinition($task_name, $task, 6, $username, $password, 1, $null) | Out-Null

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

$exit_code = $registered_task.LastTaskResult
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($schedule) | Out-Null

exit $exit_code
