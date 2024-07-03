// Programa   : DLL_TFHKA_DOWNLOAD
// Fecha/Hora : 02/12/2023 04:45:33
// Propósito  : Descargar tfhkaif.dll
// Creado Por : Juan Navas
// Llamado por: RUNEXE_TFHKA
// Aplicación :
// Tabla      :

#INCLUDE "DPXBASE.CH"

PROCE MAIN()
  LOCAL cDir :=oDp:cBin
  LOCAL cFile:=cDir+"tfhkaif.dll"
  LOCAL cUrl :=oDp:cUrlDownLoad+"/descargas/terceros/tfhkaif.dll"

  IF !FILE(cFile)
     URLDownLoad(cUrl,cFile)
  ENDIF

RETURN FILE(cFile)
// EOF

