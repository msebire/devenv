Select-String '^([^=]*)=(.*)' "${env:DEVENV_TOOLS}\opt\env.ini" | % {
 [Environment]::SetEnvironmentVariable($_.Matches.Groups[1].Value, $ExecutionContext.InvokeCommand.ExpandString($_.Matches.Groups[2].Value), "Process")
}
