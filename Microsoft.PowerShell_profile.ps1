#$PSModuleAutoLoadingPreference = "None"
#
#Import-Module Microsoft.PowerShell.Utility
#Import-Module Microsoft.PowerShell.Management

$ErrorActionPreference = "Stop"
Import-Module posh-git
Import-Module npm-completion
Import-Module PSReadLine
Import-Module gsudoModule

function Remove-ExistingAlias {
    $seek=$args[0]
    if (test-path "alias:$seek") {
        Remove-Alias -name $seek -force -scope "global"
    }
}

function Update-Path {
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") +
                ";" +
                [System.Environment]::GetEnvironmentVariable("Path","User")
}

function Refresh-Env {
    # snarfed from https://stackoverflow.com/a/22670892
    foreach($level in "Machine","User") {
        [Environment]::GetEnvironmentVariables($level).GetEnumerator() | % {
            # For Path variables, append the new values, if they're not already in there
            if($_.Name -match 'Path$') { 
                $_.Value = ($((Get-Content "Env:$($_.Name)") + ";$($_.Value)") -split ';' | Select -unique) -join ';'
            }
            $_
        } | Set-Content -Path { "Env:$($_.Name)" }
    }
}

<#
.SYNOPSIS
    like cd, except it also sets the title of your terminal for
    the location
.DESCRIPTION
    changes the current working directory (cwd / pwd) and then
    updates the title based on some rules:
    - if we're under C:\code\codeo or C:\code\opensource,
        use the parent folder (ie project name) for the title
        of the window
    - if we're in the user's home dir, set the title to ~
    - otherwise revert to the default behavior, which will come
        from the command (so likely the full pwd, or if you're
        running an app which updates the title, then that

    since this calls out to Set-Location, try `Get-Help Set-Location`
    for parameters that can be passed
#>
function cd {
    if ($args.Length -eq 0) {
        Set-Location $home
        return
    }
    if (-not (Test-Path -PathType Container $args[0])) {
        Write-Host "$($args[0]): directory not found"
        return
    }
    Set-Location @args
    update-title-for-location
}

function lg {
    lazygit.exe @args
}

function su {
    sudo.exe pwsh.exe
}

# function winget {
#     Write-Host "Disabling windows firewall during winget operations..."
#     Disable-WindowsFirewall | out-null
#     winget.exe @args
#     Enable-WindowsFirewall | out-null
# }

$sep = "$([System.IO.Path]::DirectorySeparatorChar)"
$codeDir = "${sep}code${sep}"
function update-title-for-location {
    <#
    .SYNOPSIS
        Updates the tab / window title for the current session based on
        the current location
        - under code folder, observe the project under `codeo` or `opensource`
        - in home, use ~
        - everywhere else, set the window title to the current location
    #>
    $dir = $(get-location).Path
    if ($dir -eq $env:USERPROFILE) {
        $dir = "~"
    } elseif ($dir.Contains($codeDir)) {
        $parts = $dir.Split($sep)
        $project = $parts[3]
        $context = $parts[2]
        if ($context -eq "codeo" -or $context -eq "opensource") {
            $dir = "[ $project ]"
        }
    }
    $Host.UI.RawUI.WindowTitle = $dir
}

function df {
    df.exe -h @args
}

function ls {
    if ($env:TERMINAL_EMULATOR -eq "JetBrains-JediTerm") {
        ls.exe @args
    } else {
        ls.exe --color @args
    }
}

function Enable-WindowsFirewall {
    <#
    .SYNOPSIS
    Enables Windows Advanced Firewall via netsh command
    .DESCRIPTION
    Executes:
        netsh advfirewall set currentprofile state on
    via sudo.exe (elevation is required to run this command)
    #>
    sudo.exe netsh.exe advfirewall set currentprofile state on
}

function Disable-WindowsFirewall {
    <#
    .SYNOPSIS
    Disabled Windows Advanced Firewall via netsh command
    .DESCRIPTION
    Executes:
        netsh advfirewall set currentprofile state off
    via sudo.exe (elevation is required to run this command)
    #>
    sudo.exe netsh.exe advfirewall set currentprofile state off
}

Update-Path
#oh-my-posh init pwsh --config C:\code\opensource\scripts\daf.omp.json | Invoke-Expression


Set-Alias find C:\apps\gnuwin32\bin\find.exe
Set-PSReadlineOption -EditMode Emacs
Set-PSReadlineKeyHandler -Key ctrl+d -Function ViExit
Set-PSReadlineKeyHandler -Key Tab -Function TabCompleteNext
Set-PSReadlineKeyHandler -Key shift+Tab -Function TabCompletePrevious
Set-PSReadLineOption -BellStyle None
Set-PSReadLineOption -PredictionSource None

# Import the Chocolatey Profile that contains the necessary code to enable
# tab-completions to function for `choco`.
# Be aware that if you are missing these lines from your profile, tab completion
# for `choco` will not function.
# See https://ch0.co/tab-completion for details.
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
  Import-Module "$ChocolateyProfile"
}

update-title-for-location

. Remove-ExistingAlias cp
. Remove-ExistingAlias rm
. Remove-ExistingAlias ls
. Remove-ExistingAlias rmdir
. Remove-ExistingAlias mv
. Remove-ExistingAlias diff
. Remove-ExistingAlias sleep
. Remove-ExistingAlias cd
. Remove-ExistingAlias pwd
. Remove-ExistingAlias tee

Remove-Item Function:Remove-ExistingAlias

function Find-MySql-Service-Name()
{
  $result = $(sc query type= service state= all | grep SERVICE_NAME | grep -i mysql | awk '{print $2}')
  if ($result -is [array]) 
  {
    return $result
  }

  return @($result)
}

function Recover-From-Interrupted-Tests()
{
    $mysqlServices = Find-MySql-Service-Name
    $restartMySql = [System.Collections.ArrayList]@()
    foreach ($name in $mysqlServices)
    {
      if (Stop-Service-If-Running $name)
      {
        $restartMySql.Add($name)
      }
    }
    $restartRedis = Stop-Service-If-Running "Redis"
    Write-Host "Killing rogue mysqld processes"
    Kill-All mysqld
    Write-Host "Killing rogue redis-server processes"
    Kill-All redis-server
    Write-Host "Killing rogue test hosts"
    Kill-All testhost
    Write-Host "Killing msbuild"
    Kill-All msbuild
    Kill-All vbcscompiler
    if ($mysqlServices.Count -eq 0)
    {
      Write-Host "WARNING: Not restarting any mysql services ($mysqlServices -join ",")"
    }
    else
    {
      foreach ($name in $restartMySql)
      {
        Write-Host "Starting $name again"
        sudo net start $name
      }
    }

    if ($restartRedis)
    {
      Write-Host "Starting redis again"
      sudo net start "redis"
    }
    else
    {
      Write-Host "WARNING: Not restarting redis"
    }
}

function Kill-All($search) {
    $output = $(sudo pskill $search | grep killed)
    if ($output) {
      Write-Host $output
    } else {
      Write-Host "0 processes killed"
    }
    return
    $count = 0
    get-process | where-object {
      return $($_ -and $_.Path)
    } | foreach-object { 
      $part = $(Split-Path -Leaf $_.Path) 
      $cleaned = $part.Replace(".exe", "").Replace(".com", "")
      $match = $cleaned -like $search
      if ($match) {
        try {
          $_.Kill()
          $count++
        } catch {
          Write-Host "Can't kill $($_.Path) ($($proc.Id))"
        }
        #echo "should kill $($_.Path) ($cleaned) / ($search)"
      } else {
        #echo "_won't_ kill $($_.Path) ($cleaned) / ($search)"
      }
    }
    Write-Host "$count processes killed"
}


function Stop-Service-If-Running($name)
{
    $currentState = $(Get-Service $name).Status
    if ($currentState -ne "Running")
    {
        Write-Host "$name is not running"
        return $false
    }
    Write-Host "Stopping $name"
    sudo net stop $name
    return $true
}

function Kill-TempDb()
{
    sudo --inline net stop mysql80
    sudo --inline pskill mysqld
    sudo --inline net start mysql80
}

function aspnetrepl()
{
    csharprepl --framework Microsoft.AspNetCore.App
}

function nvm()
{
  echo "Redirecting to NVS..."
  nvs
}

function Set-LoadTestEnvVars()
{
  $ip=$(Resolve-DnsName "CODEO-LT-45" | grep 192.168.50 | head -n 1 | awk '{print $5}');
  $env:APPSETTINGS_ENVIRONMENT="LoadTest"
  $env:APPSETTINGS_AURORA_CONNECTION_STRING="SERVER=$ip; DATABASE=yumbi_loadtest; UID=yumbidev; PASSWORD=yumbidev; POOLING=true;Allow User Variables=true; Connection Lifetime=600; Max Pool Size=50;"
  $env:CONNECTIONSTRINGS_VOUCHERS="SERVER=$ip; DATABASE=yumbi_vouchers; UID=vouchersdev; PASSWORD=vouchersdev; POOLING=true;Allow User Variables=true; Connection Lifetime=600; Max Pool Size=50;"
  $env:CONNECTIONSTRINGS_MAIN="SERVER=$ip; DATABASE=yumbi_loadtest; UID=yumbidev; PASSWORD=yumbidev; POOLING=true;Allow User Variables=true; Connection Lifetime=600; Max Pool Size=50;"
  $env:LOADTEST_MIGRATIONS_ENVIRONMENT="Development"
  $env:LOADTEST_BRANCH="feat/beta-env-scrubber"
  $env:LOADTEST_THREADS_PER_AGENT=5
  $env:LOADTEST_AGENTS=5
  $env:LOADTEST_REPEAT=20
  $env:YUMBI_HOST="loadtest.yumbi.com"
  $env:LOADTEST_DEBUG=1
  $env:FORCE_MIGRATIONS=1
}

function Set-LoadTestEnvVarsForSingleTest()
{
  $ip=$(Resolve-DnsName "CODEO-LT-45" | grep 192.168.50 | head -n 1 | awk '{print $5}');
  $env:APPSETTINGS_ENVIRONMENT="LoadTest"
  $env:APPSETTINGS_AURORA_CONNECTION_STRING="SERVER=$ip; DATABASE=yumbi_loadtest; UID=yumbidev; PASSWORD=yumbidev; POOLING=true;Allow User Variables=true; Connection Lifetime=600; Max Pool Size=50;"
  $env:CONNECTIONSTRINGS_VOUCHERS="SERVER=$ip; DATABASE=yumbi_vouchers; UID=vouchersdev; PASSWORD=vouchersdev; POOLING=true;Allow User Variables=true; Connection Lifetime=600; Max Pool Size=50;"
  $env:CONNECTIONSTRINGS_MAIN="SERVER=$ip; DATABASE=yumbi_loadtest; UID=yumbidev; PASSWORD=yumbidev; POOLING=true;Allow User Variables=true; Connection Lifetime=600; Max Pool Size=50;"
  $env:LOADTEST_MIGRATIONS_ENVIRONMENT="Development"
  $env:LOADTEST_BRANCH="feat/beta-env-scrubber"
  $env:LOADTEST_THREADS_PER_AGENT=1
  $env:LOADTEST_AGENTS=1
  $env:LOADTEST_REPEAT=1
  $env:YUMBI_HOST="loadtest.yumbi.com"
  $env:LOADTEST_DEBUG=1
  $env:FORCE_MIGRATIONS=1
  $env:LTC_REPORT_FOLER="/app/logs"
}

function Set-LoadTestEnvVarsForLoadTestOverSSH()
{
  $ip="localhost"
  $env:APPSETTINGS_ENVIRONMENT="LoadTest"
  $env:APPSETTINGS_AURORA_CONNECTION_STRING="SERVER=$ip; DATABASE=yumbi; UID=loadtest; PASSWORD=Qk9qOZ4PEaYmuE7BZdmIkQNOOKWhKS5f; Port=3307; POOLING=true;Allow User Variables=true; Connection Lifetime=600; Max Pool Size=50;"
  $env:CONNECTIONSTRINGS_VOUCHERS="SERVER=$ip; DATABASE=yumbi; UID=loadtest; PASSWORD=Qk9qOZ4PEaYmuE7BZdmIkQNOOKWhKS5f; POOLING=true; Port=3307; Allow User Variables=true; Connection Lifetime=600; Max Pool Size=50;"
  $env:CONNECTIONSTRINGS_MAIN="SERVER=$ip; DATABASE=yumbi; UID=loadtest; PASSWORD=Qk9qOZ4PEaYmuE7BZdmIkQNOOKWhKS5f; POOLING=true; Port=3307; Allow User Variables=true; Connection Lifetime=600; Max Pool Size=50;"
  $env:LOADTEST_MIGRATIONS_ENVIRONMENT="Development"
  $env:LOADTEST_BRANCH="feat/beta-env-scrubber"
  $env:LOADTEST_THREADS_PER_AGENT=1
  $env:LOADTEST_AGENTS=1
  $env:LOADTEST_REPEAT=1
  $env:YUMBI_HOST="loadtest.yumbi.com"
  $env:LOADTEST_DEBUG=1
  $env:FORCE_MIGRATIONS=1
}


function Clear-LoadTestEnvVars()
{
  $env:APPSETTINGS_ENVIRONMENT=""
  $env:APPSETTINGS_AURORA_CONNECTION_STRING=""
  $env:CONNECTIONSTRINGS_VOUCHERS=""
  $env:CONNECTIONSTRINGS_MAIN=""
  $env:LOADTEST_MIGRATIONS_ENVIRONMENT=""
  $env:LOADTEST_BRANCH=""
  $env:LOADTEST_THREADS_PER_AGENT=""
  $env:LOADTEST_AGENTS=""
  $env:LOADTEST_REPEAT=""
  $env:YUMBI_HOST=""
  $env:LOADTEST_DEBUG=""
  $env:FORCE_MIGRATIONS=""
}

function Run-LoadTest()
{
  Set-LoadTestEnvVars
  npm run loadtest
}

#nvs auto on
new-alias -force -name wget -value wget2
new-alias -force -name 'c#' -value csharprepl
new-alias -force -name 'asp#' -value aspnetrepl
new-alias -force -name vlc -value 'C:\Program Files\VideoLAN\VLC\vlc.exe'

. $HOME/.dotbins/shell/powershell.ps1
