// Programa   : IntTFHKA_DOWNLOAD
// Fecha/Hora : 02/12/2023 04:45:33
// Propósito  : Descargar IntTFHKA.exe
// Creado Por : Juan Navas
// Llamado por: RUNEXE_TFHKA
// Aplicación :
// Tabla      :

#INCLUDE "DPXBASE.CH"

PROCE MAIN()
  LOCAL cDir :="C:\IntTFHKA\"
  LOCAL cFile:=cDir+"IntTFHKA.exe"
  LOCAL cUrl :="http://191.96.151.60/~ftp16402/descargas/terceros/IntTFHKA.exe"

  IF !FILE(cFile)
     LMKDIR(cDir)
     URLDownLoad(cUrl,cFile)
  ENDIF

RETURN FILE(cFile)
// EOF
