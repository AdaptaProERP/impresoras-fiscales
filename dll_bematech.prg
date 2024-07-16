// Programa   : DLL_BEMATECH
// Fecha/Hora : 10/07/2024
// Propósito  : Impresora BEMATECH
// Creado Por : Juan Navas
// Llamado por: DLL_IMPFISCAL       
// Aplicación : Facturación
// Tabla      : DPDOCCLI/DPMOVINV
// Referencia de funciones: https://fivetechsupport.com/forums/viewtopic.php?f=6&t=23641&start=0#p127076
// Alicuota = 16.00 G
// Alicuota =  8.00 R 
// Alicuota = 00.00 E
// Alicuota =  0.01 P
// Alicuota = 31.00 A
/*
// AbreCupon->vendearticulo->iniciacoerrecupon(Descuento)->iniciacierrecuponIGF->efectuaformapago->finalizarcierrecupon
*/

#INCLUDE "DPXBASE.CH"

PROCE MAIN(cCodSuc,cTipDoc,cNumero,lMsgErr,lShow,lBrowse,cCmd,oMemo,uValue)
  LOCAL cFecha:=oDp:dFecha
  LOCAL cHora :=TIME()
  LOCAL oTable, oData, cSql, cWhere, lVenta
  LOCAL lVenta:=.T.
  LOCAL cError:="", nRet, uBuf, cTipCant, cCantid, cTipDesc, aData:={}
  LOCAL cCodigo, cDescr
  LOCAL cPagoDolar:=0, cMtoDivisa:=0, nTotal:=0, cPago:=0, cPrecio, cNetoIGTF, cIva, cValDesc
  LOCAL cFacafe, cMaqui, cSerie
  LOCAL cDia, cMes, cAno, cHora, cMin, cSeg, cCu
  LOCAL cNombre, cRif, cDir1, cDir2, cTel1, cAlicuota
  LOCAL cMsg, cMensaje1:=SPACE(48), cMensaje2:=SPACE(48), cMensaje3:=SPACE(48)
  LOCAL cVALOR:="" // MYSQLGET("DPHISMON","HMN_VALOR","HMN_CODIGO"+GetWhere("=","USD")+"  ORDER BY CONCAT(HMN_FECHA,HMN_HORA) DESC LIMIT 1")
  // LOCAL cCodBema:='11.111.111-11'
  LOCAL oBema, cBema,cFileLog,aMemo:={},aPagos:={},I
  LOCAL nDivisa:=0,lResp,lCmdRun:=.F.
  //LOCAL error:=.F.

  PRIVATE aTipoPago:={}

  DEFAULT lMsgErr:=.T.,;
          lShow  :=.T.,;
          lBrowse:=.T.,;
          oDp:lImpFisModVal:=.T.,;
          oDp:lImpFisRegAud:=.T.,;
          oDp:cImpFisCom   :="BEMATECH",;
          cCmd             :="",;
          uValue           :=NIL

  IF Empty(cCmd)

    DEFAULT cCodSuc:=oDp:cSucursal,;
            cTipDoc:="FAV",;
            cNumero:=SQLGETMAX("DPDOCCLI","DOC_NUMERO","DOC_CODSUC"+GetWhere("=",cCodSuc)+" AND DOC_TIPDOC"+GetWhere("=",cTipDoc)+" AND DOC_TIPTRA"+GetWhere("=","D"))

    cWhere:="DOC_CODSUC"+GetWhere("=",cCodSuc)+" AND "+;
            "DOC_TIPDOC"+GetWhere("=",cTipDoc)+" AND "+;
            "DOC_NUMERO"+GetWhere("=",cNumero)+" AND "+;
            "DOC_TIPTRA"+GetWhere("=","D"    )

  ELSE
    
     cCodSuc:=""
     cTipDoc:=""
     cNumero:=""

  ENDIF

  IF lShow
     AEVAL(DIRECTORY("TEMP\*.ERR"),{|a,n| FERASE("TEMP\"+a[1])})
  ENDIF


  lVenta:=(cTipDoc="FAV" .OR. cTipDoc="TIK")

  ////////////////////INICIO/////////////////////////////////////

  IF !TYPE("oBema")="O"
    TDpClass():New(NIL,"oBema")
  ENDIF

  oBema:hDll    :=NIL
// oBema:cFileIni:=GetWinDir()+"\System32\BemaFI32.INI"
  oBema:cFileIni:="BemaFI32.INI"
  oBema:cName   :="BEMATECH"
  oBema:cFileDll:="BemaFI32.dll"
  oBema:cEstatus:=""
  oBema:oFile   :=NIL
  oBema:lMsgErr :=lMsgErr
  oBema:lErr    :=.F. // no genera ninguna Incidencia
  oBema:lShow   :=lShow
  oBema:cError  :=""
  oBema:lDemo   :=.T.
  oBema:nRet    :=0
  oBema:lError  :=.F.
  oBema:lImpErr :=.F.
  oBema:cTipDoc :=cTipDoc
  oBema:cNumero :=cNumero
  oBema:oMemo   :=oMemo
  oBema:cSql    :=""
  oBema:FlagFiscal:=NIL
  oBema:cAlicuota:=""

  IF !Empty(cNumero)
    oBema:cFileLog:="TEMP\"+cTipDoc+ALLTRIM(cNumero)+"_"+LSTR(SECONDS())+".LOG"
  ELSE
    oBema:cFileLog:="TEMP\bematech_"+cCmd+".LOG"
  ENDIF

  // FUNCTION BmVerEstado(ACX ,ST1,ST2 )
  oBema:ACX     :=NIL
  oBema:ST1     :=NIL
  oBema:ST2     :=NIL
  OBema:lViewRtf:=.F.

  cFileLog:=oBema:cFileLog

  ferase(cFileLog)

  IF FILE(cFileLog) .AND. ValType(oBema:oMemo)="O"
    oBema:MsgErr("Archivo "+cFileLog+" está abierto",oBema:oMemo)
  ENDIF

  oBema:oFile:=TFile():New(oBema:cFileLog)

  IF !FILE(oBema:cFileDll)
     oBema:lErr :=.T.
     oBema:oFile:AppStr("No se Encuenta Archivo "+oBema:cFileDll)
     BEMA_END()
     BEMA_CLOSE()
     RETURN .F.
  ENDIF

  oDp:nBemaDLL:= LoadLibrary(oBema:cFileDll)
  oBema:hDll  :=oDp:nBemaDLL

  IF Empty(oDp:nBemaDLL)
    FreeLibrary(oDp:nBemaDll)
  ENDIF

  /*
  // Comando de la Impresora, X,Z
  */
  IF !Empty(cCmd)

     oBema:oFile   :=TFile():New(oBema:cFileLog)

     cError:=BEMA_INI()
     lResp :=NIL

     IF Empty(cError) .AND. "Z"$cCmd
       lResp:=BEMA_ZETA()
       lCmdRun:=.T.
     ENDIF

     IF Empty(cError) .AND. "X"$cCmd
       lResp:=BEMA_X()
       lCmdRun:=.T.
     ENDIF

     IF Empty(cError) .AND. "FAV"$cCmd
       lResp:=BEMA_FAV()
       lCmdRun:=.T.
     ENDIF

     IF Empty(cError) .AND. "CRE"$cCmd
       lResp:=BEMA_CRE()
       lCmdRun:=.T.
     ENDIF

     IF Empty(cError) .AND. "TOTAL"$cCmd
       lResp:=BEMA_TOTAL()
       lCmdRun:=.T.
     ENDIF

     IF !lCmdRun
        // Ejecuta funciones directa desde la DLL sin necesidad declararlas con FUNCTION en este programa
        lResp:=BMRUNFUNCION(cCmd,cCmd,uValue)
     ENDIF

     oDp:uBemaResp:=lResp // respuesta bematech

     BEMA_END()
     BEMA_CLOSE()

     RETURN lResp

  ENDIF

  // nRet:=BEMA_INI() // Inicio 
  cError:=BEMA_INI()

  oBema:oFile:=TFile():New(oBema:cFileLog)

  IF !Empty(cError)

    IF oDp:lImpFisModVal

      oBema:oFile:AppStr("Error Inicializando Bematech"+CRLF)

    ELSE

      MensajeErr("Error Inicializando Bematech")
      BEMA_END()
      BEMA_CLOSE()
      RETURN .F.

     ENDIF

  ENDIF


  nDivisa:=EJECUTAR("DPDOCCLIPAGDIV",cCodSuc,cTipDoc,cNumero)

  oTable :=EJECUTAR("DLL_BEMATECH_DATA",cCodSuc,cTipDoc,cNumero)

  IF lBrowse
    oTable:Browse()
  ENDIF

  oBema:cSql    :=oTable:cSql

  // Valida si fue impreso
  IF oTable:DOC_IMPRES .AND. .F.

     oBema:cError:="Documento fué Impreso"
     oBema:oFile:AppStr(oBema:cError+CRLF)

     IF !oDp:lImpFisModVal
       oTable:End()
       BEMA_END()
       BEMA_CLOSE()
       RETURN .F.
     ENDIF

  ENDIF

  aMemo:=_VECTOR(STRTRAN(oTable:SFI_MEMO,CRLF,CHR(10)),CHR(10)) // Comentarios o Leyendas

  /*
  // 1ERO Apertura del Cupon
  */

  IF lVenta

    cNombre:= ALLTRIM(PADR(oTable:CLI_NOMBRE,41))
    cRif   := ALLTRIM(PADR(oTable:CLI_RIF,15))
    cDir1  := ALLTRIM(PADR(oTable:CLI_DIR1,15))
    cTel1  := ALLTRIM(PADR(oTable:CLI_TEL1,12))

    nRet   := BmAbreCupom(PADR(cRif,18),PADR(cNombre,41))

  ELSE

    cFacafe:=oTable:DOC_FACAFE          // MYSQLGET("DPDOCCLI", "DOC_FACAFE",cWhere)
    cMaqui:=PADR(oTable:SFI_SERIMP,10)  // ALLTRIM(PADR(MYSQLGET("DPEQUIPOSPOS","EPV_IMPFIS","EPV_SERIEF"=oTable:DOC_SERFIS),10))

    cNombre:= ALLTRIM(PADR(oTable:CLI_NOMBRE,41))
    cRif   := ALLTRIM(PADR(oTable:CLI_RIF,15))
    cDir1  := ALLTRIM(PADR(oTable:CLI_DIR1,15))
    cTel1  := ALLTRIM(PADR(oTable:CLI_TEL1,12))
    cCu    := SUBST(cFacafe,5,6)
    cSerie := SUBST(cMaqui,1,10)
    cDia   := STRZERO(DAY(oDp:dFecha)  ,2)
    cMes   := STRZERO(MONTH(oDp:dFecha),2)
    cAno   := RIGHT(STRZERO(YEAR(oDp:dFecha) ,4),2)
    cHora  := _VECTOR(TIME(),":")
    cMin   := cHora[2]
    cSeg   := cHora[3]
    cHora  := cHora[1]

    nRet   := BmAbreNotaDeCredito(PADR(cNombre,41),cSerie,PADR(cRif,18),cDia,cMes,cAno,cHora,cMin,cSeg,cCu)

  ENDIF

  oTable:Gotop()

  /*
  // 2DO VENDEITEM 
  */
  WHILE !oTable:Eof()

    cCodigo  := oTable:MOV_CODIGO
    cDescr   := oTable:INV_DESCRI 
    cIva     := "ii"

    //oTable:Replace("MOV_IVA",16) // para validar si es IVA

    IF oTable:MOV_IVA>0 
      cAlicuota:= LSTR(oTable:MOV_IVA,6,2)
      cIva     := STRTRAN(cAlicuota,".","")
    ENDIF

    cTipCant := "F"
    cCantid  := StrTran(STR(oTable:MOV_CANTID,7,3),".","")
    cPrecio  := StrTran(STR(oTable:MOV_PRECIO,12,2),".","")
    cTipDesc := "%" // %=Relativo Y $=Absoluto
    cValDesc := STRZERO(oTable:MOV_DESCUE*100,4)

    nRet:=BmVendItem( PADR(cCodigo,13), PADR(cDescr,29), PADR(cIva,05), cTipCant, cCantid, 2, cPrecio, cTipDesc, cValDesc )

    oTable:DbSkip()

    SysRefresh(.T.)

   ENDDO

   oTable:End()

   /*
   // 3ERO INICIA DEL CIERRE CUPON
   */
 
   nRet:=BmIniFecCup("A","%","0000")

   IF cMtoDivisa>0

     nRet:=BmFormasPag(PADR("DIVISAS" ,16),cPagoDolar) 
     cError:=Bema_Error(nRet,.T.)
    //BemaError(cError)

   ENDIF

   // Pago en Bs
   aPagos:=EJECUTAR("BEMATECH_PAGOS",cCodSuc,cTipDoc,cNumero)

   FOR I=1 TO LEN(aPagos)
     cPago:=STRZERO(aPagos[I,2]*100,14)
     nRet:=BmFormasPag(PADR(aPagos[I,1],16),cPago) // Pago en Bs
     cError:=Bema_Error(nRet,.T.)
   NEXT I
   
/*
   cMsg:=PADR("Ticket : "+oTable:DOC_NUMERO,48)+;
         PADR(cMensaje1,48)+;
         PADR(cMensaje2,48)+;
         PADR(cMensaje3,48)
*/

   oTable:Gotop()
   cMsg:=PADR("Ticket : "+oTable:DOC_NUMERO,48)
   AEVAL(aMemo,{|a,n| cMsg:=cMsg+PADR(a,48)})

   IF nDivisa>0
     cPagoDolar:=LSTR(nDivisa,14,2) //  STRZERO(nDivisa*100,14)
     // cPagoDolar:=STRTRAN(cPagoDolar,",", ".")
     nRet:=BmIniFecCupIGTF(cPagoDolar)    
   ELSE
     nRet:=BmIniFecCupIGTF("0")    
   ENDIF

   /*
   // Cierre el Cupon
   */
   nRet  :=BmTerFecCup( cMsg )

   cError:=Bema_Error(nRet,.T.)

/*
   IF lVenta
     nRet:=BmTerFecCup( cMsg )
     cError:=Bema_Error(nRet,.T.)
   ELSE
     nRet:=BmTerFecCup( PADR("Ticket : "+oTable:DOC_NUMERO,48) )
     cError:=Bema_Error(nRet,.T.)
   ENDIF
*/

   BEMA_END()
   BEMA_CLOSE()

/*
   IF oDp:nBemaDll<>NIL
      FreeLibrary(oDp:nBemaDll)
      oDp:nBemaDll:=NIL
   ENDIF
*/
   SysRefresh(.T.)

   IF !oBema:lImpErr
     SQLUPDATE("DPDOCCLI","DOC_IMPRES",.T.,cWhere)
   ENDIF

   BEMA_CLOSE()

RETURN !oBema:lImpErr 


/////////////////////////////////////////////////////
//                  FUNCIONES                      //
/////////////////////////////////////////////////////

FUNCTION BemaError(cError)

 IF !Empty(cError)

   oBema:lImpErr:=.T.
   oBema:lError :=.T.

   SQLUPDATE("DPDOCCLI","DOC_IMPRES",.F.,cWhere)

   IF oDp:lImpFisModVal
      oBema:oFile:AppStr("Error en Impresión, Es necesario Reimprimir el Ticket",cError+CRLF)
   ELSE
      MensajeErr("Error en Impresión, Es necesario Reimprimir el Ticket",cError)
   ENDIF

 ENDIF

RETURN .T.

FUNCTION BEMA_CLOSE()
  LOCAL lSave:=.F.,cMemo:="",nNumero,oFont 
  LOCAL cTipo:=IF(oBema:lError,"NIMP","RAUD")

  IF !Empty(oDp:cFileToScr)
    oDp:cFileToScr:=nil
  ENDIF

  cMemo:=""
  AEVAL(DIRECTORY("TEMP\*.ERR"),{|a,n,cLine| cLine:=MEMOREAD("TEMP\"+a[1]),IF(oBema:lShow,MsgMemo(cLine),NIL),cMemo:=cMemo+cLine+CRLF})

  IF !Empty(cMemo)
    oBema:oFile:AppStr(cMemo+CRLF)
  ENDIF

  IF(ValType(oBema:oFile)="O",oBema:oFile:Close(),NIL)
  oBema:oFile:=NIL

  IF oBema:lShow .AND. !oBema:lViewRtf

    DEFINE FONT oFont     NAME "Courier"   SIZE 0, -10

    VIEWRTF(oBema:cFileLog,"Archivo "+oBema:cFileLog,oFont)

    oBema:lViewRtf:=.F.

  ENDIF

  
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
// Abrir el Cupon
*/
FUNCTION BmAbreCupom(cNroRif,cNombCli,cDirTelf)
  LOCAL cFarProc:= NIL
  LOCAL uResult := NIL
  LOCAL cFunc:="Bematech_FI_AbreCupom"

  IF !oDp:lImpFisModVal
    cFarProc:= GetProcAddress( oDp:nBemaDLL,cFunc,.T.,7,9,9,9)
    uResult := CallDLL( cFarProc,cNroRif,cNombCli,cDirTelf)
  ENDIF

  oBema:oFile:AppStr(cFunc+"(cNroRif,cNombCli,cDirTelf)"+CRLF+" cNroRif->"+CTOO(cNroRif,"C")+",cNombCli->"+CTOO(cNombCli,"C")+",cDirTelf->"+CTOO(cDirTelf)+CRLF+;
                     ",nResult= "+CTOO(uResult,"C")+CRLF)

RETURN uResult

FUNCTION BmAbreNotaDeCredito( cNombre,cSerie,cRif,cDias,cMes,cAno,cHora,cMin,cSeg,cCu )
  LOCAL cFunc   :="Bematech_FI_AbreNotaDeCredito"
  LOCAL cFarProc,uResult

  IF !oDp:lImpFisModVal

   cFarProc:= GetProcAddress( oDp:nBemaDLL,cFunc, .T., 7,9,9,9,9,9,9,9,9,9,9 )
   uResult := CallDLL( cFarProc,cNombre,cSerie,cRif,cDias,cMes,cAno,cHora,cMin,cSeg,cCu )

  ENDIF

  oBema:oFile:AppStr("BmAbreNotaDeCredito( cNombre,cSerie,cRif,cDias,cMes,cAno,cHora,cMin,cSeg,cCu )"+CRLF+;
                     "cNombre->"+CTOO(cNombre,"C")+","+CRLF+;
                     "cSerie ->"+CTOO(cSerie ,"C")+","+CRLF+;
                     "cRif   ->"+CTOO(cRif   ,"C")+","+CRLF+;
                     "cDias  ->"+CTOO(cDias  ,"C")+","+CRLF+;
                     "cMes   ->"+CTOO(cMes   ,"C")+","+CRLF+;
                     "cAno   ->"+CTOO(cAno   ,"C")+","+CRLF+;
                     "cHora  ->"+CTOO(cHora  ,"C")+","+CRLF+;
                     "cMin   ->"+CTOO(cMin   ,"C")+","+CRLF+;
                     "cSeg   ->"+CTOO(cSeg   ,"C")+","+CRLF+;
                     "cCu    ->"+CTOO(cCu    ,"C")+","+CRLF+;
                     "nResult=" +CTOO(uResult,"C")+CRLF)

RETURN uResult

FUNCTION BmVendItem( Codigo,Descricao,Aliquota,TpQte,Quantid,Decimal,ValUnit,TpDesc,ValDesc )
  LOCAL cFarProc:= NIL
  LOCAL uResult := 0
  LOCAL cFunc   :="Bematech_FI_VendeArticulo"

  IF !oDp:lImpFisModVal
     cFarProc:= GetProcAddress( oDp:nBemaDLL,cFunc,.T., 7,8,8,8,8,8,7,8,8,8 )
     uResult := CallDLL( cFarProc,Codigo,Descricao,Aliquota,TpQte,Quantid,Decimal,ValUnit,TpDesc,ValDesc )
  ENDIF

  oBema:oFile:AppStr(cFunc+"( Codigo,Descricao,Aliquota,TpQte,Quantid,Decimal,ValUnit,TpDesc,ValDesc )"+CRLF+;
                     " Codigo->"   +CTOO(Codigo,   "C")+","+CRLF+;
                     " Descricao->"+CTOO(Descricao,"C")+","+CRLF+;
                     " Aliquota-> "+CTOO(Aliquota ,"C")+","+CRLF+;
                     " TpQte->  "  +CTOO(TpQte    ,"C")+","+CRLF+;
                     " Quantid->"  +CTOO(Quantid  ,"C")+","+CRLF+;
                     " Decimal->"  +CTOO(Decimal  ,"C")+","+CRLF+;
                     " ValUnit->"  +CTOO(ValUnit  ,"C")+","+CRLF+;
                     " TpDesc-> "  +CTOO(TpDesc   ,"C")+","+CRLF+;
                     " ValDesc->"  +CTOO(ValDesc  ,"C")+","+CRLF+;
                     " nResult="   +CTOO(uResult  ,"C")+CRLF)

RETURN uResult

/*
// Pago IGTF
*/

FUNCTION BmIniFecCupIGTF( cPagoDolar )
 LOCAL cFarProc:= NIL
 LOCAL uResult := NIL
 LOCAL cFunc   :="Bematech_FI_IniciaCierreCuponIGTF"

 IF !oDp:lImpFisModVal
    cFarProc:= GetProcAddress( oDp:nBemaDLL,cFunc, .T., 7,8 )
    uResult := CallDLL( cFarProc,cPagoDolar )
 ENDIF

 oBema:oFile:AppStr(cFunc+"( cPagoDolar )"+CRLF+;
                     " cPagoDolar->"   +CTOO(cPagoDolar,"C")+","+CRLF+;
                     " nResult="       +CTOO(uResult   ,"C")+CRLF)

RETURN uResult

/*
// Inicia el Cierre del Cupon
*/
FUNCTION BmIniFecCup( Acrescimo,TipAcresc,ValAcresc )
 LOCAL cFarProc:= NIL
 LOCAL uResult := NIL
 LOCAL cFunc   :="Bematech_FI_IniciaCierreCupon"

 IF !oDp:lImpFisModVal
    cFarProc:= GetProcAddress( oDp:nBemaDLL,cFunc, .T., 7,8,8,8 )
    uResult := CallDLL( cFarProc,Acrescimo,TipAcresc,ValAcresc )
 ENDIF

 oBema:oFile:AppStr(cFunc+"(Acrescimo,TipAcresc,ValAcresc )"+CRLF+;
                    " Acrescimo->"+CTOO(Acrescimo,"C")+","+CRLF+;
                    " TipAcresc->"+CTOO(TipAcresc,"C")+","+CRLF+;
                    " ValAcresc->"+CTOO(ValAcresc,"C")+","+CRLF+;
                    " nResult="   +CTOO(uResult  ,"C")+CRLF)

RETURN uResult

/*
// Formas de Pago
*/
FUNCTION BmFormasPag( FormaPgto,ValorPago )
  LOCAL cFarProc:= NIL
  LOCAL uResult := NIL
  LOCAL cFunc   :="Bematech_FI_EfectuaFormaPago"

  IF !oDp:lImpFisModVal
     cFarProc:= GetProcAddress( oDp:nBemaDLL, cFunc, .T., 7,8,8 )
     uResult := CallDLL( cFarProc,FormaPgto,ValorPago )
  ENDIF

  oBema:oFile:AppStr(cFunc+"( FormaPgto,ValorPago )"+CRLF+;
                     " FormaPgto->"   +CTOO(FormaPgto,"C")+","+CRLF+;
                     " ValorPago->"   +CTOO(ValorPago,"C")+","+CRLF+;
                     " nResult="      +CTOO(uResult  ,"C")+CRLF)

RETURN uResult

FUNCTION BmTerFecCup( Mensagem )
  LOCAL cFarProc:= NIL
  LOCAL uResult := NIL
  LOCAL cFunc   :="Bematech_FI_FinalizarCierreCupon"

  IF !oDp:lImpFisModVal
     cFarProc:= GetProcAddress( oDp:nBemaDLL,cFunc, .T., 7,8 )
     uResult := CallDLL( cFarProc,Mensagem )
  ENDIF

  oBema:oFile:AppStr(cFunc+"("+CTOO(Mensagem,"C")+")"+CRLF+" nResult="      +CTOO(uResult  ,"C")+CRLF )

RETURN uResult

FUNCTION BEMA_INI()
   LOCAL nRet,cError:="",I
   LOCAL cWinDir :=GetWinDir()+"\System32\"
   LOCAL cFileDll:="bemafi32.dll"
   LOCAL aDlls:={}

   DEFAULT oDp:lBema_Demo := .T.,;
           oDp:aBema_Tasas:= {} ,;
           oDp:nBemaDll   := LoadLibrary("bemafi32.dll")

   nRet:=BmPrintLig()

   // cError:=BEMA_ERROR(nRet,.F.)
   cError:=BEMA_ERROR(nRet,.T.,.T.)

   IF "Cupón fiscal abierto" $ cError

     MensajeInfo("Hay un Ticket Abierto"," Es necesario Cerrarlo")

     nRet  :=BmCanCupom()
     cError:=Bema_Error(nRet,.T.)

     IF EMPTY(cError)
       MensajeErr("Ticket Anulado Satisfactoriamente")
     ENDIF

   ENDIF

//   BmFlagFiscal()
//   BEMA_ALICUOTAS()

RETURN cError

/*
// Iniciar Impresora
*/
FUNCTION BmPrintLig()
  LOCAL cFarProc:= NIL
  LOCAL uResult := 1
  LOCAL cFunc   :="Bematech_FI_VerificaImpressoraLigada"

  IF !oDp:lImpFisModVal

    cFarProc:= GetProcAddress( oDp:nBemaDLL,cFunc, .T., 7 )
    uResult := CallDLL( cFarProc )

  ELSE

    oBema:oFile:AppStr("Modo Validación Activo "+CRLF)

  ENDIF

  IF ValType(oBema:oFile)="O"

    oBema:oFile:AppStr("Iniciación hDLL="+LSTR(oDp:nBemaDLL)+",BmPrintLig(),"+"FUNCTION="+cFunc+","+;
                       "nResult="+CTOO(uResult  ,"C")+CRLF)

  ENDIF

RETURN uResult

/*
// Estatus Error
*/
FUNCTION BEMA_ERROR(nRet,lShow)
  LOCAL cError:=""

  DEFAULT nRet  :=1,;
          lShow := .T.

  // If( lShow == nil, lShow := .T., ) 

  IF nRet <> 1

    IF nRet=1
      RETURN ""
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
      cError:="Archivo BemaFI32.INI no encontrado, copielo en "+GetWinDir()+"\System32\"
   ENDIF

   IF nRet=-5
      cError:="Error en Apertura, Posiblemente ya está Abierto el Puerto"
   ENDIF

   IF nRet=-6
      cError:="Ninguna Impresora fué Encontrada, Verifique si está Encendida o Conectada al Cable Serial"
   ENDIF

   IF nRet = -8
      cError:="Error al Crear o Grabar en el Archivo status.txt o retorno.txt "
   ENDIF

   cError:="Error:"+CTOO(nRet,"C")+", "+cError

   oBema:oFile:AppStr(cError+CRLF)

   IF oBema:lShow

     IF !oDp:lImpFisModVal
       MensajeErr(cError,"Error Impresora Bematech")
     ENDIF

   ENDIF

 ELSE

    cError:=BEMATECH_CHECK() // EJECUTAR("DLL_BEMATECH_CHECK")

 ENDIF
 

RETURN cError

FUNCTION IFESTATUS()

 cFecha:=_VECTOR(DTOC(oDp:dFecha),"/")
 cFecha:=cFecha[1]+cFecha[2]+RIGHT(cFecha[3],2)
 cHora :=STRTRAN(TIME(),":","")

 // Verifica el Estatus de la Impresora
 uBuf  := 0
 nRet  := BmFlagFiscal(@uBuf) // Verifica si hay Cupones
 cError:= Bema_Error(nRet,.T.)

 // Asignar Moneda
 nRet:=BmSimboloMoneda(oDp:cMoneda) // "Bs")
 //cError:= Bema_Error(nRet,.T.)

 IF uBuf=0
   //SetMsgInfo("Bematech Imprimiendo, Estatus OK")
 ENDIF

 IF uBuf>0 .AND. (uBuf/1)%2=1

    MensajeInfo("Hay Cupon Abierto"+LSTR(uBuf)," Es necesario Cerrarlo")

    // puede ser cancelado

    lOpen:=.F.
    nRet:=BmCanCupom()

    IF Empty(cError)
       MensajeErr("Cupon Cancelado")
    ENDIF

    uBuf:=0
 ENDIF

 IF uBuf>0 .AND. (uBuf/2)%2=1

    MensajeInfo("Cupon sin Pago, Es Necesio Pagar o Cancelar <Anular>")
    // puede ser cancelado

    lOpen :=.F.
    nRet  :=BmCanCupom()

    IF Empty(cError)
       MensajeErr("Cupon Cancelado")
    ENDIF
 ENDIF

 IF uBuf>0 .AND. (uBuf/16)%2=1
    MensajeInfo("Sin determinaci¢n")
 ENDIF

 IF uBuf>0 .AND. (uBuf/32)%2=1
    //    MensajeInfo("Permite Cancelar <Anular> Cupon")
    nRet:=BmCanCupom()

    IF Empty(cError)
    //     MensajeErr("Cupon Cancelado")
    ENDIF
 ENDIF

 IF uBuf>0 .AND. (uBuf/128)%2=1
    MensajeInfo("No hay Espacio en Memoria Fiscal")
    MensajeErr("Cambie la Impresora por una Nueva")       
    RETURN .T.
 ENDIF

 IF !Empty(cError)
    RETURN .F.
 ENDIF

 cAlicuota:=SPACE(79)
 BemaLeerAlicuota(@cAlicuota)
 //MensajeInfo(cAlicuota," Alicuotas Conocidas")

RETURN cError

FUNCTION BEMA_END()
  LOCAL oFont

  IF oDp:nBemaDll<>NIL
     FreeLibrary(oDp:nBemaDll)
     oDp:nBemaDll:=NIL
  ENDIF

  IF TYPE("oBEMA")="O" .AND. ValType(oBema:oFile)="O"
     oBema:oFile:AppStr("BEMA_END()"+CRLF)
     oBema:oFile:End()
     oBema:oFile:=NIL
  ENDIF

  IF oBema:lShow .AND. !oBema:lViewRtf

    DEFINE FONT oFont     NAME "Courier"   SIZE 0, -10

    VIEWRTF(oBema:cFileLog,"Archivo "+oBema:cFileLog,oFont)

    oBema:lViewRtf:=.F.

 ENDIF

RETURN .T.

/*
// Cancela Cupon
*/
FUNCTION BmCanCupom()
RETURN BMRUNFUNCION("Bematech_FI_CancelaCupom","BmCanCupom()")

/*
// Cancela Item
*/
FUNCTION BmCancItem()
RETURN BMRUNFUNCION("Bematech_FI_CancelaItemAnterior","BmCancItem()")

/*
// Abrir Gaveta
*/
FUNCTION BmAbreGav()
RETURN BMRUNFUNCION("Bematech_FI_AcionaGaveta","BmAbreGav()")

/*
// Programas las tasas de IVA
*/
FUNCTION BMFLAGFISCAL(FlagFiscal) 
  LOCAL cFunc   :="Bematech_FI_FlagsFiscais"
  LOCAL cFarProc:=NIL

  oBema:FlagFiscal:=NIL

  IF !oDp:lImpFisModVal
     cFarProc:=GetProcAddress(oDp:nBemaDLL,cFunc,.T.,7,10) 
     uResult :=CallDLL(cFarProc,@FlagFiscal)
     oBema:FlagFiscal:=FlagFiscal
   ENDIF

   IF ValType(oBema:oFile)="O"
     oBema:oFile:AppStr(cFunc+"(FlagFiscal)"+"->"+CTOO(FlagFiscal,"C")+"),Result->"+CTOO(uResult,"C")+CRLF)
   ENDIF

  SysRefresh(.T.)

RETURN uResult

/*
// Programar Alicuotas
*/
FUNCTION BEMA_PROGALICUOTA(cTasas)
  LOCAL cFunc   :="Bematech_FI_ProgramaAliquota"
  LOCAL cFarProc:=NIL
  LOCAL nResult :=NIL

  IF !oDp:lImpFisModVal
    cFarProc:=GetProcAddress(oDp:nBemaDLL,cFunc,.T.,7,9) 
    uResult :=CallDLL(cFarProc,cTasas)
    oBema:FlagFiscal:=FlagFiscal
  ENDIF

  IF ValType(oBema:oFile)="O"
    oBema:oFile:AppStr(cFunc+"(cTasa)"+"->"+CTOO(cTasa,"C")+"),Result->"+CTOO(uResult,"C")+CRLF)
  ENDIF

RETURN nResult

/*
// Ejecuta funciones Bematecha, ahorra uso innecesario de funciones
*/
FUNCTION BMRUNFUNCION(cFunc,cName,uParam)
  LOCAL cFarProc:=NIL,uResult:=NIL

  DEFAULT cName   :="",;
          uResult :=NIL

  IF !oDp:lImpFisModVal

    IF uResult=NIL
      cFarProc:= GetProcAddress(oDp:nBemaDLL,cFunc,.T.,7) 
      uResult := CallDLL(cFarProc) 
    ELSE
      cFarProc:= GetProcAddress(oDp:nBemaDLL,cFunc,.T.,7,9 ) 
      uResult := CallDLL(cFarProc,@uParam) 
      oDp:uBemaResp:=uParam
    ENDIF

  ENDIF

  IF ValType(oBema:oFile)="O"
     oBema:oFile:AppStr(cName+","+cFunc+",Result->"+CTOO(uResult,"C")+CRLF)
  ENDIF

RETURN uResult

/*
// Reporte Zeta
*/
FUNCTION BEMA_ZETA(dT,Hs)
   LOCAL uResult:=NIL, cFarProc
   LOCAL cFunc  :="Bematech_FI_ReducaoZ"  // BemaReporteZeta    

   DEFAULT dT:=DTOC(DATE()),;
           Hs:=TIME()

   IF !oDp:lImpFisModVal
     cFarProc:=GetProcAddress(oDp:nBemaDLL,cFunc,.T.,7,9 ,9 ) 
     uResult :=CallDLL(cFarProc,dT,Hs)
   ENDIF

   IF ValType(oBema:oFile)="O"
     oBema:oFile:AppStr(cFunc+"(dt->"+CTOO(dT,"C")+;
                                 "hS->"+CTOO(Hs,"C")+"),Result->"+CTOO(uResult,"C")+CRLF)
   ENDIF

  SysRefresh(.T.)

RETURN uResult

/*
// Resetear Impresora
*/
FUNCTION BEMA_RESET()
RETURN BMRUNFUNCION("Bematech_FI_ResetaImpresora","BEMA_RESET")

/*
// Anular Cupon
*/
FUNCTION BEMA_ANULA()
RETURN BMRUNFUNCION("Bematech_FI_AnulaCupon","BEMA_ANULA")

/*
// Reporte X
*/
FUNCTION BEMA_X()
RETURN BMRUNFUNCION("Bematech_FI_LecturaX","BEMA_X")

FUNCTION BEMA_ALICUOTAS()
  LOCAL cAlicuota:=SPACE(60), cFarProc,uResult:=NIL
  // LOCAL cFunc  :="Bematech_FI_RetornoAlicuotas" 
  LOCAL cFunc  :="Bematech_FI_RetornoAliquotas" 

  oBema:cAlicuota:=""

  IF !oDp:lImpFisModVal
    cFarProc:=GetProcAddress(oDp:nBemaDLL,cFunc,.T.,7,9) 
    uResult :=CallDLL(cFarProc,@cAlicuota)
    oBema:cAlicuota:=cAlicuota
  ENDIF

  IF ValType(oBema:oFile)="O"
    oBema:oFile:AppStr("BEMA_ALICUOTAS(),"+cFunc+"(),Alicuota->"+CTOO(cAlicuota,"C")+",Result->"+CTOO(uResult,"C")+CRLF)
  ENDIF

  SysRefresh(.T.)

RETURN uResult


/*
// Devuele Ultimo número de Factura
*/
FUNCTION BEMA_FAV()
  LOCAL uResult:=SPACE(06), cFarProc
  LOCAL cFunc  :="Bematech_FI_NumeroComprobanteFiscal"  

  IF !oDp:lImpFisModVal
    cFarProc:=GetProcAddress(oDp:nBemaDLL,cFunc,.T.,7,9) 
    uResult :=CallDLL(cFarProc,uResult)
  ENDIF

  IF ValType(oBema:oFile)="O"
    oBema:oFile:AppStr(cFunc+"(),Result->"+CTOO(uResult,"C")+CRLF)
  ENDIF

  SysRefresh(.T.)

RETURN uResult

/*
// Devuele Ultimo número de Devolución/Nota de Crédito
*/
FUNCTION BEMA_CRE()
  LOCAL uResult:=SPACE(06), cFarProc
  LOCAL cFunc  :="Bematech_FI_ContadorNotaDeCreditoMFD"  

  IF !oDp:lImpFisModVal
    cFarProc:=GetProcAddress(oDp:nBemaDLL,cFunc,.T.,7,9) 
    uResult :=CallDLL(cFarProc,uResult)
  ENDIF

  IF ValType(oBema:oFile)="O"
    oBema:oFile:AppStr(cFunc+"(),Result->"+CTOO(uResult,"C")+CRLF)
  ENDIF

  SysRefresh(.T.)

RETURN uResult


/*
// Devuele totalizadores
*/
FUNCTION BEMA_TOTAL()
  LOCAL uResult:=SPACE(445), cFarProc
  LOCAL cFunc  :="Bematech_FI_VerificaTotalizadoresParciales"  

  IF !oDp:lImpFisModVal
    cFarProc:=GetProcAddress(oDp:nBemaDLL,cFunc,.T.,7,9) 
    uResult :=CallDLL(cFarProc,uResult)
  ENDIF

  IF ValType(oBema:oFile)="O"
    oBema:oFile:AppStr(cFunc+"(),Result->"+CTOO(uResult,"C")+CRLF)
  ENDIF

RETURN uResult

FUNCTION BmSimboloMoneda(cMoneda)
  LOCAL cFunc:="Bematech_FI_AlteraSimboloMoeda"
  LOCAL uResult,cFarProc 

  IF !oDp:lImpFisModVal
    cFarProc:= GetProcAddress(oDp:nBemaDLL,cFunc,.T.,7,9 ) 
    uResult := CallDLL(cFarProc,cMoneda ) 
  ENDIF

  IF ValType(oBema:oFile)="O"
    oBema:oFile:AppStr("BmSimboloMoneda(cMoneda)"+cFunc+"(),Result->"+CTOO(uResult,"C")+CRLF)
  ENDIF

RETURN uResult

FUNCTION BmFlagFiscal(FlagFiscal )
  LOCAL cFunc:="Bematech_FI_FlagsFiscais"
  LOCAL uResult,cFarProc 

  IF !oDp:lImpFisModVal
    cFarProc:= GetProcAddress(oDp:nBemaDLL,cFunc,.T.,7,10 )
    uResult := CallDLL(cFarProc,@FlagFiscal )
  ENDIF

  IF ValType(oBema:oFile)="O"
    oBema:oFile:AppStr("BBmFlagFiscal(FlagFiscal )"+cFunc+"(),FlagFiscal->"+CTOO(FlagFiscal,"C")+",Result->"+CTOO(uResult,"C")+CRLF)
  ENDIF

  oBema:FlagFiscal:=FlagFiscal

RETURN uResult

FUNCTION MsgErr(cMsg,oMemo)

  IF ValType(oMemo)="O"
  ELSE
    MsgMemo(cMsg,"Bematech Mensaje")
  ENDIF

RETURN .T.

FUNCTION BEMATECH_CHECK()
  LOCAL cError:="",nRet,lVerCup:=.T.,lShow:=.T.
  LOCAL iACK,iST1,iST2

  WHILE .T.

    iACK := 0
    iST1 := 0
    iST2 := 0
    nRet := BmVerEstado( @iACK, @iST1, @iST2 )

    iACK:=oBema:ACX
    iST1:=oBema:ST1
    iST2:=oBema:ST2

    IF iACK = 21
      MensajeErr("La impresora ha retornado NAK !", [Atención] )
    ELSE

    IF ( iST1 <> 0 ) .OR. ( iST2 <> 0 )

        cError:=""
        // Analiza ST1

        IF ( iST1 >= 128 )
           iST1 := iST1 - 128
           cError := cError+ "Fin de Papel" + chr(13)
        ENDIF

        IF ( iST1 >= 64 )
            iST1 := iST1 - 64
            cError := cError+ "Poco Papel" + chr(13)
        ENDIF

        IF ( iST1 >= 32 )
            iST1 := iST1 - 32
            cError := cError+ "Error en el Reloj" + chr(13)
        ENDIF

        IF ( iST1 >= 16 )
          iST1 := iST1 - 16
          cError := cError+ 'Impresora con error' + chr(13)
        ENDIF

        IF ( iST1 >= 8 )
          iST1 :=  iST1 - 8
          cError := cError+ "Primer dato del comando no fue ESC" + chr(13)
        ENDIF

        IF iST1 >= 4
          iST1 :=  iST1 - 4
          cError := cError+ "Comando inexistente" + chr(13)
        ENDIF

       if iST1 >= 2
          iST1 :=  iST1 - 2
          if lVerCup
             cError := cError+ "Cupón fiscal abierto" + chr(13)
          ENDIF
       ENDIF

       IF iST1 >= 1
          iST1 :=  iST1 - 1
          cError := cError+ "Número de parámetros inválidos" + chr(13)
       ENDIF

       //  Analisa ST2
       IF iST2 >= 128
          iST2 :=  iST2 - 128
          cError := cError+ "Tipo de parámetro de comando inválido" + chr(13)
       ENDIF

       IF iST2 >= 64
          iST2 :=  iST2 - 64
          cError := cError+ "Memória fiscal llena" + chr(13)
       ENDIF

       IF iST2 >= 32
          iST2 :=  iST2 - 32
          cError := cError+ "Error en la CMOS" + chr(13)
       ENDIF

       IF iST2 >= 16
          iST2 :=  iST2 - 16
          cError := cError+ "Alicuota no programada" + chr(13)
       ENDIF

       IF iST2 >= 8
          iST2 :=  iST2 - 8
          cError := cError+ "Capacidad de Alicuota Programables llena" + chr(13)
       ENDIF

       IF iST2 >= 4
          iST2 :=  iST2 - 4
          cError := cError+ "Cancelamiento no permitido" + chr(13)
       ENDIF

       IF iST2 >= 2
          iST2 :=  iST2 - 2
          cError := cError+ "RIF del propietario no Programados" + chr(13)
       ENDIF

       IF iST2 >= 1
          iST2 :=  iST2 - 1
          cError := cError+ "Comando no ejecutado" + chr(13)
       ENDIF

       //Alert (cError, "Atención" )

       IF !EMPTY(cError)
          cError:="Error:"+LSTR(nRet)+", "+cError
          IF lShow
             MensajeErr(cError,"Error Impresora Bematech.")
           ENDIF
       ENDIF

     ENDIF

       // Return (cError)
    ENDIF

     IF EMPTY(cError) .OR.  !("Fin de Papel" $ cError .OR. "Poco Papel" $ cError)
        EXIT
     ENDIF

  ENDDO

  //??"endif cError", cError

  IF !EMPTY(cError)
     cError:="Error:"+LSTR(nRet)+", "+cError
     IF lShow
       MensajeErr(cError,"Error Impresora Bematech")
     ENDIF
  ENDIF

RETURN cError

FUNCTION BmVerEstado(ACX ,ST1,ST2 ) 
   LOCAL hDLL   :=oDp:nBemaDLL
   LOCAL uResult:=NIL 
   LOCAL cFunc  :="Bematech_FI_VerificaEstadoImpresora"
   LOCAL cFarProc 

   oBema:ACX:=ACX
   oBema:ST1:=ST1
   oBema:ST2:=ST2

   IF !oDp:lImpFisModVal
     cFarProc:= GetProcAddress(hDLL,cFunc,.T.,7,10 ,10,10 )
     uResult := CallDLL(cFarProc,@ACX ,@ST1,@ST2 )

     oBema:ACX:=ACX
     oBema:ST1:=ST1
     oBema:ST2:=ST2
   ENDIF

   oBema:oFile:AppStr("BmVerEstado(ACX->"+CTOO(ACX,"C")+;
                                        ",ST1->"+CTOO(ST1,"C")+;
                                        ",ST2->"+CTOO(ST2,"C")+")nResult="+CTOO(uResult,"C")+CRLF)
RETURN uResult


