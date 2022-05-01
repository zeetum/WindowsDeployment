@echo off
CLS

:wait
ping localhost -n 2 > nul
echo Starting Powershell Domain Join Script...

:Call DomainJoin Powershell
powershell.exe -noprofile -executionpolicy bypass -file %~dp0\DomainJoin\JoinDomainRestartIf.ps1

exit