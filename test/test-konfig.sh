#!/bin/bash
# Surum klasoru bulma ve ayar dosyasi (menu.conf) mantigini dener.
# Calistirma: bash test/test-konfig.sh   (proje klasorunun icinden)

cd "$(dirname "$0")/.." || exit 1
. test/sahte-ortam.sh
sahte_taklit

hata=0
kontrol() { # ad kosul-sonucu(0=iyi)
    if [ "$2" -eq 0 ]; then echo "TAMAM : $1"; else echo "HATA  : $1"; hata=1; fi
}

sahte_kur P
menu_fonksiyonlari sayi_mi konf_oku konf_yaz surumleri_bul surum_sec surum_belirle
# ikinci surum klasoru, ve mats icermeyen bir klasor (listede olmamali)
mkdir -p "$MATSMODS_HOME/455.diger" "$MATSMODS_HOME/nvmt_yok"
cp "$DIR/mats" "$MATSMODS_HOME/455.diger/mats"
KOK="$MATSMODS_HOME"; KONF="$KOK/menu.conf"

surumleri_bul
kontrol "mats iceren 2 klasor bulunur (nvmt klasoru yok sayilir)" $([ "${#SURUMLER[@]}" -eq 2 ] && echo 0 || echo 1)

# ilk acilis: 2 surum var -> sorar; 2. secenegi sec
DIR=""
surum_sec >/dev/null <<< "2"
kontrol "surum secimi DIR'e yazilir" $([ "$(basename "$DIR")" = "455.sahte" ] || [ "$(basename "$DIR")" = "455.diger" ] && echo 0 || echo 1)
kontrol "ayar dosyasi olusur" $([ -f "$KONF" ] && echo 0 || echo 1)
SECILEN="$DIR"

# yeniden acilis: ayar dosyasindan okur, sormaz
DIR=""; SURUM=""
surum_belirle </dev/null >/dev/null
kontrol "ayardan ayni surum geri okunur" $([ "$DIR" = "$SECILEN" ] && echo 0 || echo 1)

# GPU secimi kaydi
NARGS="-n 1"; ADI="GA104"; GPU_KAYIT=1; GPU_SECIM="$NARGS"; GPU_ADI="$ADI"; konf_yaz
GPU_KAYIT=0; GPU_SECIM=""; GPU_ADI=""; konf_oku
kontrol "GPU secimi (-n 1, GA104) ayardan okunur" $([ "$GPU_KAYIT" = "1" ] && [ "$GPU_SECIM" = "-n 1" ] && [ "$GPU_ADI" = "GA104" ] && echo 0 || echo 1)

# ayar dosyasi silinirse ve tek surum kalirsa kendiliginden secilir
rm -rf "$MATSMODS_HOME/455.diger" "$KONF"
DIR=""; SURUM=""
surum_belirle </dev/null >/dev/null
kontrol "tek surum varsa sormadan secilir" $([ "$(basename "$DIR")" = "455.sahte" ] && echo 0 || echo 1)

# hic surum yoksa hata verir
rm -rf "$MATSMODS_HOME/455.sahte" "$KONF"
DIR=""; SURUM=""
surum_belirle </dev/null >/dev/null 2>&1; rc=$?
kontrol "hic mats klasoru yoksa hata doner" $([ "$rc" -ne 0 ] && echo 0 || echo 1)

sahte_temizle
exit $hata
