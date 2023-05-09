// Programa   : DLL_TFH
// Fecha/Hora : 22/08/2022 11:19:17
// Propósito  : Imprimir con impresora THEFACTORY
// Creado Por : Juan Navas/Kelvis Escalante
// Llamado por: DPDOCCLI_PRINT      
// Aplicación : Facturación/Punto de Venta
// Tabla      : DPDOCCLI/DPMOVINV

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
  IF Empty(cCodSuc) .AND. ("Z"$cCmd .OR. "X"$cCmd .OR. "7"$cCmd)

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

  ELSE
  
     oDp:cImpFiscalSqlPagos:=""

    // Obtiene la Data del Ticket
    cData   :=EJECUTAR("TFHKA_DATA",cCodSuc,cTipDoc,cNumero,cOption)
    cFilePag:="temp\"+cTipDoc+cNumero+".pag"
    
    IF !oDp:lImpFisModVal 
       aData   :=STRTRAN(cData,CRLF,CHR(10))
       aData   :=_VECTOR(aData,CHR(10))
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

  IF nRet = 137
    cError:="Impresora No Conectada o Apagada"
  ENDIF

  IF nRet = 999
    cError:="No se puedo cargar archivo tfhkaif.dll"
  ENDIF

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
  LOCAL cFarProc:= GetProcAddress(oDp:nTFHDLL,If(Empty("OpenFpctrl" ) == .t.,"DpOpenFpctrl","OpenFpctrl" ),.T.,7,9 ) 
  LOCAL uResult := CallDLL(cFarProc,lpPortName ) 

  oTFH:oFile:AppStr("DpOpenFpctrl: Pararam->"+CTOO(lpPortName,"C")+",Resp->"+CTOO(uResult,"C")+CRLF)

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
// Cerrar la comunicación
*/
FUNCTION DpCloseFpctrl() 
  LOCAL cFarProc:= GetProcAddress(oDp:nTFHDLL,If(Empty("CloseFpctrl" ) == .t.,"DpCloseFpctrl","CloseFpctrl" ),.T.,7 ) 
  LOCAL uResult := CallDLL(cFarProc ) 

  oTFH:oFile:AppStr("DpCloseFpctrl() ,Resp->"+CTOO(uResult,"C")+CRLF)

RETURN uResult

/*
// Lectura del estatus de la Impresora
*/
FUNCTION DpReadFpStatus() 
  LOCAL nStatus :=0,nError:=0
  LOCAL cFarProc:= GetProcAddress(oDp:nTFHDLL,If(Empty("ReadFpStatus" ) == .t.,"DpReadFpStatus","ReadFpStatus" ),.T.,7,10 ,10 ) 
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
  LOCAL cFarProc := GetProcAddress(oDp:nTFHDLL,If(Empty("SendCmd" ) == .t.,"DpSendCmd","SendCmd" ),.T.,7,10 ,10,9 ) 
  LOCAL uResult  := CallDLL(cFarProc,@nStatus,@nError,@cCmd ) 

  oTFH:nStatus:=nStatus
  oTFH:nError :=nError
  oTFH:cCmd   :=cCmd

  oTFH:oFile:AppStr("DpSendCmd: Param: nStatus->"+CTOO(nStatus,"C")+",Error->"+CTOO(nError,"C")+",cCmd->"+CTOO(cCmd,"C")+", Resp->"+CTOO(uResult,"C")+CRLF)

RETURN uResult

/*
// Envio de comandos introducidos en un Archivo TEXTO
*/
FUNCTION DpSendFileCmd(nStatus,nError,file )
   LOCAL cFarProc:= GetProcAddress(oDp:nTFHDLL,If(Empty("SendFileCmd" ) == .t.,"DpSendFileCmd","SendFileCmd" ),.T.,7,10 ,10,9 ) 
   LOCAL uResult := CallDLL(cFarProc,@nStatus,@nError,@file ) 

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
    LOCAL cIni:="I0Z", nStatus, nError, cError:=""

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

