#!/bin/bash
# Otro ejercicio de programación en bash por JCRUEDA.com
# Carácter separador de campos del CSV (por defecto, ";") :
sep=";"
# Títulos de las columnas :
encabezado="Identificador;Tipo;Inicio;Conclusión;Cantidad reclamada;Lotes;Anuncio BOE;Valor subasta;Valor tasación;Puja mínima;Tramos;Depósito;Código;Descripción;Dirección;Teléfono;Fax;E-mail;Tipo de bien;Descripción del bien;Dirección del bien;Codigo postal;Localidad del bien;Provincia;Vivienda habitual;Situación posesoria;Visitable;Pujas recibidas;Enlace;"
echo "WSB v.0.1 · Webscrapping de Subastas en Bash · jcrueda.com""\n";
echo "Datos extraídos de la Agencia Estatal del Boletín Oficial del Estado y bajo licencia:""\n""https://www.boe.es/informacion/aviso_legal""\n";
sleep 1; echo " - - -";
echo -n "[?] Primeros dos dígitos del código postal: "; read prv;
echo -n "[?] Nombre del archivo CSV de salida: "; read csvf;
echo "[i] Cargando página inicial de provincia...";
lynx --dump "https://subastas.boe.es/subastas_ava.php?campo%5B1%5D=SUBASTA.ESTADO&dato%5B1%5D=EJ&campo%5B2%5D=BIEN.TIPO&dato%5B2%5D=I&campo%5B7%5D=BIEN.COD_PROVINCIA&dato%5B7%5D="$prv"&campo%5B16%5D=SUBASTA.FECHA_INICIO_YMD&dato%5B16%5D%5B0%5D=&dato%5B16%5D%5B1%5D=&page_hits=40&sort_field%5B0%5D=SUBASTA.FECHA_FIN_YMD&sort_order%5B0%5D=desc&sort_field%5B1%5D=SUBASTA.FECHA_FIN_YMD&sort_order%5B1%5D=asc&sort_field%5B2%5D=SUBASTA.HORA_FIN&sort_order%5B2%5D=asc&accion=Buscar" > buf.fer; 
echo "[!] Extrayendo links a subastas concretas";
grep "detalleSubasta" buf.fer | tr " " "\n" | grep "https" > subastas.txt;
alguna=$(grep "accion=Mas" buf.fer | tail -1 | xargs | cut -f2 -d" ");
if [ -z "$alguna" ]; then echo "[i] Sólo hay una página de links.";
else echo "[!] Hay varias páginas. Listándolas todas...";
siguiente=$(grep "id_busqueda=" buf.fer | tail -1 | cut -f4 -d" ");
pagina=$(echo "https://subastas.boe.es/subastas_ava.php?accion=Mas&id_busqueda=`echo $siguiente | cut -f3 -d"=" | cut -f1 -d"-"`-0-5000");
rm buf.fer subastas.txt; lynx --dump "$pagina" > buf.fer; 
grep "detalleSubasta" buf.fer | tr " " "\n" | grep "https" > subastas.txt;
echo "[i] Se han extraído todos los links a subastas concretas."; fi;
echo "[i] Se han encontrado `wc -l subastas.txt | cut -f1 -d" "` subastas."; 
sleep 3;
echo "$encabezado" > $csvf;
for line in `cat subastas.txt`; do clear;
echo " - - - \n [!] Guardando subasta `grep -n "$line" subastas.txt | cut -f1 -d ":" | awk "NR==1"` de `wc -l subastas.txt | cut -f1 -d" "` ... \n - - -"
lynx --dump "$line" > buf.fer;
grep "Lotes" buf.fer > /dev/null | awk "NR==1" | sed s/" Lotes "// > lotes
    if grep -q "Sin lotes" lotes > /dev/null; then lotes="NO";
    else lotes="SÍ"; fi; rm lotes;
PARTE1=$(echo "`grep "Identificador " buf.fer | xargs | cut -f2 -d" "`#`grep "Tipo de subasta " buf.fer | sed s/" Tipo de subasta "//`#`grep "Fecha de inicio" buf.fer | sed s/" Fecha de inicio "// | cut -f1 -d"(" | tr " " "\n" | grep -v "CET" | xargs`#`grep "Fecha de conclusión" buf.fer | sed s/" Fecha de conclusión "// | cut -f1 -d"(" | tr " " "\n" | grep -v "CET" | xargs`#`grep "Cantidad reclamada" buf.fer | sed s/" Cantidad reclamada "//`#`echo $lotes`#`grep "Anuncio BOE" buf.fer | sed s/" Anuncio BOE "//`#`grep "Valor subasta" buf.fer | sed s/" Valor subasta "//`#`grep "Tasación " buf.fer | sed s/" Tasación "//`#`grep "Puja mínima " buf.fer | sed s/" Puja mínima "//`#`grep "Tramos entre pujas" buf.fer | sed s/" Tramos entre pujas "//`#`grep "Importe del depósito " buf.fer | sed s/" Importe del depósito "//`" | xargs);
autoridadgestora=$(grep "ver=2" buf.fer | xargs | cut -f2 -d" ");
bienes=$(grep "ver=3" buf.fer | xargs | cut -f2 -d" ");
pujas=$(grep "ver=5" buf.fer | xargs | cut -f2 -d" ");
lynx --dump "$autoridadgestora" > buf.fer; 
PARTE2=$(echo "`grep "Código" buf.fer | sed s/" Código "// | xargs`#`grep "Descripción" buf.fer | sed s/" Descripción "//`#`grep "Dirección" buf.fer | tr ";" "-" | sed s/" Dirección "//`#`grep "Teléfono" buf.fer | sed s/" Teléfono "//`#`grep "Fax" buf.fer | sed s/" Fax "//`#`grep "Correo electrónico" buf.fer | sed s/" Correo electrónico "//`" | xargs)
# TODO: Soportar varios bienes y listarlos independientemente
lynx --width 999 --dump "$bienes" > buf.fer;
PARTE3=$(echo "`grep "Bien " buf.fer | awk "NR==1" | sed s/"Bien "//`#`grep "Descripción " buf.fer | xargs | sed s/"Descripción" | tr ";" ","//`#`grep "Dirección" buf.fer | xargs | sed s/" Dirección"//`#`grep "Código Postal" buf.fer | sed s/"Código Postal"// | xargs | cut -f1 -d" "`#`grep "Localidad " buf.fer | xargs | sed s/"Localidad"// | cut -f1 -d" "`#`grep "Provincia " buf.fer | awk "NR==1" | xargs | sed s/"Provincia"//`#`grep "Vivienda habitual" buf.fer | awk "NR==1" | xargs | sed s/"Vivienda habitual"//`#`grep "Situación posesoria " buf.fer | xargs | sed s/"Situación posesoria"//`#`grep "Visitable" buf.fer | awk "NR==1" | xargs | sed s/"Visitable"//`");
PARTE4=$(lynx --width 999 --dump "$pujas" | grep "Puja máxima actual de la subasta" -A 3 | grep -v "Puja máxima actual de la subasta" | xargs )
if grep -q "ha recibido alguna" "$PARTE4"; then PARTE4="Con pujas";
else PARTE4="Sin pujas"; fi;
echo $PARTE1"#"$PARTE2"#"$PARTE3"#"$PARTE4"#"$line | tr "#" "$sep" >> $csvf
done;
rm buf.fer subastas.txt lotes; clear;
echo "[!] Finalizado! Resultados almacenados en '$csvf'"
