// Programa   : DLL_BEMATECH_2
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
  LOCAL uBuf,nClrText:=0,lSave:=.F.,cMemo,cTipo:="",cSql:="",nNumero,oTable
  LOCAL cFecha,cHora,cAlicuota:="",aData:={},lOpen:=.F.
  LOCAL cTipDesc:="%",I,cTipCant:=""

  DEFAULT cCodSuc:=oDp:cSucursal,;
          cTipDoc:="FAV",;
          cNumero:=SQLGETMAX("DPDOCCLI","DOC_NUMERO","DOC_CODSUC"+GetWhere("=",cCodSuc)+" AND DOC_TIPDOC"+GetWhere("=",cTipDoc)+" AND DOC_TIPTRA"+GetWhere("=","D"))

  DEFAULT lMsgErr:=.T.,;
          lShow  :=.T.,;
          lBrowse:=.T.,;
          oDp:lImpFisModVal:=.T.,;
          oDp:lImpFisRegAud:=.T.,;
          oDp:cImpFisCom   :="BEMATECH"

// ? cCodSuc,cTipDoc,cNumero,lMsgErr,lShow,lBrowse,"cCodSuc,cTipDoc,cNumero,lMsgErr,lShow,lBrowse"

  IF lShow
     AEVAL(DIRECTORY("TEMP\*.ERR"),{|a,n| FERASE("TEMP\"+a[1])})
  ENDIF

  cTicket:=cNumero 

  cSql:=" SELECT INV_DESCRI,MOV_TOTAL,MOV_CANTID,MOV_PRECIO,5 AS CINCO,MOV_CODIGO,MOV_IVA,MOV_TIPIVA,INV_DESCRI,MOV_UNDMED,MOV_CXUND,MOV_CODVEN,MOV_DESCUE,MOV_CAPAP,MOV_LOTE,"+;
        " IF(DOC_CODIGO"+GetWhere("=","0000000000")+",DPCLIENTESCERO.CCG_RIF   ,DPCLIENTES.CLI_RIF   ) AS  CCG_RIF    ,"+;
        " IF(DOC_CODIGO"+GetWhere("=","0000000000")+",DPCLIENTESCERO.CCG_NOMBRE,DPCLIENTES.CLI_NOMBRE) AS  CCG_NOMBRE ,"+;
        " IF(DOC_CODIGO"+GetWhere("=","0000000000")+",DPCLIENTESCERO.CCG_DIR1  ,DPCLIENTES.CLI_DIR1  ) AS  CCG_DIR1   ,"+;
        " IF(DOC_CODIGO"+GetWhere("=","0000000000")+",DPCLIENTESCERO.CCG_TEL1  ,DPCLIENTES.CLI_TEL1  ) AS  CCG_TEL1   ,"+;
        " SFI_SERIMP "+;
        " FROM DPMOVINV "+;
        " INNER JOIN DPINV ON MOV_CODIGO=INV_CODIGO "+;
        " INNER JOIN DPDOCCLI       ON MOV_CODSUC=DOC_CODSUC AND MOV_TIPDOC=DOC_TIPDOC AND DOC_NUMERO=MOV_DOCUME AND DOC_TIPTRA='D'"+;
        " LEFT  JOIN DPSERIEFISCAL  ON DOC_SERFIS=SFI_LETRA  "+;
        " LEFT  JOIN DPCLIENTES     ON DOC_CODIGO=CLI_CODIGO "+;
        " LEFT  JOIN DPCLIENTESCERO ON CCG_CODSUC=DOC_CODSUC AND CCG_TIPDOC=DOC_TIPDOC AND CCG_NUMDOC=DOC_NUMERO "+;
        " LEFT  JOIN DPPRECIOTIP    ON MOV_LISTA=TPP_CODIGO "+;
        " WHERE MOV_CODSUC"+GetWhere("=",cCodSuc )+;
        " AND   MOV_TIPDOC"+GetWhere("=",cTipDoc )+;
        " AND   MOV_DOCUME"+GetWhere("=",cNumero )+;
        " AND   MOV_INVACT=1 " +;
        " GROUP BY MOV_ITEM "+;
        " ORDER BY MOV_ITEM "

   oTable:=OpenTable(cSql,.T.)
   aData:=oTable:aDataFill // ASQL(cSql)

// ViewArray(aData)
//  IF !TYPE("oBema")="O"
//    TDpClass():New(NIL,"oBema")
//  ENDIF
//  oDp:cFileToScr:="traza\bematech.txt"

  DPEDIT():New("BemaTech","","oBema",.F.)

  oBema:cFileDll:="BemaMFD2ES.dll"
  oBema:hDll    :=NIL
  oBema:cNamePrn:="BEMATECH"
  oBema:oMemo   :=nil
  oBema:cMemo   :="Imprimiendo "+oDp:cImpFisCom+CRLF+cTipDoc+"-"+cNumero+CRLF
  oBema:cTipDoc :=cTipDoc
  oBema:lVenta  :=(cTipDoc="FAV" .OR. cTipDoc="TIK")
  oBema:cNumero :=cNumero
  oBema:aData   :=aData

  oBema:CreateWindow(NIL,oDp:aCoors[3]/2,oDp:aCoors[4]/2,130,400+200)

  oBema:oDlg:SetColor(NIL,oDp:nGris2)
 
  @ 0.1,.1 GET oBema:oMemo VAR oBema:cMemo MULTI SIZE 290,40 COLOR NIL,oDp:nGris2 READONLY OF oBema:oDlg
  
  oBema:Activate()
  SysRefresh(.T.)
  oBema:FrmCentrar()

  oBema:hDll    :=NIL
  oBema:cNamePrn:="BEMATECH"
  // oBema:cFileDll:="BemaFI32.dll"
  
  oBema:cEstatus:=""
  oBema:oFile   :=NIL
  oBema:lMsgErr :=lMsgErr
  oBema:lErr    :=.F. // no genera ninguna Incidencia
  oBema:cFileLog:="TEMP\"+cTipDoc+ALLTRIM(cTicket)+"_"+LSTR(SECONDS())+".LOG"
  oBema:lShow   :=lShow
  oBema:cError  :=""
  oBema:lDemo   :=.T.
  oBema:nRet    :=0
  oBema:lError  :=.F.
  oBema:SETSCRIPT() //"DLL_BEMATECH")
  oBema:cSql    :=cSql

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
  oBema:uBuf  := 0
  oBema:nRet  :=oBema:BmFlagFiscal(oBema:uBuf) // Verifica si hay Cupones
  oBema:cError:=oBema:BEMA_ERROR(oBema:nRet,.T.,oBema:oMemo)
  
  uBuf:=oBema:uBuf  

  IF uBuf=0
     oBema:oMemo:Append("Imprimiendo, Estatus OK"+CRLF)
  ENDIF

  IF uBuf>0 .AND. (uBuf/1)%2=1

       MensajeInfo("Hay Cupon Abierto"+LSTR(uBuf)," Es necesario Cerrarlo")

       // puede ser cancelado

       lOpen:=.F.

       oBema:nRet:=oBema:BmCanCupom()
       oBema:cError:=oBema:BEMA_ERROR(oBema:nRet,.T.,oBema:oMemo)

       IF Empty(oBema:cError)
          oBema:oMemo:Append("Cupon Cancelado"+CRLF)
//        MensajeErr("Cupon Cancelado")
       ENDIF

       uBuf:=0

   ENDIF

   IF uBuf>0 .AND. (uBuf/2)%2=1

       MensajeInfo("Cupon sin Pago, Es Necesio Pagar o Cancelar <Anular>")
       // puede ser cancelado

       lOpen:=.F.

       oBema:nRet  :=oBema:BmCanCupom()
       oBema:cError:=oBema:BEMA_ERROR(oBema:nRet,.T.,oBema:oMemo)

       IF Empty(oBema:cError)
          oBema:oMemo:Append("Cupon Cancelado"+CRLF)
//        MensajeErr("Cupon Cancelado")
       ENDIF

   ENDIF

   IF uBuf>0 .AND. (uBuf/4)%2=1

     MensajeInfo("Horario de Verano, Solo Brasil")

   ENDIF

   IF uBuf>0 .AND. (uBuf/8)%2=1

     MensajeInfo("Horario de Verano, Solo Brasil")

   ENDIF

   IF uBuf>0 .AND. (uBuf/16)%2=1

       MensajeInfo("Sin determinaci¢n")

   ENDIF

   IF uBuf>0 .AND. (uBuf/32)%2=1
       oBema:nRet  :=oBema:BmCanCupom()
       oBema:cError:=oBema:BEMA_ERROR(oBema:nRet,.T.,oBema:oMemo)
   ENDIF

   IF uBuf>0 .AND. (uBuf/128)%2=1

       MensajeInfo("No hay Espacio en Memoria Fiscal")
       MensajeErr("Cambie la Impresora por una Nueva")       

       RETURN .T.

   ENDIF

   IF !Empty(oBema:cError)
      oBema:BEMA_CLOSE()
      RETURN .F.
   ENDIF

  // Asignar Moneda
  oBema:nRet  :=oBema:SimboloMoneda(oDp:cMoneda)
  oBema:cError:=oBema:BEMA_ERROR(oBema:nRet,.T.,oBema:oMemo)

  cAlicuota:=SPACE(79)
  oBema:bmLeerAlicuota(cAlicuota)

  oBema:cCliente:=PADR(oTable:CCG_NOMBRE,41)+PADR(oTable:CCG_RIF,18)

  IF oBema:lVenta .AND. !lOpen

    oBema:nRet:=oBema:BmAbreCup(oBema:cCliente)

  ENDIF

  IF !oBema:lVenta

     oBema:cSerie  :=PADR(oTable:SFI_SERIMP,13) // STRZERO(1,13) // Numero de Serie de la Impresora
     oBema:cRif    :=PADR(oTable:CCG_RIF,15)
     // cCliente:=PADR("Nombre",39)
     oBema:cCupon  :=STRZERO(1,6)

     oBema:cDia    :=STRZERO(DAY(oDp:dFecha)  ,2)
     oBema:cMes    :=STRZERO(MONTH(oDp:dFecha),2)
     oBema:cAno    :=RIGHT(STRZERO(YEAR(oDp:dFecha) ,4),2)

     oBema:cHora   :=_VECTOR(TIME(),":")
     oBema:cMin    :=oBema:cHora[2]
     oBema:cSeg    :=oBema:cHora[3]
     oBema:cHora   :=oBema:cHora[1]

     oBema:nRet  :=oBema:BmAbreNotaDeCredito(oBema:cCliente,oBema:cSerie,oBema:cRif,oBema:cDia,oBema:cMes,oBema:cAno,oBema:cHora,oBema:cMin,oBema:cSeg,oBema:cCupon)
   
   ENDIF

   oBema:cError:=oBema:BEMA_ERROR(oBema:nRet,.T.,oBema:oMemo)

   FOR I=1 TO LEN(aData)

       oBema:nCant  :=aData[I,3]
       oBema:nPrecio:=IIF(aData[I,13]>0,aData[I,4],aData[I,2])
       oBema:nDesc  :=aData[I,13]
       oBema:cIva   :=STRZERO(aData[I,7]*100,4)
       oBema:cIva   :=LEFT(oBema:cIva,2)+","+RIGHT(oBema:cIva,2)

       IF cTipDesc="%"
          oBema:cValDesc:=STRZERO(oBema:nDesc*100,4) // STR(nDesc*100,4,0)
       ELSE
          oBema:cValDesc:=STRZERO(oBema:nDesc*100,8)
       ENDIF

       oBema:cTipDesc:=cTipDesc
       oBema:cValDesc:=StrTran(oBema:cValDesc , "." , ",") // Quitar Puntos

       oBema:cTipCant:=IIF(oBema:nCant=INT(oBema:nCant),"I","F")  // Entero o "F" fracciondo

       IF oBema:cTipCant="F"
          oBema:cCantid :=STR(oBema:nCant,7,3)
       ELSE
          oBema:cCantid :=STR(oBema:nCant,4,0)
       ENDIF

       oBema:cCantid :=StrTran(oBema:cCantid,".","")
       oBema:cPrecio :=StrTran(Str(oBema:nPrecio/oBema:nCant,9,2),".","") // Antes era 8, Quitar Coma queda en 8

       oBema:nRet:=oBema:BmVendItem( PADR(aData[I,6],13),;
                                     PADR(aData[I,9],29),;
                                     PADR(oBema:cIva,05),;
                                     oBema:cTipCant     ,;
                                     oBema:cCantid      ,;
                                     2                  ,;
                                     oBema:cPrecio      ,;
                                     oBema:cTipDesc     ,;
                                     oBema:cValDesc )


       oBema:cError  := oBema:Bema_Error(oBema:nRet,.T.)

       // oPos:BemaErr(cError)

   NEXT 

   IF oBema:lVenta

      oBema:nRet:=oBema:BmIniFecCup("A","%","0000")
      oBema:cError  := oBema:Bema_Error(oBema:nRet,.T.)

      oBema:cTotal:=SPACE(14)
      oBema:nRet:=oBema:BmSubTotal(SPACE(14))

      oBema:nTotal:=VAL(oBema:cTotal)/100
      oBema:cPago :=STRZERO((oBema:nTotal/1)*100,14) // Formas de Pago
/*
   IF oPos:nCheque>0
     nTotal:=(oPos:nCheque)
     cPago :=STRZERO((nTotal/1)*100,14) // Formas de Pago
     nRet:=BmFormasPag(PADR("Cheque" ,16),cPago)
     cError  := Bema_Error(nRet,.T.)
     oPos:BemaErr(cError)

   ENDIF

   IF oPos:nCesta>0
     nTotal:=(oPos:nCesta)
     cPago :=STRZERO((nTotal/1)*100,14) // Formas de Pago
     nRet:=BmFormasPag(PADR("Cesta Ticket" ,16),cPago)
     cError  := Bema_Error(nRet,.T.)
     oPos:BemaErr(cError)

   ENDIF

   IF oPos:nDebito>0
     nTotal:=(oPos:nDebito)
     cPago :=STRZERO((nTotal/1)*100,14) // Formas de Pago
     nRet:=BmFormasPag(PADR("Tarjeta Débito" ,16),cPago)
     cError  := Bema_Error(nRet,.T.)
     oPos:BemaErr(cError)

   ENDIF

   IF oPos:nCredito>0
     nTotal:=(oPos:nCredito)
     cPago :=STRZERO((nTotal/1)*100,14) // Formas de Pago
     nRet:=BmFormasPag(PADR("Tarjeta Crédito" ,16),cPago)
     cError  := Bema_Error(nRet,.T.)
     oPos:BemaErr(cError)

   ENDIF

   IF oPos:nEfectivo>0

     nTotal:=(oPos:nEfectivo+oPos:nVuelto)
     cPago :=STRZERO((nTotal/1)*100,14) // Formas de Pago
     nRet:=BmFormasPag(PADR("Efectivo" ,16),cPago)
     cError  := Bema_Error(nRet,.T.)
     oPos:BemaErr(cError)
   ENDIF
*/

   ENDIF

   IF !Empty(oDp:cFileToScr)
    oDp:cFileToScr:=nil
   ENDIF

   oBema:BEMA_CLOSE()

RETURN .T.

FUNCTION BEMA_CLOSE()
  LOCAL lSave:=.F.,cMemo:=""
  LOCAL cTipo:=IF(oBema:lError,"NIMP","RAUD")

  IF !Empty(oDp:cFileToScr)
    oDp:cFileToScr:=nil
  ENDIF

  cMemo:=""
  AEVAL(DIRECTORY("TEMP\*.ERR"),{|a,n,cLine| cLine:=MEMOREAD("TEMP\"+a[1]),MsgMemo(cLine),cMemo:=cMemo+cLine+CRLF})

  IF !Empty(cMemo)
    oBema:oFile:Append(cMemo+CRLF)
  ENDIF

  oBema:oFile:Close()
  oBema:Close()

  IF oBema:lError .OR. oDp:lImpFisRegAud
     lSave:=.T.
  ENDIF

  IF lSave

    cMemo:=MemoRead(oBema:cFileLog)+CRLF+oBema:cSql

    AUDITAR(cTipo , NIL ,"DPDOCCLI" , cTipDoc+cNumero )

    nNumero:=SQLINCREMENTAL("DPAUDITOR","AUD_NUMERO","AUD_SCLAVE"+GetWhere("=","DLL_BEMATECH"))
    oTable:=OpenTable("SELECT * FROM DPAUDITOR",.F.)
    oTable:Append()
    oTable:Replace("AUD_FECHAS",oDp:dFecha    )
    oTable:Replace("AUD_FECHAO",DPFECHA()     )
    oTable:Replace("AUD_HORA  ",HORA_AP()     )
    oTable:Replace("AUD_TABLA ","DPDOCCLI"    )
    oTable:Replace("AUD_CLAVE ",cCodSuc+cTipDoc+cNumero)
    oTable:Replace("AUD_USUARI",oDp:cUsuario  )
    oTable:Replace("AUD_ESTACI",oDp:cPcName   )
    oTable:Replace("AUD_IP"    ,oDp:cIpLocal  )
    oTable:Replace("AUD_TIPO"  ,cTipo         ) // No impreso/Anulado
    oTable:Replace("AUD_MEMO"  ,cMemo         )
    oTable:Replace("AUD_SCLAVE","DLL_BEMATECH")
    oTable:Replace("AUD_NUMERO",nNumero       )
    oTable:Commit()
    oTable:End(.T.)

  ENDIF

  IF oDp:lImpFisModVal .OR. oBema:lError
    VIEWRTF(oBema:cFileLog,"Documento "+oBema:cTipDoc+oBema:cNumero)
  ENDIF

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

  If( oDp:lBema_Demo == nil, oDp:lBema_Demo := .T., ) ; If( oDp:aBema_Tasas == nil, oDp:aBema_Tasas := {}, );

  oBema:nRet:=oBema:BmPrintLig()
  oBema:cError:=oBema:Bema_Error(oBema:nRet,.T.,oBema:oMemo)

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
/*
PROCE XBEMA()
  LOCAL nRet  ,cRif:=PADR("Nombre del Cliente",41)+PADR("RIF",18)
  LOCAL nNumImp:=0,I,uBuf,cTasas:=SPACE(79)

  uBuf := 0
  nRet := BmFlagFiscal(@uBuf)

  bm:BemaLeerAlicuota(@cTasas)
  nRet := BmAbreCup(cRif)

RETURN NIL
*/
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
    cFarProc:= GetProcAdd(oDp:nBemaDLL, If( Empty( "Bematech_FI_AbreComprobanteDeVenta" ) == .T., "BmAbreCup", "Bematech_FI_AbreComprobanteDeVenta" ), .T., 7,9 )
    uResult := FWCallDLL( cFarProc,cData )
  ENDIF

  oBema:oFile:AppStr("BmAbreCup( cData )"+CRLF+"cData->"+CTOO(cData,"C")+", nResult="+CTOO(uResult,"C")+CRLF)

RETURN uResult

FUNCTION BmFlagFiscal( FlagFiscal )
  LOCAL cFarProc := NIL
  LOCAL uResult  := 0 // Modo Validación

  IF !oDp:lImpFisModVal
    cFarProc := GetProcAdd( oDp:nBemaDLL, If( Empty( "Bematech_FI_FlagsFiscales" ) == .T., "BmFlagFiscal", "Bematech_FI_FlagsFiscales" ), .T., 7,10 )
    uResult  := FWCallDLL( cFarProc,@FlagFiscal )
  ENDIF

  oBema:FlagFiscal:=FlagFiscal
  oBema:uBuf      :=FlagFiscal

  oBema:oFile:AppStr("BmFlagFiscal( FlagFiscal )"+CRLF+"BmFlagFiscal->"+CTOO(FlagFiscal,"C")+CRLF+" nResult="+CTOO(uResult,"C")+CRLF)

RETURN uResult

FUNCTION BmFechaCup( FormaPgto,Acrescimo,TipAcresc,ValAcresc,ValorPago,Mensagem )
  LOCAL cFarProc := NIL
  LOCAL uResult  := 0 // Modo Validación
  LOCAL cLine

  IF !oDp:lImpFisModVal
     cFarProc:= GetProcAdd( oDp:nBemaDLL, If( Empty( "Bematech_FI_CierraCupon" ) == .T., "BmFechaCup", "Bematech_FI_CierraCupon" ), .T., 7,8,8,8,8,8,8 )
     uResult := FWCallDLL( cFarProc,FormaPgto,Acrescimo,TipAcresc,ValAcresc,ValorPago,Mensagem )
  ENDIF

  cLine:="BmFechaCup( FormaPgto,Acrescimo,TipAcresc,ValAcresc,ValorPago,Mensagem )"+CRLF+;
         "FormaPgto->"  +CTOO(FormaPgto ,"C")+","+;
         "Acrescimo->"  +CTOO(Acrescimo ,"C")+","+;
         "TipAcresc->"  +CTOO(TipAcresc ,"C")+","+;
         "ValAcresc->"  +CTOO(ValAcresc ,"C")+","+;
         "ValorPago->"  +CTOO(ValorPago ,"C")+","+;
         "Mensagem->"   +CTOO(Mensagem  ,"C")+","+;
         "nResult="     +CTOO(uResult,"C")

  oBema:oFile:AppStr(cLine+CRLF)

RETURN uResult

FUNCTION bmLeerAlicuota( cTasas )
  LOCAL cFarProc := NIL
  LOCAL uResult  := 0 // Modo Validación
  LOCAL cLine

  IF !oDp:lImpFisModVal
    cFarProc:= GetProcAdd( oDp:nBemaDLL, If( Empty( "Bematech_FI_RetornoAlicuotas" ) == .T., "BemaLeerAlicuota", "Bematech_FI_RetornoAlicuotas" ), .T., 7,9 )
    uResult := FWCallDLL( cFarProc,@cTasas )
  ENDIF

  oBema:cLeeTasas:=cTasas
  oBema:oFile:AppStr("bmLeerAlicuota( cTasas )"+CRLF+;
                     "cTasas->"+CTOO(cTasas ,"C")+","+CRLF+;
                     "nResult="+CTOO(uResult,"C")+CRLF)

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
                     "nResult="+CTOO(uResult,"C"))


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
    cFarProc:= GetProcAdd( oDp:nBemaDLL, If( Empty( "Bematech_FI_SubTotal" ) == .T., "BmSubTotal", "Bematech_FI_SubTotal" ), .T., 7,9 ) 
    uResult := FWCallDLL( cFarProc,@SubTotal )
  ENDIF

  oBema:cTotal:=SubTotal

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
  	cFarProc:= GetProcAdd( oDp:nBemaDLL, If( Empty( "Bematech_FI_LecturaX" ) == .T., "BmLeituraX", "Bematech_FI_LecturaX" ), .T., 7 ) 
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
  LOCAL cFarProc := NIL
  LOCAL uResult  := 0 // Modo Validación
 
  IF !oDp:lImpFisModVal
    cFarProc:= GetProcAdd( oDp:nBemaDLL, If( Empty( "Bematech_FI_ImprimeComprobanteNoFiscalVinculado" ) == .T., "BmCupAdUsa", "Bematech_FI_ImprimeComprobanteNoFiscalVinculado" ), .T., 7,8 )
    uResult := FWCallDLL( cFarProc,Texto )
  ENDIF

  oBema:oFile:AppStr("BmCupAdUsa( Texto )"+CRLF+;
                     "Texto->"+CTOO(Texto,"C")+","+CRLF+;
                     "nResult="+CTOO(uResult,"C")+CRLF)

RETURN uResult

FUNCTION BmCupAdFec( )
  LOCAL cFarProc := NIL
  LOCAL uResult  := 0 // Modo Validación
 
  IF !oDp:lImpFisModVal
    cFarProc:= GetProcAdd( oDp:nBemaDLL, If( Empty( "Bematech_FI_CierraComprobanteNoFiscalVinculado" ) == .T., "BmCupAdFec", "Bematech_FI_CierraComprobanteNoFiscalVinculado" ), .T., 7 )
    uResult := FWCallDLL( cFarProc )
  ENDIF

  oBema:oFile:AppStr("BmCupAdFec( )"+CRLF+;
                     "nResult="+CTOO(uResult,"C")+CRLF)


RETURN uResult


FUNCTION BmVendItem( Codigo,Descricao,Aliquota,TpQte,Quantid,Decimal,ValUnit,TpDesc,ValDesc )
  LOCAL cFarProc:= NIL
  LOCAL uResult := 0

  IF !oDp:lImpFisModVal
     cFarProc:= GetProcAdd( oDp:nBemaDLL, If( Empty( "Bematech_FI_VendeArticulo" ) == .T., "BmVendItem", "Bematech_FI_VendeArticulo" ), .T., 7,8,8,8,8,8,7,8,8,8 )
     uResult := FWCallDLL( cFarProc,Codigo,Descricao,Aliquota,TpQte,Quantid,Decimal,ValUnit,TpDesc,ValDesc )
  ENDIF

  oBema:oFile:AppStr("BmVendItem( Codigo,Descricao,Aliquota,TpQte,Quantid,Decimal,ValUnit,TpDesc,ValDesc )"+CRLF+;
                     "Codigo->"   +CTOO(Codigo,   "C")+","+CRLF+;
                     "Descricao->"+CTOO(Descricao,"C")+","+CRLF+;
                     "Aliquota-> "+CTOO(Aliquota ,"C")+","+CRLF+;
                     "TpQte->  "  +CTOO(TpQte    ,"C")+","+CRLF+;
                     "Quantid->"  +CTOO(Quantid  ,"C")+","+CRLF+;
                     "Decimal->"  +CTOO(Decimal  ,"C")+","+CRLF+;
                     "ValUnit->"  +CTOO(ValUnit  ,"C")+","+CRLF+;
                     "TpDesc-> "  +CTOO(TpDesc   ,"C")+","+CRLF+;
                     "ValDesc->"  +CTOO(ValDesc  ,"C")+","+CRLF+;
                     "nResult="   +CTOO(uResult  ,"C")+CRLF)


RETURN uResult

FUNCTION BmFormasPag( FormaPgto,ValorPago )
  LOCAL cFarProc:= NIL
  LOCAL uResult := 0

  IF !oDp:lImpFisModVal
     cFarProc:= GetProcAdd( oDp:nBemaDLL, If( Empty( "Bematech_FI_EfectuaFormaPago" ) == .T., "BmFormasPag", "Bematech_FI_EfectuaFormaPago" ), .T., 7,8,8 )
     uResult := FWCallDLL( cFarProc,FormaPgto,ValorPago )
  ENDIF

  oBema:oFile:AppStr("BmFormasPag( FormaPgto,ValorPago )"+CRLF+;
                     "FormaPgto->"+CTOO(FormaPgto,"C")+","+CRLF+;
                     "ValorPago->"+CTOO(ValorPago,"C")+","+CRLF+;
                     "nResult="   +CTOO(uResult  ,"C")+CRLF)

RETURN uResult

FUNCTION BmIniFecCup( Acrescimo,TipAcresc,ValAcresc )
  LOCAL cFarProc:= NIL
  LOCAL uResult := 0

  IF !oDp:lImpFisModVal
     cFarProc:= GetProcAdd( oDp:nBemaDLL, If( Empty( "Bematech_FI_IniciaCierreCupon" ) == .T., "BmIniFecCup", "Bematech_FI_IniciaCierreCupon" ), .T., 7,8,8,8 )
     uResult := FWCallDLL( cFarProc,Acrescimo,TipAcresc,ValAcresc )
  ENDIF

  oBema:oFile:AppStr("BmIniFecCup( Acrescimo,TipAcresc,ValAcresc )"+CRLF+;
                     "Acrescimo->"  +CTOO(Acrescimo  ,"C")+","+CRLF+;
                     "TipAcresc->" +CTOO(TipAcresc ,"C")+","+CRLF+;
                     "ValAcresc->"+CTOO(ValAcresc,"C")+","+CRLF+;
                     "nResult="   +CTOO(uResult      ,"C")+CRLF)

RETURN uResult

FUNCTION BmTerFecCup( Mensagem )
  LOCAL cFarProc:= NIL
  LOCAL uResult := 0

  IF !oDp:lImpFisModVal

    cFarProc:= GetProcAdd( oDp:nBemaDLL, If( Empty( "Bematech_FI_FinalizarCierreCupon" ) == .T., "BmTerFecCup", "Bematech_FI_FinalizarCierreCupon" ), .T., 7,8 )
    uResult := FWCallDLL( cFarProc,Mensagem )

  ENDIF


  oBema:oFile:AppStr("BmTerFecCup( Mensagem )"+CRLF+;
                     "Mensagem->"  +CTOO(Mensagem ,"C")+","+CRLF+;
                     "nResult="   +CTOO(uResult  ,"C")+CRLF)

RETURN uResult

FUNCTION BmTfStatus( Operacao )
  LOCAL cFarProc:= NIL
  LOCAL uResult := 0

  IF !oDp:lImpFisModVal
     cFarProc:= GetProcAdd( oDp:nBemaDLL, If( Empty( "Bematech_FITEF_Status" ) == .T., "BmTfStatus", "Bematech_FITEF_Status" ), .T., 7,9 )
     uResult := FWCallDLL( cFarProc,Operacao )
  ENDIF

  oBema:oFile:AppStr("BmTfStatus( Operacao )"+CRLF+;
                     "Operacao->" +CTOO(Operacao ,"C")+","+CRLF+;
                     "nResult="   +CTOO(uResult  ,"C")+CRLF)


RETURN uResult

FUNCTION SimboloMoneda( cMoneda )
  LOCAL cFarProc:= NIL
  LOCAL uResult := 0

  IF !oDp:lImpFisModVal
     cFarProc := GetProcAdd( oDp:nBemaDLL, If( Empty( "Bematech_FI_CambiaSimboloMoneda" ) == .T., "BmSimboloMoneda", "Bematech_FI_CambiaSimboloMoneda" ), .T., 7,9 )
     uResult  := FWCallDLL( cFarProc,cMoneda )
  ENDIF

  oBema:oFile:AppStr("SimboloMoneda( cMoneda )"+CRLF+;
                     "cMoneda->" +CTOO(cMoneda ,"C")+","+CRLF+;
                     "nResult="  +CTOO(uResult  ,"C")+CRLF)

RETURN uResult

FUNCTION BmAbreNotaDeCredito( cNombre,cSerie,cRif,cDias,cMes,cAno,cHora,cMin,cSeg,cCupon )
  LOCAL cFarProc:= NIL
  LOCAL uResult := 0

  IF !oDp:lImpFisModVal
     cFarProc:= GetProcAdd( oDp:nBemaDLL, If( Empty( "Bematech_FI_AbreNotaDeCredito" ) == .T., "BmAbreNotaDeCredito", "Bematech_FI_AbreNotaDeCredito" ), .T., 7,9,9,9,9,9,9,9,9,9,9 )
     uResult := FWCallDLL( cFarProc,cNombre,cSerie,cRif,cDias,cMes,cAno,cHora,cMin,cSeg,cCupon )
  ENDIF

  oBema:oFile:AppStr("BmAbreNotaDeCredito( cNombre,cSerie,cRif,cDias,cMes,cAno,cHora,cMin,cSeg,cCupon )"+CRLF+;
                     "cNombre->"+CTOO(cNombre,"C")+","+CRLF+;
                     "cSerie->" +CTOO(cSerie ,"C")+","+CRLF+;
                     "cRif->"   +CTOO(cRif   ,"C")+","+CRLF+;
                     "cDias->"  +CTOO(cDias  ,"C")+","+CRLF+;
                     "cMes->"   +CTOO(cMes   ,"C")+","+CRLF+;
                     "cAno->"   +CTOO(cAno   ,"C")+","+CRLF+;
                     "cHora->"  +CTOO(cHora  ,"C")+","+CRLF+;
                     "cMin->"   +CTOO(cMin   ,"C")+","+CRLF+;
                     "cSeg->"   +CTOO(cSeg   ,"C")+","+CRLF+;
                     "cCupon->" +CTOO(cCupon ,"C")+","+CRLF+;
                     "nResult=" +CTOO(uResult,"C")+CRLF)

RETURN uResult

FUNCTION BmLecturaX()
  LOCAL cFarProc:= NIL
  LOCAL uResult := 0

  IF !oDp:lImpFisModVal
     cFarProc:= GetProcAdd( oDp:nBemaDLL, If( Empty( "Bematech_FI_LecturaX" ) == .T., "BmLecturaX", "Bematech_FI_LecturaX" ), .T., 7 )
     uResult := FWCallDLL( cFarProc )
  ENDIF

  oBema:oFile:AppStr("BmLecturaX()"+CRLF+;
                     "nResult="   +CTOO(uResult  ,"C")+CRLF)

RETURN uResult

/*
// IGTF
*/
FUNCTION BmIniFecCupIGTF( ValorD )
  LOCAL cFarProc:= NIL
  LOCAL uResult := 0

  IF !oDp:lImpFisModVal
    cFarProc:= GetProcAdd( oDp:nBemaDLL, "Bematech_FI_IniciaCierreCuponIGTF", .T., 7,8 )
    uResult := FWCallDLL( ValorD )
  ENDIF

  oBema:oFile:AppStr("BmIniFecCupIGTF( ValorD )"+CRLF+;
                     "ValorD->" +CTOO(ValorD ,"C")+","+CRLF+;
                     "nResult=" +CTOO(uResult  ,"C")+CRLF)


RETURN uResult
// EOF
