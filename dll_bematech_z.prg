// Programa   : DLL_BEMATECH_Z
// Fecha/Hora : 24/06/2024 12:54:03
// Prop�sito  : Emitir reporte Z
// Creado Por :
// Llamado por:
// Aplicaci�n :
// Tabla      :

#INCLUDE "DPXBASE.CH"

PROCE MAIN()

   EJECUTAR("DPSERIEFISCALLOAD")
   EJECUTAR("DLL_BEMATECH",NIL,NIL,NIL,NIL,.T.,NIL,"Z")
RETURN
