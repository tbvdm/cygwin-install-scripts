# Copyright (c) 2022 Tim van der Molen <tim@kariliq.nl>
#
# Permission to use, copy, modify, and distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

$setup            = "setup-x86_64.exe"
$setupUrl         = "https://cygwin.com/$setup"
$setupDirectory   = "C:\cygwin-setup"
$packageDirectory = "C:\cygwin-packages"
$rootDirectory    = "C:\cygwin64"
$siteUrl          = "https://ftp.snt.utwente.nl/pub/software/cygwin/"
$packages         = @(
    "gcc-core"
    "git"
    "libssl-devel"
    "make"
    "pkg-config"
)

function Say {
    Write-Host -BackgroundColor Yellow -ForegroundColor Black $args
}

function Pause {
    Say "Press Enter to close this window"
    Read-Host | Out-Null
}

function Abort {
    Say $args
    Pause
    exit 1
}

Say "Creating directory $setupDirectory"
New-Item -Force -ItemType Directory "$setupDirectory" | Out-Null
if (-not $?) {
    Abort "Cannot create directory $setupDirectory"
}

Set-Location "$setupDirectory"
if (-not $?) {
    Abort "Cannot set working location"
}

if (Test-Path "$setup") {
    Say "$setup already exists; not downloading"
} else {
    Say "Downloading $setupUrl"
    Invoke-WebRequest -OutFile "$setup" "$setupUrl"
    if (-not $?) {
        Abort "Cannot download $setupUrl"
    }
}

Say "Installing Cygwin"
$process = Start-Process -NoNewWindow -PassThru -Wait ".\$setup" `
    "--local-package-dir `"$packageDirectory`"",
    "--packages `"$($packages -join ',')`"",
    "--quiet-mode",
    "--root `"$rootDirectory`"",
    "--site `"$siteUrl`"",
    "--wait"
if ($process.ExitCode -ne 0) {
    Abort "The installation of Cygwin failed"
}

Say "Installing sigtop"
$process = Start-Process -NoNewWindow -PassThru -Wait "$rootDirectory\bin\bash.exe" `
    "-celo igncr",
    '"
    cd
    rm -fr sigtop
    git clone -b portable https://github.com/tbvdm/sigtop.git
    make -C sigtop install clean
    "'
if ($process.ExitCode -ne 0) {
    Abort "The installation of sigtop failed"
}

Say "Cygwin and sigtop have been successfully installed"
Pause
