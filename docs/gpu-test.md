# GPU-Test: Pop!_OS içinde memtest_vulkan ve FurMark

`gpu-test/t`, NVIDIA sürücüsü çalışırken (Pop!_OS canlı oturumu gibi) kartı **yük altında** denemek için küçük bir menü betiğidir. MATS/MODS sürücüden bağımsız çalışır; bu betik ise sürücünün kartı başlatabildiği durumlarda kullanılır. Karta NVIDIA sürücüsüyle erişilemiyorsa (`nvidia-smi` "No devices were found" diyorsa) bu araçlar çalışmaz.

## Betiğin yaptığı

| Menü | Ne yapar |
|---|---|
| 1 | `nvidia-smi` ile GPU bilgisi |
| 2 | `memtest_vulkan`, 10 dakika (VRAM ve GPU yükü) |
| 3 | `memtest_vulkan`, sınırsız (`Ctrl+C` ile bitir) |
| 4 | Canlı izleme: sıcaklık, güç, saat (`nvidia-smi -l 1`) |
| 5 | FurMark stres testi 10 dk (**masaüstü gerekir**) |
| 6 | FurMark arayüzü (**masaüstü gerekir**) |

Test sırasında sıcaklık/güç/saat/kullanım her saniye `loglar/` klasörüne CSV olarak yazılır, bitince en yüksek sıcaklık ve güç özeti gösterilir.

## Hazırlık

Bu depo **memtest_vulkan ve FurMark'ı içermez**. Kendin indirip şu düzende bir USB bellekte (ya da MATS USB'sinin boş yeri olan bir bölümünde) `GPU-Test` klasörü olarak yan yana koy:

```
GPU-Test/
  t                      <- bu depodaki gpu-test/t
  memtest_vulkan/
    memtest_vulkan       <- memtest_vulkan-v0.5.0_DesktopLinux_X86_64.tar.xz içinden
  FurMark2/
    FurMark_linux64/     <- FurMark 2 Linux x86_64 paketi (.7z) açılmış hali
```

- memtest_vulkan: https://github.com/GpuZelenograd/memtest_vulkan (Releases bölümü, `DesktopLinux_X86_64` dosyası).
- FurMark 2: https://www.geeks3d.com/furmark/downloads/ (Linux / x86_64, `.7z`).
- `t` dosyası **LF satır sonlarıyla** kalmalı (CRLF ile çalışmaz).

## Çalıştırma

USB'yi çalışan Pop!_OS oturumuna tak. Masaüstü açıksa USB kendiliğinden bağlanır:

```
bash /media/pop-os/<USB-ETIKETI>/GPU-Test/t
```

Masaüstü kapalıysa (metin konsolu) USB kendiliğinden bağlanmaz. Elle bağla:

```
sudo mkdir -p /mnt/g
sudo mount /dev/disk/by-label/<USB-ETIKETI> /mnt/g
bash /mnt/g/GPU-Test/t
```

`<USB-ETIKETI>` USB'nin bölüm etiketidir (`lsblk -f` ile bakılır).

## Notlar

- memtest_vulkan başlarken bir GitHub adresi ve başlık yazdırır, sonra yanıp sönen bir imleç bırakabilir; hemen satır yazmaması normal olabilir. Çalışıp çalışmadığını `nvidia-smi` ile (bellek kullanımı birkaç GB'a çıkar) kontrol et.
- Hibrit grafikli laptoplarda (Intel + NVIDIA) test sırasında memtest_vulkan'ın **NVIDIA** kartı seçtiğinden emin ol. Cihaz listesi sorarsa RTX/GeForce olanı seç. Liste sormuyorsa hangi kartı test ettiğini ekrandan oku.
- Testi yarıda durdurmak için `Ctrl+C`. Test çalışırken konsol değiştirmek (`Ctrl+Alt+F4`) bazı laptoplarda çalışmaz; bu durumda `Ctrl+Z` testi durdurur ve komut satırını geri verir, `bg` arka planda devam ettirir, `fg` öne alır, `kill %1` bitirir.
- memtest_vulkan hata bulursa ekrana `Error found ...` satırları ve bit tablosu yazar. Vulkan cihazı kaybolursa `ERROR_DEVICE_LOST` görürsün; bu, kartın test sırasında yanıt vermeyi bıraktığı anlamına gelir.
- Bu betik MATS menüsünden ayrı, daha basit bir araçtır. MATS/MODS menüsü için ana `README.md`'ye bak.
