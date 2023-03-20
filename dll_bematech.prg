// Programa   : DLL_BEMATECH
// Fecha/Hora : 19/06/2022 18:06:15
// Propósito  : Imprimir con BemaTech sin depender del modulos HRB
// Creado Por : Juan Navas
// Llamado por: DPPOS/DPFACTURAV
// Aplicación :
// Tabla      :

#INCLUDE "DPXBASE.CH"

PROCE MAIN(cCodSuc,cTipDoc,cNumero,lMsgErr,lShow,lBrowse)
  LOCAL oTable,cFileOrg
  LOCAL cTicket :=""
  LOCAL cFileLog:=""
  LOCAL oSerFis :=NIL
  LOCAL lDemo   :=(cTipDoc=NIL)
  LOCAL uBuf,nClrText:=0

  DEFAULT cCodSuc:=oDp:cSucursal,;
          cTipDoc:="FAV",;
          cNumero:=SQLGETMAX("DPDOCCLI","DOC_NUMERO","DOC_CODSUC"+GetWhere("=",cCodSuc)+" AND DOC_TIPDOC"+GetWhere("=",cTipDoc)+" AND DOC_TIPTRA"+GetWhere("=","D"))

  DEFAULT lMsgErr:=.T.,;
          lShow  :=.T.,;
          lBrowse:=.T. 


// ? cCodSuc,cTipDoc,cNumero,lMsgErr,lShow,lBrowse,"cCodSuc,cTipDoc,cNumero,lMsgErr,lShow,lBrowse"

  IF lShow
     AEVAL(DIRECTORY("TEMP\*.ERR"),{|a,n| FERASE("TEMP\"+a[1])})
  ENDIF

  cTicket:=cNumero 
  
//  IF !TYPE("oBema")="O"
//    TDpClass():New(NIL,"oBema")
//  ENDIF

  oDp:cFileToScr:="traza\bematech.txt"

  DPEDIT():New("BemaTech","","oBema",.F.)

  oBema:hDll    :=NIL
  oBema:cNamePrn:="BEMATECH"
  oBema:cFileDll:="BemaFI32.dll"
  oBema:oMemo   :=nil
  oBema:cMemo   :="Imprimiendo "+oDp:cImpFisCom+CRLF

  oBema:CreateWindow(NIL,oDp:aCoors[3]/2,oDp:aCoors[4]/2,130,400+200)

  oBema:oDlg:SetColor(NIL,oDp:nGris2)
 
  @ 0.1,.1 GET oBema:oMemo VAR oBema:cMemo MULTI SIZE 290,40 COLOR NIL,oDp:nGris2 READONLY OF oBema:oDlg
  
  oBema:Activate()
  SysRefresh(.T.)
  oBema:FrmCentrar()

  oBema:hDll    :=NIL
  oBema:cNamePrn:="BEMATECH"
  oBema:cFileDll:="BemaFI32.dll"

  oBema:cEstatus:=""
  oBema:oFile   :=NIL
  oBema:lMsgErr :=lMsgErr
  oBema:lErr    :=.F. // no genera ninguna Incidencia
  oBema:cFileLog:="TEMP\"+cTipDoc+ALLTRIM(cTicket)+".LOG"
  oBema:lShow   :=lShow
  oBema:cError  :=""
  oBema:lDemo   :=.T.
  oBema:SETSCRIPT("DLL_BEMATECH")


  cFileLog:=oBema:cFileLog

  ferase(cFileLog)

  IF FILE(cFileLog)
    oBema:MsgErr("Archivo "+cFileLog+" está abierto",oBema:oMemo)
     // oBema:oSay:Append("Archivo "+cFileLog+" está abierto")
  ENDIF

  oBema:oFile:=TFile():New(oBema:cFileLog)

  IF !FILE(oBema:cFileDll)
    oBema:lErr    :=.T.
    oBema:oFile:AppStr("No se Encuenta Archivo "+oBema:cFileDll)
    // oBema:oSay:Append("No se Encuenta Archivo "+oBema:cFileDll)
    oBema:MsgErr()
    oBema:End()
    oBema:oFile:Close()
    RETURN .F.
  ENDIF

  oBema:hDll    := LoadLibrary(oBema:cFileDll)
  oDp:nBemaDLL  :=oBema:hDll

  IF lDemo
    oBema:MSGERR()
  ENDIF

  // Verifica el Estatus de la Impresora
  uBuf  := 0
  oBema:nRet  := BmFlagFiscal(@uBuf) // Verifica si hay Cupones

  oBema:cError:=oBema:Bema_Error(oBema:nRet,.T.,oBema:oMemo)

  oDp:cFileToScr:=nil

  // Asignar Moneda
  oBema:nRet:=oBema:BmSimboloMoneda(oDp:cMoneda)

  oBema:cError:=oBema:Bema_Error(oBema:nRet,.T.,oBema:oMemo)
  oBema:oFile:Close()
  oBema:Error()

RETURN .T.

/*
// En este Lugar Introduce la llamada desde el programa DpXbase para bematech
*/

FUNCTION MSGLOG(cMsg,lMsgErr,oMemo)

  IF oBema:lMsgErr .AND. Empty(cMsg)
     cMsg:=MemoRead(oBema:cFileLog)
  ENDIF

  IF !Empty(cMsg)

     IF ValType(oMemo)="O"
        oMemo:Append(cMsg+CRLF)
     ELSE
       MsgMemo(cMsg)
     ENDIF

  ENDIF

RETURN .T.

FUNCTION MSGERR(cMsg,oMemo)
  LOCAL cMsgErr:=""

  DEFAULT cMsg:=""

  IF oBema:lShow 
    cMsgErr:=EJECUTAR("MSGTEMPERR")
    cMsgErr:=cMsgErr+CRLF+cMsg
  ENDIF

  IF !Empty(cMsg)

     IF ValType(oMemo)="O"
        oMemo:Append(cMsg+CRLF)
     ELSE
       MsgMemo(cMsg)
     ENDIF

  ENDIF

RETURN .T.


FUNCTION BEMA_INI()
  LOCAL nRet,cError:="",I
  LOCAL cWinDir :="" // GetWinDir()+"\System32\"
  LOCAL cFileDll:="bemafi32.dll"
  LOCAL aDlls:={}

  If( oDp:lBema_Demo == nil, oDp:lBema_Demo := .T., ) ; If( oDp:aBema_Tasas == nil, oDp:aBema_Tasas := {}, );

/*
  IF !File(cFileDll)

     AADD(aDlls,"bemafi32.dll")
     AADD(aDlls,"bemafi32.ini")

     FOR I := 1 TO len(aDlls)

       IF !File(cWinDir+aDlls[I])
         __COPYFILE("BEMATECH\"+aDlls[I],cWinDir+aDlls[I])
       ENDIF

     NEXT

  ENDIF

  If( oDp:nBemaDll == nil, oDp:nBemaDll := LoadLibrary("bemafi32.dll"), ) ;
*/
  nRet:=BmPrintLig()

  cError:=BEMA_ERROR(nRet,.F.)

RETURN cError

FUNCTION BEMA_ERROR(nRet,lShow)
   LOCAL cError:=""

   If( lShow == nil, lShow := .T., ) ;

   IF nRet=1 .OR. nRet=0
      RETURN ""
   ENDIF

  DO CASE

    CASE nRet= -1

      cError:="Parámetro inválido"

    CASE nRet= -2

      cError:="Parámetro Inválido"

    CASE nRet=-3

      cError:="Aliquota no programada"

    CASE nRet=-4

      cError:="Archivo BemaFI32.INI no encontrado, copielo en c:\windows\system32"

    CASE nRet=-5

      cError:="Error en Apertura, Posiblemente ya está Abierto el Puerto"

    CASE nRet=-6

      cError:="Ninguna Impresora fué Encontrada, Verifique si está Encendida o Conectada al Cable Serial"

    CASE nRet = -8

      cError:="Error al Crear o Grabar en el Archivo status.txt o retorno.txt "

  ENDCASE

  cError:="Error:"+LSTR(nRet)+", "+cError

  IF lShow
    MensajeErr(cError,"Error Impresora Bematech")
  ENDIF

RETURN cError


FUNCTION BEMA_END()

  IF oDp:nBemaDll<>NIL
     FreeLibrary(oDp:nBemaDll)
     oDp:nBemaDll:=NIL
  ENDIF

RETURN .T.

PROCE XBEMA()
  LOCAL nRet  ,cRif:=PADR("Nombre del Cliente",41)+PADR("RIF",18)
  LOCAL nNumImp:=0,I,uBuf,cTasas:=SPACE(79)

  uBuf := 0
  nRet := BmFlagFiscal(@uBuf)

  BemaLeerAlicuota(@cTasas)
  nRet := BmAbreCup(cRif)

RETURN NIL

FUNCTION CAMBIARTASAS()

  WQout( { "Es necesario Emitir Reporte Z" } )

  IF MsgYesNo("Cambiar Tasas ")
     BematechZ()
     BemaProgAlicuota( "1600")
  ENDIF

RETURN .T.

FUNCTION BemaTechZ()
  LOCAL cFecha:=DTOC(DATE())
  LOCAL cHora :=TIME()

  BemaReporteZeta(cFecha,cHora)

RETURN .T.

FUNCTION BmPrintLig( )
  LOCAL cFarProc := NIL
  LOCAL uResult  := 0 // Modo Validación

  IF !oDp:lImpFisModVal
     cFarProc:= GetProcAdd( oDp:nBemaDLL, If( Empty( "Bematech_FI_VerificaImpressoraLigada" ) == .T., "BmPrintLig", "Bematech_FI_VerificaImpressoraLigada" ), .T., 7 )
     uResult := FWCallDLL( cFarProc )
  ENDIF

  oBema:oFile:AppStr("BmPrintLig, nResult= "+CTOO(uResult,"C")+CRLF)

Return uResult

FUNCTION BmNumeroCx( NumeroCaixa )
  LOCAL cFarProc:= NIL
  LOCAL uResult := 0

  IF !oDp:lImpFisModVal
     cFarProc:= GetProcAdd( oDp:nBemaDLL, If( Empty( "Bematech_FI_VerificaImpressoraLigada" ) == .T., "BmPrintLig", "Bematech_FI_VerificaImpressoraLigada" ), .T., 7 )
     uResult := FWCallDLL( cFarProc )
  ENDIF

  oBema:oFile:AppStr("NumeroCaixa->"+CTOO(NumeroCaixa,"C")+", nResult="+CTOO(uResult,"C")+CRLF)

RETURN uResult

FUNCTION BmAbreCup( cData )
  LOCAL cFarProc:= NIL
  LOCAL uResult := 0

  IF !oDp:lImpFisModVal
    LOCAL cFarProc:= GetProcAdd(oDp:nBemaDLL, If( Empty( "Bematech_FI_AbreComprobanteDeVenta" ) == .T., "BmAbreCup", "Bematech_FI_AbreComprobanteDeVenta" ), .T., 7,9 )
    LOCAL uResult := FWCallDLL( cFarProc,cData )
  ENDIF

  oBema:oFile:AppStr("cData->"+CTOO(cData,"C")+", nResult="+CTOO(uResult,"C")+CRLF)

RETURN uResult

FUNCTION BmFlagFiscal( FlagFiscal )
  LOCAL cFarProc := NIL
  LOCAL uResult  := 0 // Modo Validación

  IF !oDp:lImpFisModVal
    cFarProc := GetProcAdd( oDp:nBemaDLL, If( Empty( "Bematech_FI_FlagsFiscales" ) == .T., "BmFlagFiscal", "Bematech_FI_FlagsFiscales" ), .T., 7,10 )
    uResult  := FWCallDLL( cFarProc,@FlagFiscal )
  ENDIF

  oBema:FlagFiscal:=FlagFiscal

  oBema:oFile:AppStr("BmFlagFiscal,1->"+CTOO(FlagFiscal,"C")+" nResult="+CTOO(uResult,"C")+CRLF)

RETURN uResult

FUNCTION BmFechaCup( FormaPgto,Acrescimo,TipoAcresc,ValorAcresc,ValorPago,Mensagem )
  LOCAL cFarProc := NIL
  LOCAL uResult  := 0 // Modo Validación
  LOCAL cLine

  IF !oDp:lImpFisModVal
     cFarProc:= GetProcAdd( oDp:nBemaDLL, If( Empty( "Bematech_FI_CierraCupon" ) == .T., "BmFechaCup", "Bematech_FI_CierraCupon" ), .T., 7,8,8,8,8,8,8 )
     uResult := FWCallDLL( cFarProc,FormaPgto,Acrescimo,TipoAcresc,ValorAcresc,ValorPago,Mensagem )
  ENDIF

  cLine:="FormaPgto->"  +CTOO(FormaPgto  ,"C")+","+;
         "Acrescimo->"  +CTOO(Acrescimo  ,"C")+","+;
         "TipoAcresc->" +CTOO(TipoAcresc ,"C")+","+;
         "ValorAcresc->"+CTOO(ValorAcresc,"C")+","+;
         "ValorPago->"  +CTOO(ValorPago  ,"C")+","+;
         "Mensagem->"   +CTOO(Mensagem   ,"C")+","+;
         "nResult="     +CTOO(uResult,"C")

  oBema:oFile:AppStr(cLine+CRLF)

RETURN uResult

FUNCTION BemaLeerAlicuota( cTasas )
  LOCAL cFarProc := NIL
  LOCAL uResult  := 0 // Modo Validación
  LOCAL cLine

  IF !oDp:lImpFisModVal
    cFarProc:= GetProcAdd( oDp:nBemaDLL, If( Empty( "Bematech_FI_RetornoAlicuotas" ) == .T., "BemaLeerAlicuota", "Bematech_FI_RetornoAlicuotas" ), .T., 7,9 )
    uResult := FWCallDLL( cFarProc,@cTasas )
  ENDIF

  oBema:cLeeTasas:=cTasas
  oBema:oFile:AppStr("cTasas->"+CTOO(cTasas,"C")+CRLF+","+;
                     "nResult="+CTOO(uResult,"C")

RETURN uResult

FUNCTION BemaProgAlicuota( cTasas )
  LOCAL cFarProc := NIL
  LOCAL uResult  := 0 // Modo Validación
  LOCAL cLine

  IF !oDp:lImpFisModVal
     cFarProc:= GetProcAdd( oDp:nBemaDLL, If( Empty( "Bematech_FI_ProgramaAlicuota" ) == .T., "BemaProgAlicuota", "Bematech_FI_ProgramaAlicuota" ), .T., 7,9 )
     uResult := FWCallDLL( cFarProc,cTasas )
  ENDIF

  oBema:oFile:AppStr("cTasas->"+CTOO(cTasas,"C")+CRLF+","+;
                     "nResult="+CTOO(uResult,"C")


RETURN uResult

FUNCTION BemaReporteZeta( Dt,Hs ) 
  LOCAL cFarProc := NIL
  LOCAL uResult  := 0 // Modo Validación
 

  IF !oDp:lImpFisModVal
     cFarProc:= GetProcAdd( oDp:nBemaDLL, If( Empty( "Bematech_FI_ReduccionZ" ) == .T., "BemaReporteZeta", "Bematech_FI_ReduccionZ" ), .T., 7,9,9 )
     uResult := FWCallDLL( cFarProc,Dt,Hs )
  ENDIF

  oBema:oFile:AppStr("BemaReporteZeta( Dt,Hs )"+CRLF+;
                     "DT->"+CTOO(DT,"C")+","+;
                     "HS->"+CTOO(HS,"C")+","+;
                     "nResult="     +CTOO(uResult,"C")+CRLF)

RETURN uResult

FUNCTION BmSubTotal( SubTotal )
  LOCAL cFarProc := NIL
  LOCAL uResult  := 0 // Modo Validación

  IF !oDp:lImpFisModVal
    cFarProc:= GetProcAdd( oDp:nBemaDLL, If( Empty( "Bematech_FI_SubTotal" ) == .T., "BmSubTotal", "Bematech_FI_SubTotal" ), .T., 7,9 ) ;
    uResult := FWCallDLL( cFarProc,SubTotal )
  ENDIF

  oBema:oFile:AppStr("BmSubTotal( SubTotal )"+CRLF+;
                     "SubTotal->"+CTOO(SubTotal,"C")+","+;
                     "nResult="  +CTOO(uResult,"C")+CRLF)

RETURN uResult

FUNCTION BmVerArred(Arredonda)
  LOCAL cFarProc := NIL
  LOCAL uResult  := 0 // Modo Validación

  IF !oDp:lImpFisModVal
     cFarProc:= GetProcAdd( oDp:nBemaDLL, If( Empty( "Bematech_FI_VerificaTruncamiento" ) == .T., "BmVerArred", "Bematech_FI_VerificaTruncamiento" ), .T., 7,9 )
  	uResult := FWCallDLL( cFarProc,Arredonda )
  ENDIF

  oBema:oFile:AppStr("BmVerArred(Arredonda)"+CRLF+;
                     "Arredonda->"+CTOO(Arredonda,"C")+","+;
                     "nResult="   +CTOO(uResult,"C")+CRLF)

RETURN uResult

FUNCTION BmLigArred()
  LOCAL cFarProc := NIL
  LOCAL uResult  := 0 // Modo Validación

  IF !oDp:lImpFisModVal
     cFarProc:= GetProcAdd( oDp:nBemaDLL, If( Empty( "Bematech_FI_ProgramaRedondeo" ) == .T., "BmLigArred", "Bematech_FI_ProgramaRedondeo" ), .T., 7 )
     uResult := FWCallDLL( cFarProc )
  ENDIF

  oBema:oFile:AppStr("BmLigArred()"+CRLF+;
                    "nResult="   +CTOO(uResult,"C")+CRLF)

RETURN uResult

FUNCTION BmDtMovto( DtMovto )
  LOCAL cFarProc := NIL
  LOCAL uResult  := 0 // Modo Validación

  IF !oDp:lImpFisModVal
     cFarProc:= GetProcAdd( oDp:nBemaDLL, If( Empty( "Bematech_FI_FechaMovimiento" ) == .T., "BmDtMovto", "Bematech_FI_FechaMovimiento" ), .T., 7,9 )
     uResult := FWCallDLL( cFarProc,DtMovto )
  ENDIF

  oBema:oFile:AppStr("BmDtMovto(DtMovto)"+CRLF+;
                     "DtMovto->"+CTOO(DtMovto,"C")+","+CRLF+;
                     "nResult="   +CTOO(uResult,"C")+CRLF)

RETURN uResult

FUNCTION BmFlagFisc( FlagFiscal )
  LOCAL cFarProc := NIL
  LOCAL uResult  := 0 // Modo Validación

  IF !oDp:lImpFisModVal
     cFarProc:= GetProcAdd( oDp:nBemaDLL, If( Empty( "Bematech_FI_FlagsFiscales" ) == .T., "BmFlagFisc", "Bematech_FI_FlagsFiscales" ), .T., 7,10 )
     uResult := FWCallDLL( cFarProc,@FlagFiscal )
  ENDIF

  oBema:oFile:AppStr("BmFlagFisc( FlagFiscal )"+CRLF+;
                     "FlagFiscal->"+CTOO(FlagFiscal,"C")+","+CRLF+;
                     "nResult="   +CTOO(uResult,"C")+CRLF)

RETURN uResult

FUNCTION BmLeituraX( )
  LOCAL cFarProc := NIL
  LOCAL uResult  := 0 // Modo Validación

  IF !oDp:lImpFisModVal
  	cFarProc:= GetProcAdd( oDp:nBemaDLL, If( Empty( "Bematech_FI_LecturaX" ) == .T., "BmLeituraX", "Bematech_FI_LecturaX" ), .T., 7 ) ;
  	uResult := FWCallDLL( cFarProc )
  ENDIF

  oBema:oFile:AppStr("BmLeituraX()"+CRLF+;
                     "nResult="   +CTOO(uResult,"C")+CRLF)

RETURN uResult

FUNCTION BmReducaoZ( Dt,Hs )
  LOCAL cFarProc := NIL
  LOCAL uResult  := 0 // Modo Validación

  IF !oDp:lImpFisModVal
     cFarProc:= GetProcAdd( oDp:nBemaDLL, If( Empty( "Bematech_FI_ReduccionZ" ) == .T., "BmReducaoZ", "Bematech_FI_ReduccionZ" ), .T., 7,9,9 )
     uResult := FWCallDLL( cFarProc,Dt,Hs )
  ENDIF

  oBema:oFile:AppStr("BmFlagFisc( Hs )"+CRLF+;
                    "Dt->"+CTOO(Dt,"C")+","+CRLF+;
                    "Hs->"+CTOO(Hs,"C")+","+CRLF+;
                    "nResult="   +CTOO(uResult,"C")+CRLF)


RETURN uResult

FUNCTION BmDtHora( Dt,Hs )
  LOCAL cFarProc := NIL
  LOCAL uResult  := 0 // Modo Validación

  IF !oDp:lImpFisModVal
     cFarProc:= GetProcAdd( oDp:nBemaDLL, If( Empty( "Bematech_FI_FechaHoraImpresora" ) == .T., "BmDtHora", "Bematech_FI_FechaHoraImpresora" ), .T., 7,9,9 )
     uResult := FWCallDLL( cFarProc,Dt,Hs )
  ENDIF

  oBema:oFile:AppStr("BmDtHora( Dt,Hs )"+CRLF+;
                     "Dt->"+CTOO(Dt,"C")+","+CRLF+;
                     "Hs->"+CTOO(Hs,"C")+","+CRLF+;
                     "nResult="   +CTOO(uResult,"C")+CRLF)

RETURN uResult

FUNCTION BmAbreDia( Vl,Fr )
  LOCAL cFarProc := NIL
  LOCAL uResult  := 0 // Modo Validación

  IF !oDp:lImpFisModVal
     cFarProc:= GetProcAdd( oDp:nBemaDLL, If( Empty( "Bematech_FI_AberturaDoDia" ) == .T., "BmAbreDia", "Bematech_FI_AberturaDoDia" ), .T., 7,9,9 )
     uResult := FWCallDLL( cFarProc,Vl,Fr )
  ENDIF

  oBema:oFile:AppStr("BmAbreDia( Vl,Fr )"+CRLF+;
                     "Vl->"+CTOO(Vl,"C")+","+CRLF+;
                     "Fr->"+CTOO(Fr,"C")+","+CRLF+;
                     "nResult="   +CTOO(uResult,"C")+CRLF)

RETURN uResult

FUNCTION BmVerPapel( Linhas )
  LOCAL cFarProc := NIL
  LOCAL uResult  := 0 // Modo Validación

  IF !oDp:lImpFisModVal
     cFarProc:= GetProcAdd( oDp:nBemaDLL, If( Empty( "Bematech_FI_MonitoramentoPapel" ) == .T., "BmVerPapel", "Bematech_FI_MonitoramentoPapel" ), .T., 7,10 )
     uResult := FWCallDLL( cFarProc,@Linhas )
  ENDIF

  oBema:oFile:AppStr("BmVerPapel( Linhas )"+CRLF+;
                     "Linhas->"+CTOO(Linhas,"C")+","+CRLF+;
                     "nResult="   +CTOO(uResult,"C")+CRLF)

RETURN uResult

FUNCTION BmCanCupom()
  LOCAL cFarProc := NIL
  LOCAL uResult  := 0 // Modo Validación

  IF !oDp:lImpFisModVal
     cFarProc:= GetProcAdd( oDp:nBemaDLL, If( Empty( "Bematech_FI_CierraCupon" ) == .T., "BmCanCupom", "Bematech_FI_CierraCupon" ), .T., 7 )
     uResult := FWCallDLL( cFarProc )
  ENDIF

  oBema:oFile:AppStr("BmCanCupom()"+CRLF+;
                     "nResult="   +CTOO(uResult,"C")+CRLF)

RETURN uResult

FUNCTION BmCancItem()
  LOCAL cFarProc := NIL
  LOCAL uResult  := 0 // Modo Validación

  IF !oDp:lImpFisModVal
    cFarProc:= GetProcAdd( oDp:nBemaDLL, If( Empty( "Bematech_FI_AnulaArticuloAnterior" ) == .T., "BmCancItem", "Bematech_FI_AnulaArticuloAnterior" ), .T., 7 )
    uResult := FWCallDLL( cFarProc )
  ENDIF

  oBema:oFile:AppStr("BmCancItem()"+CRLF+;
                     "nResult="   +CTOO(uResult,"C")+CRLF)

RETURN uResult

FUNCTION BmAbreGav()
  LOCAL cFarProc := NIL
  LOCAL uResult  := 0 // Modo Validación

  IF !oDp:lImpFisModVal
    cFarProc:= GetProcAdd( oDp:nBemaDLL, If( Empty( "Bematech_FI_AccionaGaveta" ) == .T., "BmAbreGav", "Bematech_FI_AccionaGaveta" ), .T., 7 )
    uResult := FWCallDLL( cFarProc )
  ENDIF

  oBema:oFile:AppStr("BmAbreGav()"+CRLF+;
                     "nResult="   +CTOO(uResult,"C")+CRLF)

RETURN uResult

FUNCTION BmNumCupom( cCupon )
  LOCAL cFarProc := NIL
  LOCAL uResult  := 0 // Modo Validación

  IF !oDp:lImpFisModVal
    cFarProc:= GetProcAdd( oDp:nBemaDLL, If( Empty( "Bematech_FI_NumeroCupon" ) == .T., "BmNumCupom", "Bematech_FI_NumeroCupon" ), .T., 7,9 )
    uResult := FWCallDLL( cFarProc,@cCupon )
  ENDIF

  oBema:oFile:AppStr("BmNumCupom( cCupon )"+CRLF+;
                     "Linhas->"+CTOO(cCupon,"C")+","+CRLF+;
                     "nResult="+CTOO(uResult,"C")+CRLF)

RETURN uResult

FUNCTION BmMemFiscD( In,Fi )
  LOCAL cFarProc := NIL
  LOCAL uResult  := 0 // Modo Validación

  IF !oDp:lImpFisModVal
     cFarProc:= GetProcAdd( oDp:nBemaDLL, If( Empty( "Bematech_FI_LecturaMemoriaFiscalFecha" ) == .T., "BmMemFiscD", "Bematech_FI_LecturaMemoriaFiscalFecha" ), .T., 7,9,9 )
     uResult := FWCallDLL( cFarProc,In,Fi )
  ENDIF

  oBema:oFile:AppStr("BmMemFiscD( In,Fi )"+CRLF+;
                     "In->"+CTOO(In,"C")+","+CRLF+;
                     "Fi->"+CTOO(Fi,"C")+","+CRLF+;
                     "nResult="+CTOO(uResult,"C")+CRLF)

RETURN uResult

FUNCTION BmMemFiscR( In,Fi )
  LOCAL cFarProc := NIL
  LOCAL uResult  := 0 // Modo Validación

  IF !oDp:lImpFisModVal
     cFarProc:= GetProcAdd( oDp:nBemaDLL, If( Empty( "Bematech_FI_LecturaMemoriaFiscalReduccion" ) == .T., "BmMemFiscR", "Bematech_FI_LecturaMemoriaFiscalReduccion" ), .T., 7,9,9 )
     uResult := FWCallDLL( cFarProc,In,Fi )
  ENDIF

  oBema:oFile:AppStr("BmMemFiscR( In,Fi )"+CRLF+;
                     "In->"+CTOO(In,"C")+","+CRLF+;
                     "Fi->"+CTOO(Fi,"C")+","+CRLF+;
                     "nResult="+CTOO(uResult,"C")+CRLF)
RETURN uResult

FUNCTION BmCpGerAbr( Texto )
  LOCAL cFarProc := NIL
  LOCAL uResult  := 0 // Modo Validación
 
  IF !oDp:lImpFisModVal
     cFarProc:= GetProcAdd( oDp:nBemaDLL, If( Empty( "Bematech_FI_CierraInformeGerencial" ) == .T., "BmCpGerAbr", "Bematech_FI_CierraInformeGerencial" ), .T., 7,8 )
     uResult := FWCallDLL( cFarProc,Texto )
  ENDIF

  oBema:oFile:AppStr("BmCpGerAbr( Texto )"+CRLF+;
                     "Texto->"+CTOO(Texto,"C")+","+CRLF+;
                     "nResult="+CTOO(uResult,"C")+CRLF)

RETURN uResult

FUNCTION BmCpGerFec( )
  LOCAL cFarProc := NIL
  LOCAL uResult  := 0 // Modo Validación
 
  IF !oDp:lImpFisModVal
    cFarProc:= GetProcAdd( oDp:nBemaDLL, If( Empty( "Bematech_FI_CierraInformeGerencial" ) == .T., "BmCpGerFec", "Bematech_FI_CierraInformeGerencial" ), .T., 7 )
    uResult := FWCallDLL( cFarProc )
  ENDIF

  oBema:oFile:AppStr("BmCpGerFec( )"+CRLF+;
                     "nResult="+CTOO(uResult,"C")+CRLF)

RETURN uResult

FUNCTION BmStGaveta( nStatus )
  LOCAL cFarProc := NIL
  LOCAL uResult  := 0 // Modo Validación
 
  IF !oDp:lImpFisModVal
    cFarProc:= GetProcAdd( oDp:nBemaDLL, If( Empty( "Bematech_FI_VerificaEstadoGaveta" ) == .T., "BmStGaveta", "Bematech_FI_VerificaEstadoGaveta" ), .T., 7,10 )
    uResult := FWCallDLL( cFarProc,@nStatus )
  ENDIF

  oBema:oFile:AppStr("BmStGaveta( nStatus )"      +CRLF+;
                     "nStatus->"+CTOO(nStatus,"C")+","+CRLF+;
                     "nResult=" +CTOO(uResult,"C")+CRLF)

RETURN uResult

FUNCTION BmCupAdAbr( FormaPgto,Valor,Cupom )
  LOCAL cFarProc := NIL
  LOCAL uResult  := 0 // Modo Validación
 
  IF !oDp:lImpFisModVal
     cFarProc:= GetProcAdd( oDp:nBemaDLL, If( Empty( "Bematech_FI_AbreComprobanteNoFiscalVinculado" ) == .T., "BmCupAdAbr", "Bematech_FI_AbreComprobanteNoFiscalVinculado" ), .T., 7,8,8,8 )
     uResult := FWCallDLL( cFarProc,FormaPgto,Valor,Cupom )
  ENDIF

  oBema:oFile:AppStr("BmCupAdAbr( FormaPgto,Valor,Cupom )"+CRLF+;
                     "FormaPgto->"+CTOO(FormaPgto,"C")+","+CRLF+;
                     "Valor->"    +CTOO(Valor    ,"C")+","+CRLF+;
                     "Cupom->"    +CTOO(Cupom    ,"C")+","+CRLF+;
                     "nResult="+CTOO(uResult,"C")+CRLF)

RETURN uResult

FUNCTION BmCupAdUsa( Texto )
  LOCAL cFarProc:= GetProcAdd( oDp:nBemaDLL, If( Empty( "Bematech_FI_ImprimeComprobanteNoFiscalVinculado" ) == .T., "BmCupAdUsa", "Bematech_FI_ImprimeComprobanteNoFiscalVinculado" ), .T., 7,8 )
  LOCAL uResult := FWCallDLL( cFarProc,Texto )
RETURN uResult

FUNCTION BmCupAdFec( )
  LOCAL cFarProc:= GetProcAdd( oDp:nBemaDLL, If( Empty( "Bematech_FI_CierraComprobanteNoFiscalVinculado" ) == .T., "BmCupAdFec", "Bematech_FI_CierraComprobanteNoFiscalVinculado" ), .T., 7 )
  LOCAL uResult := FWCallDLL( cFarProc )
RETURN uResult


FUNCTION BmVendItem( Codigo,Descricao,Aliquota,TpQte,Quantid,Decimal,ValUnit,TpDesc,ValDesc )
  LOCAL cFarProc:= GetProcAdd( oDp:nBemaDLL, If( Empty( "Bematech_FI_VendeArticulo" ) == .T., "BmVendItem", "Bematech_FI_VendeArticulo" ), .T., 7,8,8,8,8,8,7,8,8,8 )
  LOCAL uResult := FWCallDLL( cFarProc,Codigo,Descricao,Aliquota,TpQte,Quantid,Decimal,ValUnit,TpDesc,ValDesc )
RETURN uResult

FUNCTION BmFormasPag( FormaPgto,ValorPago )
  LOCAL cFarProc:= GetProcAdd( oDp:nBemaDLL, If( Empty( "Bematech_FI_EfectuaFormaPago" ) == .T., "BmFormasPag", "Bematech_FI_EfectuaFormaPago" ), .T., 7,8,8 )
  LOCAL uResult := FWCallDLL( cFarProc,FormaPgto,ValorPago )
RETURN uResult

FUNCTION BmIniFecCup( Acrescimo,TipoAcresc,ValorAcresc )
  LOCAL cFarProc:= GetProcAdd( oDp:nBemaDLL, If( Empty( "Bematech_FI_IniciaCierreCupon" ) == .T., "BmIniFecCup", "Bematech_FI_IniciaCierreCupon" ), .T., 7,8,8,8 )
  LOCAL uResult := FWCallDLL( cFarProc,Acrescimo,TipoAcresc,ValorAcresc )
RETURN uResult

FUNCTION BmTerFecCup( Mensagem )
  LOCAL cFarProc:= GetProcAdd( oDp:nBemaDLL, If( Empty( "Bematech_FI_FinalizarCierreCupon" ) == .T., "BmTerFecCup", "Bematech_FI_FinalizarCierreCupon" ), .T., 7,8 )
  LOCAL uResult := FWCallDLL( cFarProc,Mensagem )
RETURN uResult

FUNCTION BmTfStatus( Operacao )
   LOCAL cFarProc:= GetProcAdd( oDp:nBemaDLL, If( Empty( "Bematech_FITEF_Status" ) == .T., "BmTfStatus", "Bematech_FITEF_Status" ), .T., 7,9 )
   LOCAL uResult := FWCallDLL( cFarProc,Operacao )
RETURN uResult

FUNCTION BmSimboloMoneda( cMoneda )
   LOCAL cFarProc := GetProcAdd( oDp:nBemaDLL, If( Empty( "Bematech_FI_CambiaSimboloMoneda" ) == .T., "BmSimboloMoneda", "Bematech_FI_CambiaSimboloMoneda" ), .T., 7,9 )
   LOCAL uResult  := FWCallDLL( cFarProc,cMoneda )
RETURN uResult

FUNCTION BmAbreNotaDeCredito( cNombre,cSerie,cRif,cDias,cMes,cAno,cHora,cMin,cSeg,cCupon )
  LOCAL cFarProc:= GetProcAdd( oDp:nBemaDLL, If( Empty( "Bematech_FI_AbreNotaDeCredito" ) == .T., "BmAbreNotaDeCredito", "Bematech_FI_AbreNotaDeCredito" ), .T., 7,9,9,9,9,9,9,9,9,9,9 )
  LOCAL uResult := FWCallDLL( cFarProc,cNombre,cSerie,cRif,cDias,cMes,cAno,cHora,cMin,cSeg,cCupon )
RETURN uResult

FUNCTION BmLecturaX()
  LOCAL cFarProc:= GetProcAdd( oDp:nBemaDLL, If( Empty( "Bematech_FI_LecturaX" ) == .T., "BmLecturaX", "Bematech_FI_LecturaX" ), .T., 7 )
  LOCAL uResult := FWCallDLL( cFarProc )
RETURN uResult

FUNCTION BmIniFecCupIGTF( ValorD )

  LOCAL cFarProc:= GetProcAdd( oDp:nBemaDLL, "Bematech_FI_IniciaCierreCuponIGTF", .T., 7,8 )
  LOCAL uResult := FWCallDLL( ValorD )

RETURN uResult
// EOF
