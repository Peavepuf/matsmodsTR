# Tanı rehberi: ekran kartı Linux'ta başlamıyorsa ne yapılır

Bu rehber, bir NVIDIA kartının (özellikle hibrit grafikli laptop) Linux'ta çalışmaması ya da kararsız olması durumunda **sırayla hangi testlerin yapılacağını** ve çıktıların ne anlama gelebileceğini toplar. Her yorum, belirsiz olduğu yerde "olabilir" diye yazılmıştır; hiçbir test tek başına "kart bozuk" demez.

## 0. Hazırlık

- Secure Boot kapalı olsun.
- Laptop şarjda olsun. Üretici adaptörünün watt değerini kontrol et (kartın gücü için yeterli olmalı).
- Yapılacak her deneyden sonra **çıktıyı kaydet** (not al ya da fotoğrafla).

## 1. Sürücüden bağımsız test (MATS/MODS)

Ana `README.md`'deki MATS/MODS USB'sini kullan. MATS kartı bulup test edebiliyorsa kartın temelde canlı olduğunu gösterir. Menüdeki **3 (Otomatik tanı)** testleri koşar ve karne verir; **5 (Tekrarlı test)** aralıklı hataları yakalamak için uygundur.

## 2. NVIDIA sürücüsüyle (Pop!_OS)

```
nvidia-smi
sudo dmesg | grep NVRM | head -8
cat /proc/driver/nvidia/version
```

| Gördüğün | Olası anlamı |
|---|---|
| `nvidia-smi` kart tablosu | Sürücü kartı başlatabildi |
| `No devices were found` | Sürücü kartı başlatamadı, `dmesg` satırlarına bak |
| `Booter failed ... 0xb`, `unexpected WPR2 already up`, `Cannot initialize GSP firmware RM`, `RmInitAdapter failed` | Kartın GSP firmware'i başlatılamadı. `WPR2 already up` çoğu zaman önceki bir hatanın sonucudur, asıl sebep olmayabilir |
| `Possible bad register read ... regvalue 0xbadf....` | Sürücü kartın bir yazmacını okuyamadı (kart yanıt vermiyor ya da anlamsız veri dönüyor). Donanım, güç ya da sürücü sürümü kaynaklı olabilir |

Birkaç deneme sonrası kartın bir ara görünebildiği (aralıklı çalışma) olabildi. Neyin kartı uyandırdığı belirlenemeyebilir; başarılı olursa `history | tail -20` ile komutları kaydet.

## 3. Farklı bir sürücü yolu (nouveau) ile karşılaştırma

NVIDIA sürücüsü başarısız, nouveau başarılıysa bu, kartın başlayabildiğini ama NVIDIA sürücüsünün/firmware'inin sorun yaşadığını **düşündürür** (nouveau farklı bir GSP firmware sürümü yükler). Bu, yük altında kararlılık hakkında bir şey söylemez.

SystemRescue gibi küçük, komut satırı tabanlı bir canlı sistemle (nouveau içerir) şunlara bak:

```
loadkeys <duzen>            # klavye düzenini ayarla (gerekirse; örn. trq = Türkçe Q, us = ABD)
lspci -nn | grep -i -E "nvidia|non-volatile"
sudo lspci -vv -s 01:00.0 | grep -E "LnkCap|LnkSta"
dmesg | grep -i -E "nouveau|nvme|aer|pcie bus error"
```

- `01:00.0` GPU'nun PCI adresidir; `lspci` çıktısından kendi kartının adresine bak.
- Başarılı nouveau başlatma satırları: `gsp: RM version`, `drm: VRAM: ... MiB`, `Initialized nouveau`.
- `Cannot find any crtc or sizes`: bu kartın ekran çıkışı yok demektir (ekran dahili grafikten geliyorsa beklenir), hata değildir.
- `_OSC: platform does not support [AER]`: firmware PCIe hata raporlamayı işletim sistemine bırakmıyor; zararsızdır ama PCIe hata kayıtlarına güvenemeyeceğini gösterir.

## 4. PCIe bağlantısı

`LnkCap` (desteklenen) ile `LnkSta` (şu anki) hız ve genişlik olarak aynı olmalıdır (örneğin `16GT/s x16`). Düşük hız ya da şerit sayısı bağlantı sorununa işaret edebilir. Tam hızda bağlantı, kartın içinin sağlam olduğunu **kanıtlamaz**.

## 5. Yük altında VRAM testi (sürücü çalışıyorsa)

`docs/gpu-test.md` içindeki `memtest_vulkan` testini çalıştır. Hata satırlarında `Error found`, ardından `ERROR_DEVICE_LOST` görürsen kart yük altında kararsız demektir. Sıcaklık/güç kaydı (CSV) ısı etkisini ayırt etmeye yarar: hatalar ısınınca başlıyorsa soğutmayı artırıp tekrarla.

## 6. MATS raporunu okuma

Bkz. ana `README.md` "Raporu okuma" ve "Otomatik tanı ve karne". Özetle:

- `FBIOxy` bellek bölümünü, `Bxxx` o bölümdeki bit numarasını gösterir.
- Tek bir bit tutarlı hata veriyorsa tek bir veri hattı sorunludur.
- **Art arda 8 bit** (örneğin 8-15) aynı bölümde birlikte hata veriyorsa bir bayt grubunun ortak sinyalinde sorun olabilir. Bu bir çıkarımdır; bit numaralarının fiziksel bayt gruplarına tam karşılığı MATS belgesinden doğrulanmadı.
- Hangi fiziksel çipe denk geldiği kart modeline göre değişir; bu betikler onu söylemez.

## 7. SSD de görünmüyorsa (laptop)

SSD'nin görünmemesi ile GPU hatası arasındaki bağlantı **kanıtlanmadı**. Ayırt etmek için:

1. `lspci`'de NVMe kontrolcüsü ("Non-Volatile memory controller") var mı? Yoksa SSD PCIe hattında hiç görünmüyordur. Intel VMD/RAID gizlemesi için listede "VMD" ya da "RAID" aranır.
2. M.2'yi çıkarıp **laptop kapalı, şarj ve pil bağlantısı sökülüyken** yeniden tak (açıkken sökme; kısa devre riski var).
3. SSD'yi çıkarıp GPU testini tekrarla. Sonuç değişmiyorsa SSD'nin etkisi yoktur.
4. SSD'yi başka bir bilgisayara ya da USB M.2 kutusuna tak, `smartctl -a /dev/nvme0n1` ile sağlığına bak.

VRAM veri hataları kartın kendi belleğinde oluşur; PCIe hattından geçmez. Bu yüzden SSD'nin doğrudan bu hataları üretmesi beklenmez. Ortak bir güç/anakart sorunu ise dışlanamaz.

## 8. Ne zaman servise gitmeli

Şunların bir kısmı birlikte görülüyorsa donanım servisi mantıklıdır: MATS'ta tutarlı hata (aynı bölüm/bitler), memtest_vulkan'da hatalar ve `ERROR_DEVICE_LOST`, NVIDIA sürücüsünün kartı başlatamaması, soğutma artırılınca düzelme olmaması. Servise bu rehberdeki sonuçları ve ham raporları götür.
