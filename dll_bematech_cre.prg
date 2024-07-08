// Programa   : DLL_BEMATECH_CRE
// Fecha/Hora : 24/06/2024 12:54:03
// Propósito  : Devuelve Ultimo Número de Nota de Crédito/Devolución
// Creado Por : Juan Navas
// Llamado por:
// Aplicación :
// Tabla      :

#INCLUDE "DPXBASE.CH"

PROCE MAIN()
   LOCAL cNumero:=SPACE(10),nLenC

   IF Empty(oDp:cImpLetra)
      EJECUTAR("DPSERIEFISCALLOAD")
   ENDIF


   DEFAULT lSay  :=.F.,;
           nLen  :=10,;
           cSerie:=oDp:cImpLetra

   nLenC:=nLen-1

   EJECUTAR("DPSERIEFISCALLOAD")
   EJECUTAR("DLL_BEMATECH",NIL,NIL,NIL,NIL,lSay,NIL,"CRE")

   cNumero:=oDp:uBemaResp+1 // Incrementa el siguiente número

   cNumero:=CTOO(cNumero,"C")
   cNumero:=cSerie+REPLI("0",nLenC-LEN(cNumero))+cNumero

RETURN cNumero
// eof

