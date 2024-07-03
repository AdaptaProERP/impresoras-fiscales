// Programa   : TFHKA_DATA
// Fecha/Hora : 09/11/2022
// Propósito  : Genera la data para la Impresora Fiscal
// Creado Por : Juan Navas/ Kelvis Escalante	
// Llamado por: DPDOCCLI_PRINT      
// Aplicación : FACTURACION CONVENCIONAL Y PUNTO DE VENTA
// Tabla      : DPDOCCLI
// Fecha/Hora : 01/09/2022 00:00:00

#INCLUDE "DPXBASE.CH"
#INCLUDE "FILEIO.CH"

PROCE MAIN(cCodSuc,cTipDoc,cNumero,cOption)
   LOCAL oTable
   LOCAL cWhere:="",cFile,cSql,cText:="",cSerie:=""
   LOCAL cUS,cNombre,cRIF,cDireccion,cTelefono,nTasa:=0,cTasa:="",cPrecio:="",nPrecio:=0,cCant:="",cDescri:=""
   LOCAL aPagos  :={},nLenP

   DEFAULT cCodSuc:=oDp:cSucursal,;
           cTipDoc:="TIK",;
           cNumero:=SQLGETMAX("DPDOCCLI","DOC_NUMERO","DOC_TIPDOC"+GetWhere("=",cTipDoc)),;
           cOption:="3"

   // cOption="7" -> Anular Factura

   nLenP:=oDp:nImpFisEnt        // Definible Ancho Numérico
   nLenP:=IF(nLenP=0,10,nLenP)  // Longitud del precio

   // guadamos el puerto

   cWhere:="DOC_CODSUC"+GetWhere("=",cCodSuc)+" AND "+;
           "DOC_TIPDOC"+GetWhere("=",cTipDoc)+" AND "+;
           "DOC_NUMERO"+GetWhere("=",cNumero)+" AND "+;
           "DOC_ACT"   +GetWhere("=",1      )+" AND "+;
           "DOC_TIPTRA"+GetWhere("=","D"    )

   IF Empty(cSerie)
      cSerie        :=SQLGET("DPDOCCLI","DOC_SERFIS",cWhere)
   ENDIF

   IF Empty(oDp:cImpFisCom)
      oDp:cImpFisCom:=SQLGET("DPSERIEFISCAL","SFI_PUERTO","SFI_LETRA"+GetWhere("=",cSerie))
   ENDIF

   FERASE("FACTURA.TXT",cText)

   cSql:=" SELECT  MOV_CODIGO,INV_DESCRI,MOV_TOTAL,DOC_OTROS,DOC_DCTO,MOV_PRECIO,MOV_DESCUE,MOV_CANTID,MOV_IVA,"+;
         " IF(CCG_NOMBRE IS NULL,CLI_NOMBRE,CCG_NOMBRE) AS CCG_NOMBRE,"+;
         " IF(CCG_DIR1   IS NULL,CLI_DIR1  ,CCG_DIR1  ) AS CCG_DIR1,"+;
         " IF(CCG_TEL1   IS NULL,CLI_TEL1  ,CCG_TEL1  ) AS CCG_TEL1,"+;
         " IF(CCG_RIF    IS NULL,CLI_RIF   ,CCG_RIF   ) AS CCG_RIF ,"+;
         " DOC_SERFIS "+;
         " FROM DPDOCCLI "+;
         " INNER  JOIN DPMOVINV       ON MOV_CODSUC=DOC_CODSUC AND MOV_TIPDOC=DOC_TIPDOC AND DOC_NUMERO=MOV_DOCUME AND MOV_APLORG"+GetWhere("=","V")+;
         " INNER  JOIN DPINV          ON MOV_CODIGO=INV_CODIGO "+;
         " LEFT   JOIN DPCLIENTESCERO ON CCG_CODSUC=DOC_CODSUC AND CCG_TIPDOC=DOC_TIPDOC AND CCG_NUMDOC=DOC_NUMERO "+;
         " INNER  JOIN DPCLIENTES     ON DOC_CODIGO=CLI_CODIGO "+;
         " WHERE DOC_CODSUC"+GetWhere("=",cCodSuc)+;
         "   AND DOC_TIPDOC"+GetWhere("=",cTipDoc)+;
         "   AND DOC_NUMERO"+GetWhere("=",cNumero)+;
         "   AND DOC_TIPTRA"+GetWhere("=","D"    )+;
         "   AND DOC_ACT"   +GetWhere("=",1      )

   oTable:=OpenTable(cSql,.T.)

   IF oTable:RecCount()=0
      oTable:End()
      cText:=""
      RETURN 
   ENDIF

   IF ISPCPRG()
      /*
      // Validaciones debe tener precios de 4Bs
      */
      oTable:Gotop()
      WHILE !oTable:Eof()
         oTable:REPLACE("MOV_TOTAL",4)
         oTable:DbSkip()
      ENDDO

      oTable:GoTop()
      // oTable:Browse()

   ENDIF

   oTable:GoTop()

   cUS        :=oDp:cUsuario
   cNombre    :=PADR(oTable:CCG_NOMBRE,20)
   cRIF       :=PADR(oTable:CCG_RIF   ,20)
   cDireccion :=PADR(oTable:CCG_DIR1  ,20)
   cTelefono  :=PADR(oTable:CCG_TEL1  ,20)

   IF cTipDoc = "DEV" .OR. cTipDoc="CRE"

      cText:=cText+CHR(105)+CHR(82)+CHR(42)+cRIF+CRLF
      cText:=cText+CHR(105)+CHR(83)+CHR(42)+cNombre+CRLF
      cText:=cText+CHR(105)+CHR(70)+CHR(42)+cNumero+CRLF
      cText:=cText+CHR(105)+CHR(68)+CHR(42)+DTOC(DATE())+CRLF
      cText:=cText+CHR(105)+CHR(73)+CHR(42)+oDp:cImpFisSer+CRLF // "Z6C3000509"+CRLF
      cText:=cText+"<TEXTO_CF,"+REPL("-",40)+",0>"+CRLF

   ELSE

      cText:=cText+CHR(105)+CHR(83)+CHR(42)+cNombre+CRLF
      cText:=cText+CHR(105)+CHR(82)+CHR(42)+cRIF+CRLF
      cText:=cText+CHR(105)+CHR(48)+CHR(51)+"Dir. :"+cDireccion+CRLF
      cText:=cText+CHR(105)+CHR(48)+CHR(52)+"Tlf. :"+cTelefono+" Cajero: "+cUS+CRLF
      cText:=cText+CHR(105)+CHR(48)+CHR(53)+"Ref. :"+cNumero+CRLF

   ENDIF

   oTable:Gotop()

   WHILE !oTable:Eof()

     nTasa    :=1+(oTable:MOV_IVA/100)
     cCant    :=STRZERO(oTable:MOV_CANTID*1000,8,0)
     nPrecio  :=(oTable:MOV_TOTAL/oTable:MOV_CANTID)/nTasa
     cPrecio  :=STRZERO(nPrecio*100,nLenP,0)
     cTasa    :=IIF(oTable:MOV_IVA<>0,CHR(33),CHR(32))
     cDescri  :=ALLTRIM(PADR(oTable:INV_DESCRI+SPACE(40),40))

     IF cTipDoc = "DEV" .OR. cTipDoc="CRE"
        cText    :=cText+"d"+cTasa+cPrecio+cCant+cDescri+CRLF
     ELSE
        cText    :=cText+cTasa+cPrecio+cCant+cDescri+CRLF
     ENDIF

     oTable:DbSkip()

  ENDDO

 
  oTable:Gotop()

  // Cierre de los Items
  // Antes era "3" ahor cOption
  cText:=cText+cOption+CRLF

  // Pagos
  aPagos:=EJECUTAR("SAMSUNG_PAGOS",cCodSuc,cTipDoc,cNumero)
  AEVAL(aPagos,{|cLine| cText:=cText+cLine+CRLF })

  // Cerrar el Documento, solo para impresoras con IGTF
  // cOption con valor "7" es Anular Ticket
  IF cOption="3"
    cText:=cText+"199"+CRLF
  ENDIF

  DPWRITE("FACTURA.TXT",cText)

RETURN cText
// EOF

