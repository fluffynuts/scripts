Import-Module posh-git
Import-Module npm-completion
Import-Module PSReadLine

function refresh-path {
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") +
                ";" +
                [System.Environment]::GetEnvironmentVariable("Path","User")
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

function remove-alias {
    param (
        $alias
    )
    if (test-path $alias) {
        remove-item $alias -force
    }
}

Set-Alias find C:\apps\gnuwin32\bin\find.exe
Set-PSReadlineOption -EditMode Emacs
Set-PSReadlineKeyHandler -Key ctrl+d -Function ViExit
Set-PSReadlineKeyHandler -Key Tab -Function TabCompleteNext
Set-PSReadLineOption -BellStyle None
Set-PSReadLineOption -PredictionSource None

Function Ls-Real {
    if ($env:NO_COLOR) {
        ls.exe @Args
    } else {
        ls.exe --color @Args
    }
}

function elevate {
    sudo.exe pwsh.exe
}

Set-Alias ls Ls-Real
Set-Alias su elevate
Remove-Alias alias:cp
Remove-Alias alias:rm
Remove-Alias alias:ls
Remove-Alias alias:rmdir
Remove-Alias alias:mv
Remove-Alias alias:diff
Remove-Alias alias:sleep


# Import the Chocolatey Profile that contains the necessary code to enable
# tab-completions to function for `choco`.
# Be aware that if you are missing these lines from your profile, tab completion
# for `choco` will not function.
# See https://ch0.co/tab-completion for details.
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
  Import-Module "$ChocolateyProfile"
}

