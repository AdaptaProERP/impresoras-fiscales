// Programa   : DLL_BEMATECH_FAV
// Fecha/Hora : 24/06/2024 12:54:03
// Propósito  : Devuelve Ultimo Número de Factura
// Creado Por : Juan Navas
// Llamado por:
// Aplicación :
// Tabla      :

#INCLUDE "DPXBASE.CH"

PROCE MAIN(lSay,nLen,cSerie)
   LOCAL cNumero:=SPACE(10),nLenC

   IF Empty(oDp:cImpLetra)
      EJECUTAR("DPSERIEFISCALLOAD")
   ENDIF


   DEFAULT lSay  :=.F.,;
           nLen  :=10,;
           cSerie:=oDp:cImpLetra

   nLenC:=nLen-1

   oDp:cBemaFAV:=""

   EJECUTAR("DPSERIEFISCALLOAD")
   EJECUTAR("DLL_BEMATECH",NIL,NIL,NIL,NIL,lSay,NIL,"FAV")

// ? oDp:cBemaFAV,"oDp:cBemaFAV"

   cNumero:=CTOO(oDp:cBemaFAV,"N")+1 // Incrementa el siguiente número

   cNumero:=ALLTRIM(CTOO(cNumero,"C"))
   cNumero:=ALLTRIM(cSerie)+REPLI("0",nLenC-LEN(cNumero))+cNumero

RETURN cNumero
// eof


