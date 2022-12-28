using namespace System.Management.Automation

# Source https://gist.github.com/backerman/2c91d31d7a805460f93fe10bdfa0ffb0
# - Modified to use ~/.ssh/config and only complete with host names
Register-ArgumentCompleter -CommandName ssh,scp,sftp -Native -ScriptBlock {
    param($wordToComplete, $commandAst, $cursorPosition)
    $knownHosts = Get-Content ${Env:HOMEPATH}\.ssh\config `
    | Select-String -Pattern "^Host " `
    | ForEach-Object { $_ -replace "Host ", "" } `
    | Sort-Object -Unique

    # For now just assume it's a hostname.
    $textToComplete = $wordToComplete
    $generateCompletionText = {
        param($x)
        $x
    }

    $knownHosts `
    | Where-Object { $_ -like "${textToComplete}*" } `
    | ForEach-Object { [CompletionResult]::new((&$generateCompletionText($_)), $_, [CompletionResultType]::ParameterValue, $_) }
}
