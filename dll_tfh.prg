// Programa   : DLL_TFH
// Fecha/Hora : 22/08/2022 11:19:17
// Propósito  : Imprimir con impresora THEFACTORY
// Creado Por : Juan Navas/Kelvis Escalante
// Llamado por: DPDOCCLI_PRINT      
// Aplicación : Facturación/Punto de Venta
// Tabla      : DPDOCCLI/DPMOVINV
// Manual     : https://github.com/AdaptaProERP/impresoras-fiscales/blob/main/%5BVE%5DManual%20de%20Protocolos%20y%20Comandos%20Venezuela%20V0805R00-1.pdf
#INCLUDE "DPXBASE.CH"

PROCE MAIN(cCodSuc,cTipDoc,cNumero,cOption,cCmd)
  LOCAL nStatus:=0,lError:=.F.,cError:="",nError:=0,cMsgErr:="",oTable
  LOCAL cPuerto  :=oDp:cImpFisCom,aData:={},I,lRet:=.T.,nLinErr:=0
  LOCAL cFilePag:="",nNumero,cData:="",lSave:=.F.,cFile,cMemo:="",cTipo:="SIMP" 

  DEFAULT cCodSuc  :=oDp:cSucursal,;
          cTipDoc   :="TIK",;
          cNumero   :=SQLGETMAX("DPDOCCLI","DOC_NUMERO","DOC_TIPDOC"+GetWhere("=",cTipDoc)),;
          cOption   :="3",;
          cCmd      :=""

  EJECUTAR("DLL_TFHKA_DOWNLOAD") // Valida y descarga tfhkaif.dll


//  oDp:lImpFisModVal:=.F.

  WHILE EMPTY(TFH_INI(oDp:cImpFisCom)) .OR. oTFH:lError

    IF oDp:lImpFisModVal
       EXIT
    ENDIF

    IF !MsgNoYes("Encienda la Impresora","Desea Reintentar ")
      TFH_END()
      RETURN .F.
    ENDIF

  ENDDO

  IF oTFH:lError .AND. !oDp:lImpFisModVal
     MensajeErr("Error "+LSTR(oTFH:nStatus)+" Inicializando el puerto", "Impresora "+oDp:cImpFiscal)
     TFH_END()
     RETURN .F.
  ENDIF

  oDp:cImpFiscalSqlPagos:=""

  /*
  // utilizado para REPORTZ o REPORTEX
  */
  IF Empty(cCodSuc) .AND. ("Z"$cCmd .OR. "X"$cCmd .OR. "7"$cCmd .OR. "GETFAV"$cCmd)

     IF "X"$cCmd
       lError:=REPORTEX()
       cTipo :="REPX"
     ENDIF

     IF "Z"$cCmd
        lError:=REPORTEZ()
        cTipo :="REPZ"
     ENDIF

     IF "7"$cCmd
        lError:=TFHRESERT()
        cTipo :="RESE"
     ENDIF

     IF "GETFAV"$cCmd
        ? "LEER ULTIMO NUMERO DE FACTURA DESDE THEFACTORY"


        cTipo:=DpGetData()

? cTipo,"cTipo",oTFH:cData

     ENDIF

  ELSE
  
     oDp:cImpFiscalSqlPagos:=""

    // Obtiene la Data del Ticket
    cData   :=EJECUTAR("TFHKA_DATA",cCodSuc,cTipDoc,cNumero,cOption)
    cFilePag:="temp\"+cTipDoc+cNumero+".pag"
    
    IF .T. // JN 21/11/2023 !oDp:lImpFisModVal 
       aData   :=STRTRAN(cData,CRLF,CHR(10))
       aData   :=_VECTOR(aData,CHR(10))
    ENDIF

    IF Empty(aData)
       MsgMemo("Documento "+cTipDoc+" "+cNumero+" no tiene Items")
       TFH_END()
       RETURN .F.
    ENDIF

 
  ENDIF

  /*
  // Caso de utilizar bloque de código y reemplazar el FOR/NEXT
  AEVAL(aData,{|a,I| DpSendCmd(@nStatus,@nError,aData[I]),;
                     cError :=TFH_ERROR(oTFH:nError,.T.),;
                     cMsgErr:=IF(Empty(cError),cMsgErr,cMsgErr+IF(Empty(cMsgErr),"",CRLF)+aData[I]+"->"+cError)})

  lError:=!Empty(cMsgErr)
  */

  FOR I=1 TO LEN(aData)

    DpSendCmd(@nStatus,@nError,aData[I])
    cError:=TFH_ERROR(oTFH:nError,.T.)

    IF !Empty(cError)
       nLinErr:=I
       lError:=.T.
       cMsgErr:=cMsgErr+IF(Empty(cMsgErr),"",CRLF)+aData[I]+"->"+cError
       EXIT
    ENDIF

  NEXT I

  IF nLinErr=1 .AND. !oDp:lImpFisRegAud
    cMsgErr:="Debe Resetear la Impresora, Error en la Primera Línea "+CRLF+cMsgErr
  ENDIF

  IF lError .OR. oDp:lImpFisRegAud .OR. oDp:lImpFisModVal
     cTipo:="NIMP" // ticket no impreso
     lSave:=.T.
  ENDIF

  IF lSave

    IF !Empty(oDp:cImpFiscalSqlPagos) .AND. (oDp:lImpFisRegAud .OR. oDp:lImpFisModVal)
       OpenTable(oDp:cImpFiscalSqlPagos):CTOTXT(cFilePag)
    ENDIF

    IF Empty(cData)
      cMemo:=MemoRead(oTFH:cFileLog) // Traza
    ELSE
      cMemo:=cData+CRLF+cMemo+CRLF+IF(Empty(cFilePag),"","PAGOS:"+MemoRead(cFilePag)+CRLF)+oDp:cImpFiscalSqlPagos+CRLF+MemoRead(oTFH:cFileLog) // Traza
    ENDIF

    AUDITAR(cTipo , NIL ,"DPDOCCLI" , cTipDoc+cNumero )

    IF lError .AND. !oDp:lImpFisRegAud
      MsgMemo("Ticket no Impreso"+CRLF+cMsgErr,"Error en Impresora "+oDp:cImpFiscal)
      lRet:=.F.
    ENDIF

    nNumero:=SQLINCREMENTAL("DPAUDITOR","AUD_NUMERO","AUD_SCLAVE"+GetWhere("=","TFHK"))
    oTable:=OpenTable("SELECT * FROM DPAUDITOR",.F.)
    oTable:Append()
    oTable:Replace("AUD_FECHAS",oDp:dFecha   )
    oTable:Replace("AUD_FECHAO",DPFECHA()    )
    oTable:Replace("AUD_HORA  ",HORA_AP()    )
    oTable:Replace("AUD_TABLA ","DPDOCCLI"   )
    oTable:Replace("AUD_CLAVE ",cCodSuc+cTipDoc+cNumero)

    IF !Empty(cCmd)
      oTable:Replace("AUD_CLAVE ",cCmd)
    ENDIF

    oTable:Replace("AUD_USUARI",oDp:cUsuario )
    oTable:Replace("AUD_ESTACI",oDp:cPcName  )
    oTable:Replace("AUD_IP"    ,oDp:cIpLocal )
    oTable:Replace("AUD_TIPO"  ,cTipo        ) // No impreso/Anulado
    oTable:Replace("AUD_MEMO"  ,cMemo        )
    oTable:Replace("AUD_SCLAVE","TFHK"       )
    oTable:Replace("AUD_NUMERO",nNumero      )
    oTable:Commit()
    oTable:End(.T.)

    cFile:="temp\"+cCmd+cTipDoc+cNumero+"_"+LSTR(SECONDS())+".txt"

    FERASE(cFile)
    DPWRITE(cFile,cMemo)

    IF oDp:lImpFisModVal .OR. lError .OR. !Empty(cCmd)
      VIEWRTF(cFile,"Documento "+cTipDoc+cNumero+cCmd)
    ENDIF

  ENDIF

  IF !lError .AND. !oDp:lImpFisModVal

    SQLUPDATE("DPDOCCLI","DOC_IMPRES",.T.,"DOC_CODSUC"+GetWhere("=",cCodSuc )+" AND "+;
                                          "DOC_TIPDOC"+GetWhere("=",cTipDoc )+" AND "+;
                                          "DOC_NUMERO"+GetWhere("=",cNumero )+" AND "+;
                                          "DOC_TIPTRA"+GetWhere("=","D"     ))
  ENDIF

  TFH_END()

  SysRefresh(.T.)

RETURN lRet

FUNCTION TFH_INI(cPuerto)
  LOCAL cError  :="",nError

  DEFAULT cPuerto :=oDp:cImpFisCom

  IF !TYPE("oTFH")="O"
    TDpClass():New(NIL,"oTFH")
  ENDIF

  oTFH:hDll     :=NIL
  oTFH:cName    :="TFH"
  oTFH:cFileDll :="tfhkaif.dll"
  oTFH:cEstatus :=""
  oTFH:oFile    :=NIL
  oTFH:lError   :=.F.
  oTFH:nContEnc :=0
  oTFH:cTipDoc  :=cTipDoc
  oTFH:cNumero  :=cNumero
  oTFH:cFileLog :="TEMP\"+IF(Empty(cNumero),cCmd,cNumero)+".LOG"
  oTFH:nStatus  :=0
  oTFH:nError   :=0
  oTFH:nErrorChk:=0 
  oTFH:cCmd     :=cCmd
  oTFH:lError   :=.F.
  oTFH:cErrorIni:=""
  
  FERASE(oTFH:cFileLog)

  IF !FILE(oTFH:cFileDll)
    MsgMemo("No se Encuentra Archivo "+oTFH:cFileDll)
    RETURN NIL
  ENDIF

  oTFH:oFile   :=TFile():New(oTFH:cFileLog)

  oDp:nTFHDll := If(oDp:nTFHDll == nil,LoadLibrary(oTFH:cFileDll),oDp:nTFHDll ) 
  cPuerto         := If(cPuerto == nil,"COM6",cPuerto )


  IF ValType(oDp:nTFHDll)!="N" .And. oDp:nTFHDll!=0

     cError:=TFH_ERROR(999,.T.)

  ELSE

     nError:=DpOpenFpctrl(cPuerto)

     IF nError=0
        cError:=TFH_ERROR(nError,!oDp:lImpFisModVal,.T.)
     ENDIF

     IF nError != 1 .And. nError != 0
        cError:=TFH_ERROR(nError,!oDp:lImpFisModVal,.T.)
     ENDIF

     oTFH:cErrorIni:=cError

     IF !EMPTY(cError)
        oTFH:lError:=.T.
        DpCloseFpctrl ()
     ENDIF

     oTFH:nErrorChk:=DpCheckFprinter() 

  ENDIF

  oTFH:cError  :=cError

RETURN oTFH


/*
// Mensajes de Error
*/
FUNCTION TFH_ERROR(nRet,lShow,lVerifPto)
  LOCAL cError:=""

  lShow    := If(lShow     == nil,.T.,lShow ) 
  lVerifPto:= If(lVerifPto == nil,.F.,lVerifPto )

  IF nRet=1 .Or. (nRet = 0 .And. !lVerifPto)
     RETURN ""
  ENDIF

  cError:="desconocido Nº: "+STR(nRet)

  IF nRet= 0
     cError:="Puerto no Abierto"
  ENDIF

  IF nRet= -1
     cError:="Parámetro inválido"
  ENDIF

  IF nRet= -2
     cError:="Parámetro Inválido"
  ENDIF

  IF nRet=-3
     cError:="Aliquota no programada"
  ENDIF

  IF nRet=-4
     cError:="Archivo tfhkaif.INI no encontrado, copielo en "+oDp:cBin
  ENDIF

  IF nRet=-5
     cError:="Error en Apertura, Posiblemente ya está Abierto el Puerto"
  ENDIF

  IF nRet=-6
     cError:="Ninguna Impresora fué Encontrada, Verifique si está Encendida o Conectada al Cable Serial o USB"
  ENDIF

  IF nRet = -8
    cError:="Error al Crear o Grabar en el Archivo status.txt o retorno.txt "
  ENDIF

  IF nRet = 128

    IF "199"=oTFH:cCmd
      cError:="No puede cerrar el ticket, posiblemente ticket anterior incompleto, resetee la impresora."
    ELSE
      cError:="Defina la trama del campo Precio y/o cantidad"
    ENDIF

  ENDIF

  IF nRet = 137
    cError:="Impresora No Conectada o Apagada"
  ENDIF

  IF nRet = 999
    cError:="No se puedo cargar archivo tfhkaif.dll"
  ENDIF

  // ejecuta URL con las instrucciones
  EJECUTAR("WEBRUN","https://adaptaproerp.com/impresora-fiscal-thefactory/",.F.)

  cError:="Error:"+LSTR(nRet)+", "+cError

  oTFH:oFile:AppStr(cError)

  oTFH:cError:=cError
 
  IF lShow .AND. !oDp:lImpFisRegAud
    MsgMemo(cError,"Error Impresora TFH")
  ENDIF

RETURN cError

/*
// Cierra el Objeto TFH
*/
FUNCTION TFH_END()

  DpCloseFpctrl()
  oTFH:oFile:AppStr("TFH_END()"+CRLF)

  IF !oTFH:oFile=NIL
    oTFH:oFile:Close()
  ENDIF

  IF oDp:nTFHDll<>NIL
     FreeLibrary(oDp:nTFHDll)
     oDp:nTFHDll:=NIL
  ENDIF

RETURN .T.

/*
// Apertura del Puerto para iniciar comunicación
*/
FUNCTION DpOpenFpctrl(lpPortName ) 
  LOCAL cFarProc:= GetProcAddress(oDp:nTFHDLL,"OpenFpctrl",.T.,7,9 ) 
  LOCAL uResult := CallDLL(cFarProc,lpPortName ) 

  IF oDp:lImpFisModVal
    oTFH:oFile:AppStr("Modo Validación ACTIVADO "+CRLF)
  ENDIF

  IF ValType(oTFH:oFile)="O"
    oTFH:oFile:AppStr("DpOpenFpctrl: Pararam->"+CTOO(lpPortName,"C")+",Resp->"+CTOO(uResult,"C")+CRLF)
  ENDIF

RETURN uResult

/*
// Revisa el estatus de la Impresora
*/
FUNCTION DpCheckFprinter() 
  LOCAL cFarProc:= GetProcAddress(oDp:nTFHDLL,"CheckFprinter",.T.,7 ) 
  LOCAL uResult := CallDLL(cFarProc ) 

  oTFH:oFile:AppStr("DpCheckFprinter ,Resp->"+CTOO(uResult,"C")+CRLF)

RETURN uResult

/*
// leer valores de la impresora, comandos S1,S2
*/
FUNCTION DpGetData(cFunction,cCmd) 
  LOCAL cFarProc:=NIL
  LOCAL uResult :=NIL
  LOCAL lStatus :=1
  LOCAL lError  :=1
  LOCAL cData   :=SPACE(254)

  DEFAULT cFunction:="UploadStatusDin",;
          cCmd     :="S1"

  IF !oDp:lImpFisModVal
    cFarProc:= GetProcAddress(oDp:nTFHDLL,cFunction,.T.,7,9,9,9,9) 
    uResult := CallDLL(cFarProc,lStatus,lError,cCmd,@cData) 
  ENDIF

  IF ValType(oTFH:oFile)="O"
    oTFH:oFile:AppStr(cFunction+",Resp->"+CTOO(uResult,"C")+"cData"+CTOO(cData,"C")+CRLF)
  ENDIF

RETURN cData

/*
// leer valores de la impresora, comandos S1,S2
*/
FUNCTION DpGenFileTxt(cFunction,cCmd,cFileTxt) 
  LOCAL cFarProc:=NIL
  LOCAL uResult :=NIL
  LOCAL nStatus :=NIL
  LOCAL nError  :=NIL

  DEFAULT cFunction:="UploadStatusCmd",;
          cCmd     :="S1"

  cFarProc:= GetProcAddress(oDp:nTFHDLL,cFunction,.T.,7,10,9,9 ) 
  uResult := CallDLL(cFarProc,@nStatus,@nError,@cCmd) 

? uResult,"uResult",cCmd,"cCmd"

  oTFH:oFile:AppStr(cFunction+",Resp->"+CTOO(uResult,"C")+CRLF)

RETURN uResult




/*
// Cerrar la comunicación
*/
FUNCTION DpCloseFpctrl() 
  LOCAL cFarProc:= GetProcAddress(oDp:nTFHDLL,"CloseFpctrl",.T.,7 ) 
  LOCAL uResult := CallDLL(cFarProc ) 

  oTFH:oFile:AppStr("DpCloseFpctrl() ,Resp->"+CTOO(uResult,"C")+CRLF)

RETURN uResult

/*
// Lectura del estatus de la Impresora
*/
FUNCTION DpReadFpStatus() 
  LOCAL nStatus :=0,nError:=0
  LOCAL cFarProc:= GetProcAddress(oDp:nTFHDLL,"ReadFpStatus",.T.,7,10 ,10 ) 
  LOCAL uResult := CallDLL(cFarProc,@nStatus ,@nError )

  oTFH:oFile:AppStr("DpReadFpStatus:"+CTOO(nStatus,"C")+", Resp->"+CTOO(uResult,"C")+CRLF)

  oTFH:nStatus:=nStatus
  oTFH:nError :=nError
  oTFH:lError :=(nError>0)

RETURN uResult

/*
// Envio de Comandos para la Impresión 
*/
FUNCTION DpSendCmd(nStatus,nError,cCmd)
  LOCAL cFarProc
  LOCAL uResult 

  // 21/11/2023, modo validacion requiere la traza

  IF !oDp:lImpFisModVal
     cFarProc := GetProcAddress(oDp:nTFHDLL,"SendCmd",.T.,7,10,10,9 ) 
     uResult  := CallDLL(cFarProc,@nStatus,@nError,@cCmd ) 
  ENDIF

  oTFH:nStatus:=nStatus
  oTFH:nError :=nError
  oTFH:cCmd   :=cCmd

  oTFH:oFile:AppStr("DpSendCmd: Param: nStatus->"+CTOO(nStatus,"C")+",Error->"+CTOO(nError,"C")+",cCmd->"+CTOO(cCmd,"C")+", Resp->"+CTOO(uResult,"C")+CRLF)

RETURN uResult

/*
// Envio de comandos introducidos en un Archivo TEXTO
*/
FUNCTION DpSendFileCmd(nStatus,nError,cFile )
   LOCAL cFarProc:= GetProcAddress(oDp:nTFHDLL,"SendFileCmd",.T.,7,10,10,9 ) 
   LOCAL uResult := CallDLL(cFarProc,@nStatus,@nError,@cfile ) 

   oTFH:nStatus:=nStatus
   oTFH:nError :=nError
   oTFH:cFile  :=cFile

   oTFH:oFile:AppStr("DpSendFileCmd:"+CTOO(status,"C")+","+CTOO(error,"C")+","+CTOO(file,"C")+CRLF)

RETURN uResult

/*
// Generar Reporte X
*/
FUNCTION REPORTEX()
  LOCAL cIni:="I0X", nStatus, nError, cError:=""

  DpSendCmd(@nStatus,@nError,cIni)

  IF oTFH:nError<>0
    cError:=TFH_ERROR(oTFH:nError,!oDp:lImpFisModVal,.T.)
  ENDIF

RETURN Empty(cError)

/*
// Generar Reporte Z
*/
FUNCTION REPORTEZ()
    LOCAL cIni:="I0Z", nStatus:=NIL, nError:=NIL, cError:=""

    DpSendCmd(@nStatus,@nError,cIni)

    IF oTFH:nError<>0
      cError:=TFH_ERROR(oTFH:nError,!oDp:lImpFisModVal,.T.)
    ENDIF

RETURN Empty(cError)

/*
// Resetea Ticket no concluido
*/
FUNCTION TFHRESERT()
    LOCAL cIni:="7", nStatus, nError, cError:=""

    DpSendCmd(@nStatus,@nError,cIni)

    IF oTFH:nError<>0
      cError:=TFH_ERROR(oTFH:nError,!oDp:lImpFisModVal,.T.)
    ENDIF

RETURN Empty(cError)

// EOF

