$ErrorActionPreference = "Stop"

<# 
    0 - Turns off script tracing.
    1 - Traces each line of the script as it is executed. 
        Lines in the script that are not executed are not traced. 
        Does not display variable assignments, function calls, or external scripts.
    2 - Traces each line of the script as it is executed. 
        Lines in the script that are not executed are not traced. 
        Displays variable assignments, function calls, and external scripts.
#>
Set-PSDebug -Trace 1

$cygwin_bin = "C:\cygwin\bin"

function Cygpath {
    param(
        [System.IO.FileInfo]$path
    )
    return &"$cygwin_bin\cygpath.exe" """$path"""
}

function MkDir {
    param(
        [System.IO.FileInfo]$path
    )
    If (!(Test-Path -PathType Container $path)) {
        New-Item -ItemType Directory -Path $path
    }
}

function LcBash {
    param(
        [String]$cmd
    )
    &"$cygwin_bin\bash.exe" "-lc" """$cmd"""
    if ($lastexitcode -ne 0) {
        throw ("Error...")
    }
}

$vfdeps_platform = "Win"
$vfdeps_version = &"git" "describe" "--always"
$vfdeps_dirname = "vfdeps"

$build_dir = (Get-Location).ToString()
$upload_dir = "$build_dir\upload"

$vfdeps_parent_dir = "C:\"
$vfdeps_dir = "$vfdeps_parent_dir\$vfdeps_dirname"

MkDir $upload_dir
MkDir $vfdeps_dir

# important for make to replace '\' with '/' in 'prefix'
$vfdeps_dir_slashes = ($vfdeps_dir).Replace("\", "/")
LcBash "cd $(Cygpath "$build_dir") && make PREFIX=$vfdeps_dir_slashes"

$vfdeps_filename = "$vfdeps_dirname-$vfdeps_version-$vfdeps_platform.txz"
$vfdeps_filepath = "$upload_dir/$vfdeps_filename"

LcBash "cd $(Cygpath "$vfdeps_parent_dir") && tar cjf $(Cygpath "$vfdeps_filepath") $vfdeps_dirname"

Get-ChildItem "$vfdeps_filepath"
LcBash "sha224sum $(Cygpath "$vfdeps_filepath")"