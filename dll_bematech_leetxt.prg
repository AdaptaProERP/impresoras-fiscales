// Programa   : DLL_BEMATECH_LEETXT 
// Fecha/Hora : 24/06/2024 12:54:03
// Propósito  : Emitir reporte LEETOTAL EN RETORNO.TXT
// Creado Por : Juan Navas
// Llamado por:
// Aplicación :
// Tabla      :

#INCLUDE "DPXBASE.CH"

PROCE MAIN(lView)

   DEFAULT lView:=.T.

   CursorWait()
   EJECUTAR("DPSERIEFISCALLOAD")
   EJECUTAR("DLL_BEMATECH",NIL,NIL,NIL,NIL,.F.,NIL,"LEETXT")

   IF lView
      EJECUTAR("DPDOCCLIZFF",NIL,.T.)
   ENDIF

RETURN .T.
// EOF
