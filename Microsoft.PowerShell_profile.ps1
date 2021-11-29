Import-Module posh-git
Import-Module oh-my-posh
Import-Module npm-completion
Import-Module PSReadLine

set-poshprompt -theme ~/.mytheme.omp.json

function remove-alias {
    param (
        $alias
    )
    if (test-path $alias) {
        remove-item $alias -force
    }
}

Remove-Alias alias:cp
Remove-Alias alias:rm
Remove-Alias alias:ls
Remove-Alias alias:rmdir
Remove-Alias alias:mv
Remove-Alias alias:diff

Set-Alias find C:\apps\gnuwin32\bin\find.exe
Set-PSReadlineOption -EditMode Emacs
Set-PSReadlineKeyHandler -Key ctrl+d -Function ViExit
Set-PSReadlineKeyHandler -Key Tab -Function TabCompleteNext
Set-PSReadLineOption -BellStyle None

Function Ls-Real {
    if ($env:NO_COLOR) {
        ls.exe @Args
    } else {
        ls.exe --color @Args
    }
}

Set-Alias ls Ls-Real

