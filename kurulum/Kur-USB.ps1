<#
.SYNOPSIS
    MATS/MODS USB imajini bir USB belege ham yazar, dogrular ve menu dosyasini kopyalar.

.DESCRIPTION
    Windows'ta Yonetici olarak calistirilmalidir. USB'nin icindeki HER SEY SILINIR.
    Guvenlik: yalnizca USB tipindeki, sistem/boot olmayan, imajdan kucuk olmayan bir diske yazar
    ve yazmadan once "EVET <disk no>" onayi ister.

.PARAMETER Liste
    Sadece takili USB diskleri listeler. Hicbir sey yazmaz.

.PARAMETER ImajYolu
    Forumdan indirilip 7-Zip ile acilmis .img dosyasi.

.PARAMETER DiskNo
    Yazilacak diskin numarasi (-Liste ciktisindaki "No").

.PARAMETER Onay
    Onay metni: "EVET <DiskNo>" (ornek: "EVET 1"). Verilmezse etkilesimli sorulur.
    Yapay zeka ajanlari bu degeri YALNIZCA kullanici ilgili diski acikca onayladiktan sonra vermelidir.

.PARAMETER MenuYolu
    Kopyalanacak menu dosyasi. Varsayilan: bu betigin bir ust klasorundeki "menu".

.PARAMETER MD5Atla
    Imajin MD5 kontrolunu atlar (farkli bir imaj kullaniyorsan).

.PARAMETER HedefDosya
    SADECE TEST ICIN: fiziksel disk yerine bir dosyaya yazar.

.EXAMPLE
    .\Kur-USB.ps1 -Liste
    .\Kur-USB.ps1 -ImajYolu "C:\indirilenler\MODS From 60GB 1-11-2023 with NVMT.img" -DiskNo 1
#>
[CmdletBinding()]
param(
    [switch]$Liste,
    [string]$ImajYolu,
    [int]$DiskNo = -1,
    [string]$Onay,
    [string]$MenuYolu,
    [switch]$MD5Atla,
    [string]$HedefDosya
)

$ErrorActionPreference = 'Stop'
$BilinenMD5 = '3cc2ce1e4b9836548a8fad6479a2c4c3'   # forum sayfasindaki imaj MD5 degeri
$BolumEtiketleri = @('MODS30xx','MODS5x-20xx')       # menu dosyasi her iki bolume de kopyalanir (hangisinin kartina uygun oldugu README'de)

function Hata($m) { Write-Host "HATA: $m" -ForegroundColor Red; exit 1 }
function Bilgi($m) { Write-Host $m }

function Yonetici-mi {
    $p = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Diskleri-Listele {
    $d = Get-Disk | Where-Object { $_.BusType -eq 'USB' }
    if (-not $d) { Bilgi 'Takili USB disk bulunamadi.'; return }
    Bilgi 'Takili USB diskler:'
    foreach ($x in $d) {
        $harfler = (Get-Partition -DiskNumber $x.Number -ErrorAction SilentlyContinue | Where-Object DriveLetter | ForEach-Object { "$($_.DriveLetter):" }) -join ' '
        '{0,3}  {1,-32} {2,7:N1} GB  sistem={3}  harfler={4}' -f $x.Number, $x.FriendlyName, ($x.Size / 1GB), $x.IsSystem, $harfler
    }
}

# Ham diske/dosyaya yazmak icin (FILE_FLAG_WRITE_THROUGH ile)
Add-Type -TypeDefinition @'
using System;
using System.ComponentModel;
using System.IO;
using System.Runtime.InteropServices;
using Microsoft.Win32.SafeHandles;
public static class HamDisk {
    [DllImport("kernel32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
    static extern SafeFileHandle CreateFile(string name, uint access, uint share, IntPtr sa, uint disp, uint flags, IntPtr tmpl);
    public static FileStream Ac(string yol, bool yaz) {
        uint erisim = yaz ? 0xC0000000u : 0x80000000u;
        SafeFileHandle h = CreateFile(yol, erisim, 3, IntPtr.Zero, 3, yaz ? 0x80000000u : 0u, IntPtr.Zero);
        if (h.IsInvalid) throw new Win32Exception(Marshal.GetLastWin32Error());
        return new FileStream(h, yaz ? FileAccess.ReadWrite : FileAccess.Read, 1);
    }
}
'@

# Imaji hedefe yazar (once 1 MB sonrasi, bolum tablosu en son), sonra geri okuyup karsilastirir
function Ham-Yaz($imaj, $hedefAc) {
    $parca = 4MB; $bas = 1MB
    $imajBoyu = (Get-Item -LiteralPath $imaj).Length
    $buf = New-Object byte[] $parca; $b2 = New-Object byte[] $parca
    $src = [IO.File]::OpenRead($imaj)
    $dst = & $hedefAc
    try {
        $src.Position = $bas; $dst.Position = $bas; $yapilan = $bas; $son = -1
        while ($yapilan -lt $imajBoyu) {
            $n = $src.Read($buf, 0, [int][math]::Min([long]$parca, [long]($imajBoyu - $yapilan)))
            if ($n -le 0) { throw 'Imaj okuma hatasi' }
            $dst.Write($buf, 0, $n); $yapilan += $n
            $yuzde = [int](100 * $yapilan / $imajBoyu)
            if ($yuzde -ne $son -and $yuzde % 10 -eq 0) { Bilgi "Yaziliyor %$yuzde"; $son = $yuzde }
        }
        $ilk = New-Object byte[] $bas
        $src.Position = 0; [void]$src.Read($ilk, 0, $bas)
        $dst.Position = 0; $dst.Write($ilk, 0, $bas); $dst.Flush()
        Bilgi 'Yazma bitti. Dogrulaniyor (USB''yi CIKARMA)...'
        $dst.Position = 0; $src.Position = 0; $yapilan = 0; $son = -1
        while ($yapilan -lt $imajBoyu) {
            $iste = [int][math]::Min([long]$parca, [long]($imajBoyu - $yapilan))
            $n1 = $src.Read($buf, 0, $iste); $got = 0
            while ($got -lt $iste) { $r = $dst.Read($b2, $got, $iste - $got); if ($r -le 0) { break }; $got += $r }
            if ($n1 -ne $iste -or $got -ne $iste -or -not [System.Linq.Enumerable]::SequenceEqual([byte[]]$buf, [byte[]]$b2)) {
                throw "Dogrulama hatasi (konum $yapilan). Yazma basarisiz, USB'yi tekrar yaz."
            }
            $yapilan += $iste
            $yuzde = [int](100 * $yapilan / $imajBoyu)
            if ($yuzde -ne $son -and $yuzde % 10 -eq 0) { Bilgi "Dogrulaniyor %$yuzde"; $son = $yuzde }
        }
        Bilgi 'Dogrulama OK: USB imajla birebir ayni.'
    } finally { $dst.Dispose(); $src.Dispose() }
}

# ---------------- ana akis ----------------
if ($Liste) { Diskleri-Listele; exit 0 }

if (-not $ImajYolu) { Hata '-ImajYolu gerekli. (Once -Liste ile diskleri gor.)' }
if (-not (Test-Path -LiteralPath $ImajYolu)) { Hata "Imaj bulunamadi: $ImajYolu" }
$imajBoyu = (Get-Item -LiteralPath $ImajYolu).Length
if ($imajBoyu % 512 -ne 0) { Hata 'Imaj boyutu 512 baytin kati degil; bu dogru bir disk imaji gibi gorunmuyor.' }

if (-not $MD5Atla) {
    Bilgi 'Imaj MD5 hesaplaniyor...'
    $md5 = (Get-FileHash -LiteralPath $ImajYolu -Algorithm MD5).Hash.ToLower()
    if ($md5 -ne $BilinenMD5) { Hata "Imaj MD5 uyusmuyor ($md5). Farkli/bozuk bir imaj olabilir. Eminsen -MD5Atla ile tekrar calistir." }
    Bilgi "MD5 dogru: $md5"
}

if (-not $MenuYolu) { $MenuYolu = Join-Path (Split-Path $PSScriptRoot -Parent) 'menu' }

if ($HedefDosya) {
    Bilgi "TEST MODU: dosyaya yaziliyor: $HedefDosya"
    $hedefAc = { $fs = [IO.File]::Open($HedefDosya, 'Create', 'ReadWrite'); $fs.SetLength($imajBoyu); $fs }
    Ham-Yaz $ImajYolu $hedefAc
    exit 0
}

if (-not (Test-Path -LiteralPath $MenuYolu)) { Hata "menu dosyasi bulunamadi: $MenuYolu" }
if ($DiskNo -lt 0) { Hata '-DiskNo gerekli. (Once -Liste ile diskleri gor.)' }

$disk = Get-Disk -Number $DiskNo -ErrorAction SilentlyContinue
if (-not $disk) { Hata "Disk $DiskNo bulunamadi." }
if ($disk.BusType -ne 'USB') { Hata "Disk $DiskNo USB degil ($($disk.BusType)). Guvenlik icin reddedildi." }
if ($disk.IsSystem -or $disk.IsBoot) { Hata "Disk $DiskNo sistem/boot diski. Reddedildi." }
if ($DiskNo -eq 0) { Hata 'Disk 0 reddedildi (genelde sistem diskidir).' }
if ($disk.Size -lt $imajBoyu) { Hata "Disk ($([math]::Round($disk.Size/1GB,1)) GB) imajdan ($([math]::Round($imajBoyu/1GB,1)) GB) kucuk." }
if (-not (Yonetici-mi)) { Hata 'Yonetici olarak calistirilmali (PowerShell''i "Yonetici olarak calistir" ile ac).' }

Bilgi ''
Bilgi "HEDEF: Disk $DiskNo  $($disk.FriendlyName)  $([math]::Round($disk.Size/1GB,1)) GB"
Bilgi 'Bu diskteki HER SEY SILINECEK.'
$beklenen = "EVET $DiskNo"
if (-not $Onay) { $Onay = Read-Host "Onaylamak icin tam olarak '$beklenen' yaz" }
if ($Onay -ne $beklenen) { Hata "Onay metni dogru degil (beklenen: '$beklenen'). Hicbir sey yazilmadi." }

if ($disk.PartitionStyle -ne 'RAW') { Bilgi 'Disk temizleniyor...'; Clear-Disk -Number $DiskNo -RemoveData -RemoveOEM -Confirm:$false; Start-Sleep -Seconds 2 }
$yol = "\\.\PhysicalDrive$DiskNo"
Ham-Yaz $ImajYolu ({ [HamDisk]::Ac($yol, $true) }.GetNewClosure())

Update-Disk -Number $DiskNo; Start-Sleep -Seconds 3
$bolumler = @(Get-Partition -DiskNumber $DiskNo | Get-Volume | Where-Object { $BolumEtiketleri -contains $_.FileSystemLabel -and $_.DriveLetter })
if ($bolumler.Count -eq 0) {
    Bilgi "UYARI: MODS bolumleri Windows'ta surucu harfi almadi. USB'yi cikarip tekrar tak, sonra menu dosyasini bolumlerin 'home' klasorune elle kopyala."
    exit 0
}
foreach ($b in $bolumler) {
    $hedefMenu = "$($b.DriveLetter):\home\menu"
    if (-not (Test-Path "$($b.DriveLetter):\home")) { Bilgi "UYARI: $($b.DriveLetter): ($($b.FileSystemLabel)) icinde home klasoru yok, atlandi."; continue }
    Copy-Item -LiteralPath $MenuYolu -Destination $hedefMenu -Force
    if ((Get-FileHash $hedefMenu).Hash -ne (Get-FileHash -LiteralPath $MenuYolu).Hash) { Hata "menu kopyasi dogrulanamadi: $hedefMenu" }
    Bilgi "menu kopyalandi ve dogrulandi: $hedefMenu  ($($b.FileSystemLabel))"
}
Bilgi ''
Bilgi 'TAMAM. USB''yi "Guvenli Kaldir" ile cikar. Windows "bicimlendirmek ister misiniz?" derse HAYIR de.'
Bilgi 'Sonraki adim: README.md "Kullanim" bolumu.'
