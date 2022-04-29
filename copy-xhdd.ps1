[CmdletBinding()]
Param([string]$Path)

If ( ! (Get-module 7Zip4Powershell )) { 
    Import-Module 7Zip4Powershell
}

function New-TemporaryDirectory {
    $parent = [System.IO.Path]::GetTempPath()
    [string] $name = [System.Guid]::NewGuid()
    New-Item -ItemType Directory -Path (Join-Path $parent $name)
}

function verify-mount {
    param()
    if (-Not (Test-Path -LiteralPath "X:\")) {
        throw "No X: drive mounted please use fatxplorer to mount XBOX HDD"
    }
}

function verify-sourcePath {
    Param([string]$Path)
    if (-Not (Test-Path -LiteralPath "$Path")) {
        throw "Source $Path does not exist"
    }
}

function get-archives {
    Param([string]$Path)
    $archives = gci -af -LiteralPath $Path -Filter *.7z
    $archives
}

function get-existingGames {
    (Get-ChildItem -LiteralPath "X:\Games").BaseName
}

verify-mount
verify-sourcePath $Path

$hshGamesList = @{}

get-archives $path | % {
    $fn = "$Path\$_"
    $gn = ((Get-7Zip -ArchiveFileName $fn)[0].FileName | Split-Path -Parent).split('\')[0] | ? {$_ -ne ""}
    if (($gn -ne "" ) -and ($gn -ne $null)) {
        $hshGamesList.add($gn, $fn)
    } else {
        Write-Warning "$fn has no root dir in archive"
    }
}

get-existingGames | % {
    if ($hshGamesList.ContainsKey($_)) {
        $hshGamesList.Remove($_)
    }
}

$hshGamesList.Keys | % {
    $tmpdir = (New-TemporaryDirectory).FullName
    Expand-7Zip -ArchiveFileName $hshGamesList[$_] -TargetPath $tmpdir
    Robocopy $tmpdir X:\Games /E /MOVE /MT
}

