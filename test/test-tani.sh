#!/bin/bash
# Otomatik tani (menu 3) ve karne kararlarini sahte bir MATS ile dener.
# Calistirma: bash test/test-tani.sh   (proje klasorunun icinden)
# Not: Gercek ekran karti kullanilmaz; sadece karar mantigini sinar.

cd "$(dirname "$0")/.." || exit 1
. test/sahte-ortam.sh
sahte_taklit

hata=0
# senaryo(argumanlar...) -> "plan" -> beklenen metinler
dene() {
    ad="$1"; plan="$2"; beklenen="$3"; shift 3
    sahte_kur "$@"
    menu_fonksiyonlari sayi_mi mats_var_mi oku_rapor nabiz_baslat nabiz_durdur kos karne_yaz tani konf_yaz
    sor_gpu() { NARGS="-n 1"; ADI="GA104"; }
    cikti="$(printf '4\n%s\n\n' "$plan" | tani 2>&1)"
    if echo "$cikti" | grep -q "$beklenen"; then echo "TAMAM : $ad -> '$beklenen'"
    else echo "HATA  : $ad -> '$beklenen' bulunamadi"; echo "$cikti" | sed -n '1,40p'; hata=1; fi
    sahte_temizle
}

dene "hepsi PASS"          "5:4 20:2"  "KARAR: SAGLAM GORUNUYOR"      P P P P P P
dene "tek hata"            "5:6"       "KARAR: SUPHELI"                P P F:FBIOB0:B015 P P P
dene "tutarli hata"        "5:6"       "ARIZALI SUPHESI YUKSEK"        F:FBIOB0:B015 P F:FBIOB0:B015 F:FBIOB0:B014 P F:FBIOB0:B015
dene "dagilmis hatalar"    "5:6"       "ARIZALI SUPHESI (hatalar farkli" F:FBIOA0:A001 P F:FBIOB0:B002 P F:FBIOC0:C003 P
dene "rapor olusmuyor"     "5:3"       "KARAR: BELIRSIZ"               Y Y Y
dene "karnede cip adi"     "5:2"       "Cip / GPU      : GA104"        P P
dene "alt bolum sayisi"    "5:2"       "alt bolum sayisi: 8"           P P
dene "tutarli: bolge"      "5:6"       "En sik hata veren bolge: FBIOB0 (4 tur)" F:FBIOB0:B015 P F:FBIOB0:B015 F:FBIOB0:B014 P F:FBIOB0:B015
dene "hatali bit listesi"  "5:6"       "Hatali bitler (2 adet): B014 B015" F:FBIOB0:B015 P F:FBIOB0:B015 F:FBIOB0:B014 P F:FBIOB0:B015

exit $hata
