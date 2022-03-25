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
    "curl"
    "gcc-core"
    "gcc-g++"
    "git"
    "libprotobuf-devel"
    "libsqlite3-devel"
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

Say "Installing protobuf-c and sigbak"
$process = Start-Process -NoNewWindow -PassThru -Wait "$rootDirectory\bin\bash.exe" `
    "-celo igncr",
    '"
    cd
    VERSION=1.3.3
    curl -LO https://github.com/protobuf-c/protobuf-c/releases/download/v$VERSION/protobuf-c-$VERSION.tar.gz
    rm -fr protobuf-c-$VERSION
    tar fxz protobuf-c-$VERSION.tar.gz
    cd protobuf-c-$VERSION
    ./configure --prefix=/usr/local
    make install
    cd ..
    rm -fr protobuf-c-$VERSION sigbak
    git clone -b portable https://github.com/tbvdm/sigbak.git
    PKG_CONFIG_PATH=/usr/local/lib/pkgconfig make -C sigbak install clean
    "'
if ($process.ExitCode -ne 0) {
    Abort "The installation of protobuf-c or sigbak failed"
}

Say "Cygwin and sigbak have been successfully installed"
Pause
