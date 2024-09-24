// Programa   : DLL_BEMATECH_Z
// Fecha/Hora : 24/06/2024 12:54:03
// Propósito  : Emitir reporte Z
// Creado Por :
// Llamado por:
// Aplicación :
// Tabla      :

#INCLUDE "DPXBASE.CH"

PROCE MAIN(cSerie,lTxt)

   DEFAULT lTxt:=.T.

   CursorWait()

   IF !EJECUTAR("DPSERIEFISCALLOAD",NIL,.T.)
      RETURN .F.
   ENDIF

   // Guardar el Registro Antes del Zeta (Luego del Z, la memoria fiscal se resetea)
   IF lTxt
     EJECUTAR("DLL_BEMATECH_LEETXT",.F.) // 
     EJECUTAR("DPDOCCLIZFF",cSerie)
   ENDIF

 //  EJECUTAR("DLL_BEMATECH",NIL,NIL,NIL,NIL,.T.,NIL,"Z")

   IF lTxt
     EJECUTAR("DLL_BEMATECH_VIEWZ",cSerie)
   ENDIF

RETURN .T.
// EOF
