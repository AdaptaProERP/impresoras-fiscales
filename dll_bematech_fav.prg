// Programa   : DLL_BEMATECH_FAV
// Fecha/Hora : 24/06/2024 12:54:03
// Prop�sito  : Devuelve Ultimo N�mero de Factura
// Creado Por : Juan Navas
// Llamado por:
// Aplicaci�n :
// Tabla      :

#INCLUDE "DPXBASE.CH"

PROCE MAIN()
   LOCAL cNumero:=SPACE(10)

   EJECUTAR("DPSERIEFISCALLOAD")
   cNumero:=EJECUTAR("DLL_BEMATECH",NIL,NIL,NIL,NIL,.T.,NIL,"FAV")

RETURN cNumero

