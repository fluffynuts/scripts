Remove-Item alias:rm
Remove-Item alias:ls
Remove-Item alias:cp
Remove-Item alias:mv

Function Ls-Color {
    . $(which ls) --color @Args
}
Set-Alias ls Ls-Color

Import-Module posh-git

# makes ctrl-d work to exit, as well as some
#  other stuff
Set-PSReadLineOption -EditMode vi
# make history work the traditional
#  way -- vi history mode has no preview
Set-PSReadLineKeyHandler -Chord Ctrl+r -Function ReverseSearchHistory
