// Programa   : DLL_TFH_INI
// Fecha/Hora : 15/11/2022 10:23:43
// Propósito  : Inicia y Devuelve e
// Creado Por :
// Llamado por:
// Aplicación :
// Tabla      :

#INCLUDE "DPXBASE.CH"

FUNCTION MAIN_INI(cPuerto)
  LOCAL cError  :="",nError

  
 
  DEFAULT cPuerto :=oDp:cImpFisCom

  IF !TYPE("oTFH")="O"
    TDpClass():New(NIL,"oTFH")
  ENDIF

  oTFH:hDll    :=NIL
  oTFH:cName   :="TFH"
  oTFH:cFileDll:="tfhkaif.dll"
  oTFH:cEstatus:=""
  oTFH:oFile   :=NIL
  oTFH:lError  :=.F.
  oTFH:nContEnc:=0
  oTFH:nStatus :=0
  oTFH:nError  :=0
  oTFH:cCmd    :=""
  oTFH:lError  :=.F.

  IF !FILE(oTFH:cFileDll)
    MsgMemo("No se Encuentra Archivo "+oTFH:cFileDll)
    RETURN NIL
  ENDIF

  oTFH:oFile   :=TFile():New(oTFH:cFileLog)

  oDp:nSAMSUNGDll := If(oDp:nSAMSUNGDll == nil,LoadLibrary(oTFH:cFileDll),oDp:nSAMSUNGDll ) 
  cPuerto         := If(cPuerto == nil,"COM6",cPuerto )

  IF ValType(oDp:nSAMSUNGDll)!="N" .And. oDp:nSAMSUNGDll!=0

     cError:=TFH_ERROR(999,.T.)

  ELSE

     nError:=DpOpenFpctrl(cPuerto)
     IF nError != 1 .And. nError != 0
        cError:=TFH_ERROR(nError,.T.,.T.)
     ENDIF

     IF !EMPTY(cError)
        oTFH:lError:=.T.
        DpCloseFpctrl ()
     ENDIF

  ENDIF

  oTFH:cError  :=cError

RETURN oTFH
// EOF
