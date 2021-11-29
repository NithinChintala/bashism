function prompt {
    if ($PS1 -eq $null) {
        return "PS $($executionContext.SessionState.Path.CurrentLocation)$('>' * ($nestedPromptLevel + 1)) "
    }
    return $(Format-BashPrompt $PS1)
}

<#
.SYNOPSIS
Emulate Bash $PS1 behavior with backslash-escaped special characters.

.DESCRIPTION
Emulate Bash $PS1 behavior with backslash-escaped special characters that
are decoded as follows:
    \d     the date in "Weekday Month Date" format (e.g., "Tue May 26")
    \e     an ASCII escape character (033)
    \h     the hostname up to the first '.'
    \H     the hostname
    \n     newline
    \r     carriage return
    \t     the current time in 24-hour HH:MM:SS format
    \T     the current time in 12-hour HH:MM:SS format
    \@     the current time in 12-hour am/pm format
    \A     the current time in 24-hour HH:MM format
    \u     the username of the current user
    \v     the "Major.Minor" version of PowerShell (e.g., 5.1)
    \w     the current working directory, with $HOME abbreviated with a tilde
    \W     the basename of the current working directory, with $HOME abbreviated with a tilde
    \#     the command number of this command
    \\     a backslash

.PARAMETER Format
Specifies the backslash-escaped format to parse.

.OUTPUTS
System.String. Format-BashPrompt returns a string with all the backslash-escaped formats
replaced with their appropriate information.

.EXAMPLE
PS> Format-BashPrompt "\u@\h:\w$ "
Bob@DESKTOP-ABCDEFG:~$
#>
function Format-BashPrompt {
    param(
        [String] $Format
    )
    $sb = [System.Text.StringBuilder]::new()
    $dt = Get-Date
    
    for ($i = 0; $i -lt $Format.Length; $i++) {
        if ($Format[$i] -eq "\") {
            if ($i -eq ($Format.Length - 1)) {
                Write-Error -Message "Last character cannot be start of specifier" -Category InvalidArgument
                return
            }
            $specifier = $Format[$i+1]
            $i++ # skip the specifier on next iteration
            switch -Exact ($specifier) {
                "d" { $sb.Append($(Get-Date -UFormat "%a %b %d")) > $null; break }
                "e" { $sb.Append([char]0x1b) > $null; break }
                "h" { $sb.Append($($env:COMPUTERNAME -replace "\..*")) > $null; break }
                "H" { $sb.Append($env:COMPUTERNAME) > $null; break }
                "n" { $sb.Append("`n") > $null; break }
                "r" { $sb.Append("`r") > $null; break }
                "t" { $sb.Append($(Get-Date -Date $dt -UFormat "%T")) > $null; break }
                "T" { $sb.Append($(Get-Date -Date $dt -UFormat "%I:%M:%S")) > $null; break }
                "@" { $sb.Append($(Get-Date -Date $dt -UFormat "%r")) > $null; break }
                "A" { $sb.Append($(Get-Date -Date $dt -UFormat "%R")) > $null; break }
                "u" { $sb.Append($env:USERNAME) > $null; break }
                "v" {
                    $maj = $Host.Version.Major
                    $min = $Host.Version.Minor
                    $sb.Append("$maj.$min") > $null; break
                }
                "w" {
                    $dir = $PWD.Path -replace [regex]::Escape($HOME), "~"
                    $sb.Append($dir) > $null; break
                }
                "W" {
                    $dir = Split-Path -leaf ($PWD.Path -replace [regex]::Escape($HOME), "~")
                    $sb.Append($dir) > $null; break
                }
                "#" { $sb.Append($((Get-History -Count 1).Id + 1)) > $null; break }
                "\" { $sb.Append("\") > $null; break }
                Default {
                    Write-Error -Message "Invalid specifier: \$specifier " -Category InvalidArgument
                    return
                }
            }
        } else {
            $sb.Append($Format[$i]) > $null
        }
    }
    return $sb.ToString()
}
