#!/bin/bash
# Testler icin sahte bir MATS ortami kurar. Dogrudan calistirilmaz; diger testler "source" eder.
# Kullanim: . test/sahte-ortam.sh <senaryo-satirlari...>
#   Her argüman bir turun sonucudur: P = PASS, Y = rapor yok,
#   F:<bolge>:<bit> = FAIL (ornek F:FBIOB0:B015)
# Ortam degiskenleri: T (gecici klasor), DIR (sahte MATS klasoru), REPDIR, MATSMODS_HOME

sahte_kur() {
    T=$(mktemp -d)
    MATSMODS_HOME="$T/home"; export MATSMODS_HOME
    mkdir -p "$MATSMODS_HOME/455.sahte"
    DIR="$MATSMODS_HOME/455.sahte"
    REPDIR="$MATSMODS_HOME/reports"
    : > "$T/senaryo"
    for x in "$@"; do echo "$x" >> "$T/senaryo"; done
    echo 0 > "$T/sayac"
    cat > "$DIR/mats" <<EOF
#!/bin/bash
c=\$(cat "$T/sayac"); c=\$((c+1)); echo \$c > "$T/sayac"
mb=5
while [ \$# -gt 0 ]; do [ "\$1" = "-e" ] && mb=\$2; shift; done
sc=\$(sed -n "\${c}p" "$T/senaryo")
[ -z "\$sc" ] && sc=P
[ "\$sc" = "Y" ] && exit 0
part=""; bit=""; w=0
case "\$sc" in F:*) part=\$(echo "\$sc" | cut -d: -f2); bit=\$(echo "\$sc" | cut -d: -f3); w=1 ;; esac
{
echo "mats version 455.107.  Testing GA104 with \$mb MB of memory starting with 0 MB."
echo "Read    Error Count: 0"
echo "Write   Error Count: \$w"
echo "Unknown Error Count: 0"
echo
echo "=== MEMORY ERRORS BY SUBPARTITION ==="
echo "SUBPART READ ERRORS WRITE ERRORS UNKNOWN ERRS"
echo "------- ----------- ------------ ------------"
for q in FBIOA0 FBIOA1 FBIOB0 FBIOB1 FBIOC0 FBIOC1 FBIOD0 FBIOD1; do
  if [ "\$q" = "\$part" ]; then echo "\$q 0 1 0"; else echo "\$q 0 0 0"; fi
done
if [ \$w -eq 1 ]; then echo; echo "Failing Bits: "; echo "\$bit "; fi
} > report.txt
EOF
    chmod +x "$DIR/mats"
}

# menu icindeki fonksiyonlari yukle (ayni isimlerle)
menu_fonksiyonlari() {
    for f in "$@"; do eval "$(sed -n "/^$f()/,/^}/p" menu)"; done
}

# ortak taklitler: ekrani/zamani etkileyen komutlari etkisiz yap
sahte_taklit() {
    tput() { :; }; clear() { :; }; sleep() { :; }; hwclock() { :; }
}

sahte_temizle() { rm -rf "$T"; }
