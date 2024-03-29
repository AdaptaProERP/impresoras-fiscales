// Programa   : DLL_EPSON_CMD
// Fecha/Hora : 26/04/2022 14:4:55
// Prop�sito  : LLamadas Epson DLL, Ejecutar comandos
// Creado Por :
// Llamado por:
// Aplicaci�n :
// Tabla      :

#INCLUDE "DPXBASE.CH"

PROCE MAIN(cCmd,cOption,cPar1,cPar2,cPar3)
  LOCAL oEpson,cFileLog,cError:="",cRet:=""
  LOCAL cFileLog,cEstatus,lClosed:=.F.

  DEFAULT cCmd:="PFrepz",;
          cOption:=cCmd,;
          oDp:lImpFisModVal:=.T.

  cFileLog:="TEMP\EPSON_"+DTOS(oDp:dFecha)+"_"+cCmd+".LOG"

  IF !Empty(cOption) .AND. Empty(cCmd)

    cCmd:=IF("Z"$UPPER(cOption),"PFrepz",cCmd)
    cCmd:=IF("X"$UPPER(cOption),"PFrepx",cCmd)
    cCmd:=IF("C"$UPPER(cOption),"PFCancelarDoc",cCmd)

  ENDIF

  FERASE(cFileLog)

  TDpClass():New(NIL,"oEpson")
  oEpson:hDll    :=NIL
  oEpson:cName   :="EPSON"
  oEpson:cFileDll:="pnpdll.dll"
  oEpson:cEstatus:=""
  oEpson:oFile   :=NIL
  oEpson:lError  :=.F.
  oEpson:lClosed :=.F.
  oEpson:lRuned  :=.F.

  IF !FILE(oEpson:cFileDll)
    MsgMemo("No se Encuentra Archivo "+oEpson:cFileDll)
    RETURN NIL
  ENDIF

//  cFileLog:="TEMP\"+DTOS(oDp:dFecha)+"_"+LSTR(SECONDS())+"_"+cCmd+".LOG"

  FERASE(cFileLog)

  IF !FILE(oEpson:cFileDll)
    MsgMemo("No se Encuentra Archivo "+oEpson:cFileDll)
    RETURN NIL
  ENDIF

  oEpson:oFile:=TFile():New(cFileLog)
  oEpson:hDll :=LoadLibrary(oEpson:cFileDll)
  oEpson:cPort:=RIGHT(oDp:cImpFisCom,1)

  IF !(Abs(oEpson:hDLL) > 32)
     MensajeErr("Error Leyendo Libreria "+oEpson:cFileDll)
     oEpson:IFCLOSE()
     RETURN ""
  ENDIF
 
  oEpson:IFOPEN(oEpson:cPort)

  // cEstatus:=oEpson:IFESTATUS()
  // oEpson:PFRUNCMD(cCmd,"")

  IF "X"$UPPER(cOption)
    oEpson:PFRUNCMD("PFrepx"    ,"")
    oEpson:PFRUNCMD("PFcierraNF","")
    oEpson:lClosed:=.T.
    oEpson:lRuned :=.T.
  ENDIF

  IF "Z"$UPPER(cOption)
    oEpson:PFRUNCMD("PFrepz"        ,"")
    oEpson:PFRUNCMD("PFcierrapuerto","")
    oEpson:lClosed:=.T.
    oEpson:lRuned :=.T.
  ENDIF

  // Ultima Factura
  IF "UF"$cCmd
    oEpson:lRuned :=.T.
    cRet:=oEpson:PFRUNCMD("PFultimo","10")
    cRet:=IF(oDp:lImpFisModVal,STRZERO(0,10),cRet)
  ENDIF

  IF "C"$UPPER(cOption) .AND. !oEpson:lRuned
    oEpson:lRuned :=.T.
    oEpson:PFRUNCMD("PFCancelarDoc","C","0")
  ENDIF

  // Otro Comando, enviado con par�metros
  IF !oEpson:lRuned
    oEpson:PFRUNCMD(cCmd,cPar1,cPar2,cPar3)
  ENDIF


  oEpson:IFCLOSE()
  SysRefresh(.T.)

  IF oEpson:lError
    cError:=MemoRead(cFileLog)
  ENDIF

  DPWRITE("TEMP\IMPFISCAL_CMD.TXT",cError)

  IF oDp:lImpFisModVal .OR. oEpson:lError
    VIEWRTF(cFileLog,"Comando "+cOption)
  ENDIF
  
  IF !Empty(cRet)
     RETURN cRet
  ENDIF

RETURN cError

/////////////////////////////////////////////////////
//                  FUNCIONES                      //
/////////////////////////////////////////////////////

FUNCTION IFOPEN(cPort)
  LOCAL cResp

  cResp:=oEpson:PFRUNCMD("PFabrepuerto",cPort)
  oEpson:IFESTATUS()

RETURN .T.

FUNCTION IFSHOWSTARTUS()
   MsgMemo(oEpson:cEstatus)
RETURN .T.

FUNCTION IFESTATUS()
  LOCAL cResp:=oEpson:PFRUNCMD("PFestatus","")
  oEpson:cEstatus:=""

   IF cResp = "TO"
      oEpson:cEstatus:="Se excedi� el tiempo de espera,"
      oEpson:lError:=.T.
   ENDIF

   IF cResp = "NP"
      oEpson:cEstatus:="Puerto no Abierto"
      oEpson:lError:=.T.
   ENDIF

   IF cResp = "ER"
      oEpson:cEstatus:="Existe un Error de Impresora"
      oEpson:lError:=.T.
   ENDIF

   IF !Empty(oEpson:cEstatus)
      oEpson:oFile:AppStr("Estatus "+oEpson:cEstatus)
   ENDIF

RETURN oEpson:cEstatus
/*
FUNCTION IFREPORTEX()
  oEpson:PFRUNCMD("PFrepx"      ,"")
  oEpson:PFRUNCMD("PFcierraNF"  ,"")
RETURN

FUNCTION IFREPORTEZ()
  oEpson:PFRUNCMD("PFrepz"        ,"")
  oEpson:PFRUNCMD("PFcierrapuerto","")
RETURN 
*/

FUNCTION PFRUNCMD(cFunc,cPar1,cPar2,cPar3,cPar4,cPar5,cPar6,cPar7,cPar8,cPar9)   
  LOCAL uResult, cFarProc, hDLL:=oEpson:hDll  

  IF !oDp:lImpFisModVal

    cFarProc:= GetProcAddress(hDLL,cFunc,.T.,8,8,8,8,8,8,8,8,8,8 )     
    uResult := CallDLL(cFarProc,cPar1,cPar2,cPar3,cPar4,cPar5,cPar6,cPar7,cPar8,cPar9)  

  ENDIF

  IF ValType(uResult)="C" .AND. uResult="ER"
    oEpson:lError:=.T.
    // oEpson:oFile:AppStr("Funci�n:"+cFunc+", Par�metro:"+cPar1+", Respuesta="+uResult+CRLF)
  ENDIF

  IF ValType(uResult)="C" .AND. uResult="ER"
    oEpson:lError:=.T.
  ENDIF

  DEFAULT cPar1:="",cPar2:="",cPar3:="",cPar4:="",cPar5:="",cPar6:="",cPar7:="",cPar8:="",cPar9:=""

  oEpson:oFile:AppStr(cFunc+",1->"+cPar1+",2->"+cPar2+",3->"+cPar3+",->"+cPar4+;
                            ",5->"+cPar5+",6->"+cPar6+",7->"+cPar7+",->"+cPar8+;
                            ",9->"+cPar9+",Result->"+CTOO(uResult,"C")+CRLF)

  SysRefresh(.T.)

RETURN uResult

FUNCTION IFCLOSE()

   IF !oEpson:lClosed
     oEpson:PFRUNCMD("PFcierrapuerto","")
   ENDIF

   FreeLibrary(oEpson:hDLL ) 
   oEpson:hDLL:=NIL

   IF !oEpson:oFile=NIL
     oEpson:oFile:Close()
   ENDIF

RETURN 

/*
// Obtiene ultimos Valores de la Impresora
PFultimo: 0000,0000,44,00,45,200312,143427,0035,0000,00053574,00000662,0815
Campo 1 Estado Impresora <0000>
Campo 2 Estado Fiscal <0000>
Campo 3 Ultimo valor de Secuencia
Campo 4 C�digo del Estado actual de la impresora
Campo 5 C�digo �ltimo comando ejecutado
Campo 6 Fecha en la Impresora Fiscal �AAMMDD�
Campo 7 Hora en la Impresora Fiscal �HHMMSS�
Campo 8 N�mero Factura fiscal del periodo fiscal
Campo 9 N�mero Documento no Fiscal del periodo fiscal
Campo 10 N�mero Factura fiscal acumulado
Campo 11 N�mero Documento no Fiscal acumulado
Campo 12 N�mero �ltimo reporte Z
*/
FUNCTION IFPFULTIMO(cPar1)
  LOCAL cResp

  cResp:=oEpson:PFRUNCMD("PFultimo",cPar1)

RETURN cResp
// EOF



