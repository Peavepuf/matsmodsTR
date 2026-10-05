# matsmodstr: NVIDIA VRAM testi için Türkçe menü (MATS/MODS)

NVIDIA'nın MATS/MODS araçlarını numaralı Türkçe bir menüden kullanmanı sağlayan betik. Laptop/masaüstü NVIDIA kartının VRAM'ini test eder, sonucu özetler ve **otomatik tanı** modunda sonunda bir **karne** verir (kart sağlam görünüyor mu, hangi bellek bölümü/bit hatalı, ne yapılmalı).

Menü, MATS/MODS içeren bir TinyLinux USB imajının içinde çalışır. Linux'ta NVIDIA sürücüsü gerekmez.

> Bu depo MATS, MODS veya USB imajını **içermez** (NVIDIA'nın kapalı kaynaklı araçları). Sadece menü, kurulum betiği, belgeler ve testler var.
>
> Karne yazılımsal bir tahmindir, kesin teşhis değildir.

## Proje yapısı

| Dosya | Ne işe yarar |
|---|---|
| `menu` | Ana araç: Türkçe MATS/MODS menüsü |
| `kurulum/Kur-USB.ps1` | Windows'ta imajı USB'ye yazar, doğrular, `menu`'yü kopyalar |
| `gpu-test/t` | Pop!_OS'ta memtest_vulkan/FurMark menüsü ([kullanım](docs/gpu-test.md)) |
| `docs/teshis-rehberi.md` | Kart sorunluysa hangi testler sırayla yapılır |
| `test/` | Örnek raporlar ve betik testleri |

## Kurulum

1. [Levirepair forumundan](https://levirepair.eu/infusions/forum/viewthread.php?thread_id=3&pid=3) "Nvidia MATS & MODS USB stick (with NVMT)" paketini indir, 7-Zip ile aç (`MODS From 60GB 1-11-2023 with NVMT.img`). Sayfadaki MD5: `3cc2ce1e4b9836548a8fad6479a2c4c3`.
2. 8 GB+ bir USB tak (**içindekiler silinir**).
3. PowerShell'i yönetici aç ve USB'leri listele:

   ```powershell
   cd <depo-yolu>\kurulum
   .\Kur-USB.ps1 -Liste
   ```

4. Yaz (MD5 kontrolü, `EVET <No>` onayı, ham yazma ve bayt bayt doğrulama yapar, ~15 dk):

   ```powershell
   .\Kur-USB.ps1 -ImajYolu "C:\yol\MODS From 60GB 1-11-2023 with NVMT.img" -DiskNo <No>
   ```

5. USB'yi güvenli kaldır. Windows "biçimlendirilsin mi?" derse **HAYIR**.
6. Hedef PC'de Secure Boot'u kapat, USB'den UEFI boot et, `cd /home` ve `./menu`.

Betik sadece USB tipindeki, sistem/boot olmayan diske yazar. Dosyaya yazma/doğrulama kısmı ve güvenlik reddetmeleri test edildi; fiziksel diske yazma kısmı gerçek bir diskte denenmedi.

**Elle kurulum:** paketteki Rufus 3.21 ile `.img`'yi DD modunda yaz, sonra `menu` dosyasını bölümün `home` klasörüne kopyala (LF satır sonu bozulmasın, Not Defteri'yle kaydetme). Forumdaki "bare-bone" paketler MATS/MODS içermez, tam imaj lazım.

### Hangi bölüm hangi kart için?

| Bölüm | Genelde uygun kartlar |
|---|---|
| `MODS30xx` | RTX 30xx |
| `MODS5x-20xx` | GTX 10xx/16xx, RTX 20xx ve eskiler |

40xx/50xx için doğrulamadık. UEFI'de bu imajda ilk bölüm (`MODS30xx`) açıldı; eski kartlar için ikinci bölümü UEFI'de nasıl açacağını denemedik (imajın `Patch notes.txt`'ine bak). `Kur-USB.ps1` menüyü iki bölüme de kopyalar.

## İlk açılış ve ayar

1. `cd /home`, `./menu` (çalışmazsa `bash menu`).
2. Menü `/home` altında `mats` içeren klasörleri kendisi bulur. Birden çoksa listeden kartına uygununu seç (adında modelin geçiyorsa onu, yoksa aile sürümünü; sonradan `v` ile değişir).
3. Menü **3** veya **5**'te "GPU" sorusuna Enter de: `-n 1`, `-n 0`, `-n yok` sırayla 5 MB testle denenir, çalışan seçilip kaydedilir.
4. Kart bulunamazsa ve ekran dahili GPU'dan geliyorsa önce menü **2** (`modsinit`).

Seçimler `/home/menu.conf` dosyasına kaydedilir (silersen sıfırlanır):

```
SURUM="/home/455.107_SKU10_3070"
GPU_KAYIT="1"
GPU_SECIM="-n 1"
GPU_ADI="GA104"
```

Kendi kartının MODS/MATS paketini eklemek için klasörü (içinde `mats`, MODS için `mods` ve `gputest.js` olacak) bölümün `home`'una kopyala; menüde `v` ile seç.

## Kullanım

| Menü | Ne yapar |
|---|---|
| 1 | Kart bilgisi (PCIe, bağlantı hızı) |
| 2 | `modsinit` |
| **3** | **Otomatik tanı + karne** |
| 4 | Tek MATS testi |
| 5 | Tekrarlı MATS testi |
| 6 | MODS tam GPU testi (gerçek kartta denenmedi) |
| 7 / 8 | Son rapor özeti / tamamı |
| 9 | Kayıtlı rapor ve karneler |
| m | Son MODS log özeti |
| l | Çalışma kayıtları (kilitlenme anı) |
| v | Sürüm klasörünü değiştir |
| k / 0 | Kapat / komut satırı |

Menü yazıları bilerek ASCII (ş, ğ, ı yok). TinyLinux konsolu ABD klavyesiyle açılır; Türkçe Q için imajda `loadkeys trq` varsa kullanılabilir.

## Otomatik tanı ve karne (menü 3)

| Profil | Turlar |
|---|---|
| 1 Hızlı | 5 MB ×5, 20 MB ×3, 100 MB ×2 |
| 2 Normal | 5 MB ×10, 20 MB ×6, 100 MB ×4 |
| 3 Uzun | 5 MB ×30, 20 MB ×15, 100 MB ×10 |
| 4 Özel | `5:10 20:5 100:2` gibi `MB:tekrar` planı |

Test boyutu 5-100 MB ile sınırlı. Başlamadan tahmini süre gösterilir. `Ctrl+C` o anki turu bitirir ve o ana kadarki sonuçla karne yazar. Karne `/home/reports/karne-*.txt` dosyasına kaydedilir.

| Durum | KARAR |
|---|---|
| Hata yok, tüm raporlar oluştu | SAĞLAM GÖRÜNÜYOR (sadece denenen kısım için) |
| Hata yok ama bazı turlarda rapor oluşmadı | BELİRSİZ |
| Toplam 1 tur hatalı | ŞÜPHELİ |
| 2+ tur hatalı, aynı bölüm hatalı turların en az yarısında | ARIZALI ŞÜPHESİ YÜKSEK |
| 2+ tur hatalı, dağınık | ARIZALI ŞÜPHESİ |

Eşikleri bu proje seçti, NVIDIA'nın değil.

**Sınırlar:** MATS her turda belleğin aynı başlangıcını (0. MB'tan itibaren) test eder, yani büyük VRAM'in küçük kısmı denenir. Hatanın hangi fiziksel çipte olduğunu söylemez. Isınınca çıkan hatalar kısa testte görünmeyebilir; bunun için `docs/gpu-test.md`.

## Raporu okuma

```
SONUC : FAIL - toplam 1 hata
HATALI BELLEK BOLGELERI (sadece hatasi olanlar):
  FBIOB0  okuma:0  yazma:1  bilinmeyen:0
HATALI BITLER (harf=bellek bolumu, sayi=bit no):
  B015
HATALI ADRESLER:
  000048ec60 55555555 5555d555 00008000 WB0700 B015
```

- Tek hata kesin arıza değildir; tekrarla. Aynı bölge/bit/adres tekrar ediyorsa tutarlıdır.
- Aynı bölümde art arda çok bit (8-15 gibi) hatalıysa tek hücreden çok ortak sinyal/bağlantı sorunu olabilir (çıkarım, doğrulanmadı).
- Yanıp sönen imleç sahte hata üretebilir; menü test sırasında imleci gizler.

## Kilitlenme ve süre

Test sırasında menü 5 saniyede bir `/home/reports/calisma-*.log` dosyasına yazar. Sistem kilitlenirse son satır sistemin son çalıştığı anı gösterir; `bitis:` satırı yoksa test normal bitmemiştir (menü `l`).

MATS ilerleme göstermez. Bir kartta 20 MB ~20 sn, 100 MB 1-2 dk sürdü.

## Sınırlamalar

- Tek test, tekrarlı test, rapor özeti ve kilitlenme kaydı gerçek bir kartta denendi. Otomatik tanı, karne, otomatik GPU bulma ve `menu.conf` sadece sahte MATS ile test edildi.
- MODS (menü 6) gerçek kartta denenmedi.
- Takılan MATS'ı menü sonlandırmaz; `Ctrl+C` yap, `-n`'i elle yaz.
- GPU Linux'ta çalışmıyorsa bu VRAM hatası demek değil, bkz. `docs/teshis-rehberi.md`.

## Testler

```
bash test/test-ozet.sh
bash test/test-tekrar.sh
bash test/test-tani.sh
bash test/test-konfig.sh
```

Sadece betik mantığını sınar, gerçek kart gerekmez.

## Lisans

Henüz seçilmedi.
