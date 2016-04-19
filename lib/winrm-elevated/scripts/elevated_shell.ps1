param([String]$username, [String]$password, [String]$encoded_command, [String]$timeout)

$pass_to_use = $password
$logon_type = 1
$logon_type_xml = "<LogonType>Password</LogonType>"
if($pass_to_use.length -eq 0) {
  $pass_to_use = $null
  $logon_type = 5
  $logon_type_xml = ""
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
    <ExecutionTimeLimit>{timeout}</ExecutionTimeLimit>
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
$task_xml = $task_xml.Replace("{timeout}", $timeout)
$task_xml = $task_xml.Replace("{logon_type}", $logon_type_xml)

$schedule = New-Object -ComObject "Schedule.Service"
$schedule.Connect()
$task = $schedule.NewTask($null)
$task.XmlText = $task_xml
$folder = $schedule.GetFolder("\")
$folder.RegisterTaskDefinition($task_name, $task, 6, $username, $pass_to_use, $logon_type, $null) | Out-Null

$registered_task = $folder.GetTask("\$task_name")
$current_tasks=@()
$current_tasks += Get-WmiObject -Class Win32_Process -Filter "name = 'powershell.exe' and CommandLine like '%$encoded_command%'" |
  select ProcessId |
  % { $_.ProcessId }

$registered_task.Run($null) | Out-Null

$timeout = 10
$sec = 0

do{
  $taskProc=Get-WmiObject -Class Win32_Process -Filter "name = 'powershell.exe' and CommandLine like '%$encoded_command%'" |
    select ProcessId |
    % { $_.ProcessId } |
    ? { !($current_tasks -contains $_) }
}
Until($taskProc -ne $null)
$waitProc=get-process -id $taskProc -ErrorAction SilentlyContinue

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
} while ($waitProc -ne $null -and !$waitProc.HasExited)

$exit_code = $registered_task.LastTaskResult
# 259 indicates STILL_ACTIVE. We assume 0
# At some point we can investigate being more
# sophisticated to get the final exit code in
# this case.
if($exit_code -eq 259) { $exit_code = 0 }
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($schedule) | Out-Null

del $out_file
del $err_file

exit $exit_code
