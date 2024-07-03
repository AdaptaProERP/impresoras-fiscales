// Programa   : RUNEXE_TFHKA_STATUS
// Fecha/Hora : 08/11/2022 10:45:13
// Propósito  : leer status de la impresora
// Creado Por : Juan Navas
// Llamado por:
// Aplicación :
// Tabla      :

#INCLUDE "DPXBASE.CH"

PROCE MAIN(cSerie)
  LOCAL cDir    :=CURDRIVE()+":"+"\"+"IntTFHKA"+"\"
  LOCAL cFileExe:=cDir+"IntTFHKA.exe"
  LOCAL cUrl    :="https://mega.nz/file/RQ9GUbhT#aWx7KTl4uo9FBNxZ2ZI_CKO5vgaLDkWlQtef9MrUaxA"

  IF oDp:lImpFisModVal
     RETURN .T.
  ENDIF

  EJECUTAR("IntTFHKA_DOWNLOAD") // 02/12/2023 descargar programa binario

  IF !FILE(cFileExe) 
     MsgMemo("Necesario Programa "+cFileExe+CRLF+"Descarguelo desde "+CRLF+cUrl+CRLF+"Descomprimalo en la carpeta "+cDir,"Dirección URL Copiada en ClipBoad")
     SHELLEXECUTE(oDp:oFrameDp:hWND,"open",cUrl)
     RETURN .F.
  ENDIF

  oDp:cMemoLog:=""

  lResp:=EJECUTAR("RUNEXE_TFHKA_CMD","STATUS","Estatus",cSerie)

  ? oDp:cMemoLog

RETURN lResp
// EOF
