$ErrorActionPreference = "Stop"

Import-Module posh-git
Import-Module npm-completion
Import-Module PSReadLine

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

function winget {
    Write-Host "Disabling windows firewall during winget operations..."
    Disable-WindowsFirewall | out-null
    winget.exe @args
    Enable-WindowsFirewall | out-null
}

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
oh-my-posh init pwsh --config ~/.mytheme.omp.json | Invoke-Expression


Set-Alias find C:\apps\gnuwin32\bin\find.exe
Set-PSReadlineOption -EditMode Emacs
Set-PSReadlineKeyHandler -Key ctrl+d -Function ViExit
Set-PSReadlineKeyHandler -Key Tab -Function TabCompleteNext
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

Remove-Item Function:Remove-ExistingAlias

function Recover-From-Interrupted-Tests()
{
    Stop-Service-If-Running "MySQL57"
    Stop-Service-If-Running "Redis"
    Write-Host "Killing rogue mysqld processes"
    Kill-All "mysqld"
    Write-Host "Killing rogue redis-server processes"
    Kill-All "redis-server"
    Write-Host "Killing rogue test hosts"
    Kill-All "testhost"
    Write-Host "Killing msbuild"
    Kill-All "msbuild"
    Kill-All "vbcscompiler"
    Write-Host "Starting mysql again"
    Start-Service "MySql57"
    Write-Host "Starting redis again"
    Start-Service "redis"
}

function Kill-All($search) {
    $count = 0
    get-process | where-object { 
        if ($_ -and $_.Path) {
            $(Split-Path -Leaf $_.Path).Replace(".exe", "").Replace(".com", "") -like $search
        } else {
            return $false
        }
    } | foreach-object {
        $proc = $_
        try {
            $proc.Kill()
            $count++
        } catch {
            Write-Host "Can't kill $($proc.Path) ($($proc.Id))"
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
        return
    }
    Write-Host "Stopping $name"
    Stop-Service $name
}

function Kill-TempDb()
{
    sudo Stop-Service mysql57
    pskill mysqld
    sudo Start-Service mysql57
}
