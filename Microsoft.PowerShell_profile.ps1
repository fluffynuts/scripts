Import-Module posh-git
Import-Module npm-completion
Import-Module PSReadLine

function refresh-path {
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") +
                ";" +
                [System.Environment]::GetEnvironmentVariable("Path","User")
}

function cd {
    Set-Location @args
    update-title-for-location
}

function update-title-for-location {
    $dir = $(get-location).Path
    if ($dir -eq $env:USERPROFILE) {
        $dir = "~"
    } elseif ($dir.StartsWith("C:\code")) {
        $project = $(split-path $dir -leaf)
        $context = $(split-path $(split-path $dir) -leaf)
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

refresh-path

oh-my-posh init pwsh --config ~/.mytheme.omp.json | Invoke-Expression

function do-remove-alias {
    $seek=$args[0]
    if (test-path "alias:$seek") {
        Remove-Alias -name $seek -force -scope "global"
    }
}

Set-Alias find C:\apps\gnuwin32\bin\find.exe
Set-PSReadlineOption -EditMode Emacs
Set-PSReadlineKeyHandler -Key ctrl+d -Function ViExit
Set-PSReadlineKeyHandler -Key Tab -Function TabCompleteNext
Set-PSReadLineOption -BellStyle None
Set-PSReadLineOption -PredictionSource None

function elevate {
    sudo.exe pwsh.exe
}

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

Set-Alias su elevate
. Do-Remove-Alias cp
. Do-Remove-Alias rm
. Do-Remove-Alias ls
. Do-Remove-Alias rmdir
. Do-Remove-Alias mv
. Do-Remove-Alias diff
. Do-Remove-Alias sleep
. Do-Remove-Alias cd
