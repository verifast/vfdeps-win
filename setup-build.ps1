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

$cygwin_exe = "cygwin-setup-x86_64.exe"
$cygwin_url = "https://cygwin.com/setup-x86_64.exe"
$mirror = "http://ftp.inf.tu-dresden.de/software/windows/cygwin32/"

$pkgs = [String]::Join(" ", (
        @(
            "coreutils"
            "rsync"
            "p7zip"
            "cygutils-extra"
            "make"
            "mingw64-x86_64-gcc-g++"
            "patch"
            "rlwrap"
            "diffutils"
            "m4"
            "curl"
            "python"
            "autoconf"
            "automake"
            "libtool"
            "intltool"
        ) | ForEach-Object { "-P " + $_ }
    ))

Invoke-WebRequest -Uri "$cygwin_url" -OutFile "$cygwin_exe"

Start-Process -NoNewWindow -FilePath "$cygwin_exe" -ArgumentList "-B -qnNd -R c:/cygwin -l c:/cygwin/var/cache/setup -s $mirror $pkgs" -Wait -PassThru
"none /cygdrive cygdrive binary,posix=0,user,noacl 0 0" | Out-File -FilePath "C:\cygwin\etc\fstab" -Encoding "utf8"

