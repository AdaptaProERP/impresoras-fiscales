// Programa   : DLL_TFHKA_DOWNLOAD
// Fecha/Hora : 02/12/2023 04:45:33
// Prop�sito  : Descargar tfhkaif.dll
// Creado Por : Juan Navas
// Llamado por: RUNEXE_TFHKA
// Aplicaci�n :
// Tabla      :

#INCLUDE "DPXBASE.CH"

PROCE MAIN()
  LOCAL cDir :=oDp:cBin
  LOCAL cFile:=cDir+"tfhkaif.dll"
  LOCAL cUrl :="http://191.96.151.60/~ftp16402/descargas/terceros/tfhkaif.dll"

  IF !FILE(cFile)
     URLDownLoad(cUrl,cFile)
  ENDIF

RETURN FILE(cFile)
// EOF

