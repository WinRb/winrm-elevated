# WinRM-Elevated Gem Changelog

# 1.2.3
- Fix encoding corruptions

# 1.2.2
- Use StringIO instead of Tempfile to write task script
- Optimize requires
- Cleanup orphaned tasks

# 1.2.1
- Backport GUID usage for PowerShell < 5
- Wrap task setup within try block and exit on caught errors

# 1.2.0
- Add configurable timeouts for execution
- Remove old task and add a unique name

# 1.1.2
- Replace erubis with erubi

# 1.1.1
- Slim gem and resolve several RuboCop warnings

# 1.1.0
- Allow tasks to be configured for interactive logon
- Fix broken credentials when they contain dollar signs
- Do not fail when temporary files cannot be deleted

# 1.0.1
- Fix to avoid profile conflicts
- Fix inadequate Execution Policy errors

# 1.0.0
- Adjust to comply with winrm v2 APIs
- Expose implementation as a class of `WinRM::Shells`

# 0.4.0
- Initialize `Elevated::Runner` with a `CommandExecutor` instead of a `WinrmService` client
- Run commands from newer winrm executor
- Use latest winrm-fs 0.4.2
- Allow task to run as a service account
- Provide an artificially long timeout to the task to keep the task from dying after 60 seconds

# 0.3.0
- [Name Powershell Script and Log Files Uniquely](https://github.com/WinRb/winrm-elevated/pull/6)

# 0.2.0
- [Only upload the elevated runner script once per winrm session](https://github.com/WinRb/winrm-elevated/pull/3)
- Bump WinRM (1.5) and WinRM-fs (0.3.0) gem constraints

# 0.1.0
- Initial Release
