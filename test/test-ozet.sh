#!/bin/bash
# menu icindeki ozet() fonksiyonunu ornek raporlarla dener.
# Calistirma: bash test/test-ozet.sh   (proje klasorunun icinden)
# Not: ornek-rapor-pass.txt gercek bir cikti degil, el ile yazilmis kisa bir ornek.

cd "$(dirname "$0")/.." || exit 1
eval "$(sed -n '/^ozet()/,/^}/p' menu)"
eval "$(sed -n '/^mods_ozet()/,/^}/p' menu)"

hata=0
kontrol() {
    cikti="$(ozet "$1")"
    if echo "$cikti" | grep -q "$2"; then
        echo "TAMAM : $1 -> '$2' bulundu"
    else
        echo "HATA  : $1 -> '$2' bulunamadi"; hata=1
    fi
}

kontrol test/ornek-rapor-fail.txt "SONUC : FAIL - toplam 1 hata"
kontrol test/ornek-rapor-fail.txt "FBIOB0"
kontrol test/ornek-rapor-fail.txt "B015"
kontrol test/ornek-rapor-fail.txt "000048ec60"
kontrol test/ornek-rapor-pass.txt "SONUC : PASS"

# MODS logu: gecici, el ile yazilmis kisa ornekler
gecici="$(mktemp)"
trap 'rm -f "$gecici"' EXIT
mods_kontrol() {
    cikti="$(mods_ozet "$gecici")"
    if echo "$cikti" | grep -q "$1"; then echo "TAMAM : mods_ozet $1"; else echo "HATA  : mods_ozet $1"; hata=1; fi
}
printf 'MODS start\nTest 118 running\nError Code = 0 (ok)\nMODS end\n' > "$gecici"
mods_kontrol "SONUC : PASS"
printf 'MODS start\nmismatch at 0x1000\nError Code = 12 (memory error)\nMODS end\n' > "$gecici"
mods_kontrol "SONUC : FAIL"
printf 'MODS start\nTest 118 running\n' > "$gecici"
mods_kontrol "SONUC : BELIRSIZ"

exit $hata
