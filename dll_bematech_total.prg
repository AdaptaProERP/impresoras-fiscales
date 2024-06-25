// Programa   : DLL_BEMATECH_TOTAL
// Fecha/Hora : 24/06/2024 12:54:03
// Propósito  : Devuelve Totalizadores
// Creado Por : Juan Navas
// Llamado por:
// Aplicación :
// Tabla      :

#INCLUDE "DPXBASE.CH"

PROCE MAIN()
   LOCAL cTotal:=SPACE(445)
   EJECUTAR("DPSERIEFISCALLOAD")

   cTotal:=EJECUTAR("DLL_BEMATECH",NIL,NIL,NIL,NIL,.T.,NIL,"TOTAL")

   IF !Empty(cTotal)
      ? cTotal,"TOTAL"
   ENDIF

RETURN cTotal
// EOF


