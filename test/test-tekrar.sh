#!/bin/bash
# menu icindeki tekrar() fonksiyonunu sahte bir "mats" ile dener.
# Senaryo (6 tur): 1,3,6 PASS; 2,5 FAIL (ayni bolge/bit); 4 rapor yok.
# Calistirma: bash test/test-tekrar.sh   (proje klasorunun icinden)
# Not: gercek MATS calistirilmaz; Ctrl+C davranisi bu testte denenmez.

cd "$(dirname "$0")/.." || exit 1
. test/sahte-ortam.sh
sahte_taklit
sahte_kur P F:FBIOB0:B015 P Y F:FBIOB0:B015 P
menu_fonksiyonlari sayi_mi mats_var_mi oku_rapor nabiz_baslat nabiz_durdur kos tekrar
sor_mb() { MB=20; }
sor_gpu() { NARGS="-n 1"; ADI="GA104"; }

cikti="$(printf '6\n' | tekrar 2>&1)"
sahte_temizle

hata=0
kontrol() {
    if echo "$cikti" | grep -q "$1"; then echo "TAMAM : '$1' bulundu"
    else echo "HATA  : '$1' bulunamadi"; hata=1; fi
}
kontrol "Yapilan tur: 6   FAIL: 2   Rapor yok: 1"
kontrol "HATALI TURLAR: 2 5"
kontrol "FBIOB0 : 2 tur"
kontrol "B015 : 2 tur"
kontrol "4    RAPOR_YOK"
exit $hata
