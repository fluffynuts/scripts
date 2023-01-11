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

Remove-Item Function:Remove-ExistingAlias
