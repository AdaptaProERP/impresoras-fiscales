// Programa   : DLL_BEMATECH
// Fecha/Hora : 10/02/2023
// Propósito  : Impresora BEMATECH
// Creado Por : Kelvis Escalante/Juan Navas
// Llamado por: DLL_IMPFISCAL       
// Aplicación : Facturación
// Tabla      : DPDOCCLI/DPMOVINV
// Alicuota = 16.00 G
// Alicuota =  8.00 R 
// Alicuota = 00.00 E
// Alicuota =  0.01 P
// Alicuota = 31.00 A


#INCLUDE "DPXBASE.CH"

PROCE MAIN(cCodSuc,cTipDoc,cNumero,lMsgErr,lShow,lBrowse,cCmd)
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
  LOCAL nDivisa:=0,lResp
  //LOCAL error:=.F.

  PRIVATE aTipoPago:={}

  DEFAULT cCodSuc:=oDp:cSucursal,;
          cTipDoc:="FAV",;
          cNumero:=SQLGETMAX("DPDOCCLI","DOC_NUMERO","DOC_CODSUC"+GetWhere("=",cCodSuc)+" AND DOC_TIPDOC"+GetWhere("=",cTipDoc)+" AND DOC_TIPTRA"+GetWhere("=","D"))

  DEFAULT lMsgErr:=.T.,;
          lShow  :=.T.,;
          lBrowse:=.T.,;
          oDp:lImpFisModVal:=.T.,;
          oDp:lImpFisRegAud:=.T.,;
          oDp:cImpFisCom   :="BEMATECH",;
          cCmd             :=""

  cWhere:="DOC_CODSUC"+GetWhere("=",cCodSuc)+" AND "+;
          "DOC_TIPDOC"+GetWhere("=",cTipDoc)+" AND "+;
          "DOC_NUMERO"+GetWhere("=",cNumero)+" AND "+;
          "DOC_TIPTRA"+GetWhere("=","D"    )

  IF lShow
     AEVAL(DIRECTORY("TEMP\*.ERR"),{|a,n| FERASE("TEMP\"+a[1])})
  ENDIF


  lVenta:=(cTipDoc="FAV" .OR. cTipDoc="TIK")

  ////////////////////INICIO/////////////////////////////////////

  IF !TYPE("oBema")="O"
    TDpClass():New(NIL,"oBema")
  ENDIF

  oBema:hDll    :=NIL
  oBema:cFileIni:=GetWinDir()+"\System32\BemaFI32.INI"
  oBema:cName   :="BEMATECH"
  oBema:cFileDll:="BemaFI32.dll"
  oBema:cEstatus:=""
  oBema:oFile   :=NIL
  oBema:lMsgErr :=lMsgErr
  oBema:lErr    :=.F. // no genera ninguna Incidencia
  oBema:cFileLog:="TEMP\"+cTipDoc+ALLTRIM(cNumero)+"_"+LSTR(SECONDS())+".LOG"
  oBema:lShow   :=lShow
  oBema:cError  :=""
  oBema:lDemo   :=.T.
  oBema:nRet    :=0
  oBema:lError  :=.F.
  oBema:lImpErr :=.F.
  oBema:cTipDoc :=cTipDoc
  oBema:cNumero :=cNumero

  // FUNCTION BmVerEstado(ACX ,ST1,ST2 )
  oBema:ACX     :=NIL
  oBema:ST1     :=NIL
  oBema:ST2     :=NIL

  IF !FILE(oBema:cFileIni)
     COPY FILE ("BemaFI32.INI") TO (oBema:cFileIni)
  ENDIF

  cFileLog:=oBema:cFileLog

  ferase(cFileLog)

  IF FILE(cFileLog) .AND. ValType(oBema:oMemo)="O"
    oBema:MsgErr("Archivo "+cFileLog+" está abierto",oBema:oMemo)
     // oBema:oSay:Append("Archivo "+cFileLog+" está abierto")
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

     oBema:cFileLog:="TEMP\bematech_"+cCmd+".LOG"
     oBema:oFile   :=TFile():New(oBema:cFileLog)

     cError:=BEMA_INI()
     lResp :=NIL

     IF Empty(cError) .AND. "Z"$cCmd
       lResp:=BEMA_ZETA()
     ENDIF

     IF Empty(cError) .AND. "FAV"$cCmd
       lResp:=BEMA_FAV()
     ENDIF

     IF Empty(cError) .AND. "CRE"$cCmd
       lResp:=BEMA_CRE()
     ENDIF

     IF Empty(cError) .AND. "TOTAL"$cCmd
       lResp:=BEMA_TOTAL()
     ENDIF

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


  nDivisa  :=EJECUTAR("DPDOCCLIPAGDIV",cCodSuc,cTipDoc,cNumero)

  cSql:=" SELECT  MOV_DOCUME,DOC_FACAFE,DOC_IMPRES,MOV_CODIGO,INV_DESCRI,MOV_TOTAL,DOC_OTROS,DOC_DCTO,DOC_TIPDOC,MOV_PRECIO,MOV_DESCUE,MOV_CANTID,MOV_IVA,MOV_CODALM,"+;
        " DOC_NUMERO,CLI_NOMBRE,CLI_RIF,CLI_DIR1,CLI_TEL1,"+;
        " IF(DOC_CODIGO"+GetWhere("=","0000000000")+",DPCLIENTESCERO.CCG_RIF   ,DPCLIENTES.CLI_RIF   ) AS  CLI_RIF    ,"+;
        " IF(DOC_CODIGO"+GetWhere("=","0000000000")+",DPCLIENTESCERO.CCG_NOMBRE,DPCLIENTES.CLI_NOMBRE) AS  CLI_NOMBRE ,"+;
        " IF(DOC_CODIGO"+GetWhere("=","0000000000")+",DPCLIENTESCERO.CCG_DIR1  ,DPCLIENTES.CLI_DIR1  ) AS  CLI_DIR1   ,"+;
        " IF(DOC_CODIGO"+GetWhere("=","0000000000")+",DPCLIENTESCERO.CCG_TEL1  ,DPCLIENTES.CLI_TEL1  ) AS  CLI_TEL1   ,"+;
        " SFI_SERIMP,SFI_MEMO"+;
        " FROM DPMOVINV "+;
        " INNER JOIN DPINV ON MOV_CODIGO=INV_CODIGO "+;
        " INNER JOIN DPDOCCLI       ON MOV_CODSUC=DOC_CODSUC AND MOV_TIPDOC=DOC_TIPDOC AND DOC_NUMERO=MOV_DOCUME AND DOC_TIPTRA='D'"+;
        " LEFT  JOIN DPSERIEFISCAL  ON DOC_SERFIS=SFI_LETRA  "+;
        " LEFT  JOIN DPCLIENTES     ON DOC_CODIGO=CLI_CODIGO "+;
        " LEFT  JOIN DPCLIENTESCERO ON CCG_CODSUC=DOC_CODSUC AND CCG_TIPDOC=DOC_TIPDOC AND CCG_NUMDOC=DOC_NUMERO "+;
        " LEFT  JOIN DPPRECIOTIP    ON MOV_LISTA=TPP_CODIGO "+;
        " WHERE MOV_CODSUC"+GetWhere("=",cCodSuc)+;
        " AND   MOV_TIPDOC"+GetWhere("=",cTipDoc)+;
        " AND   MOV_DOCUME"+GetWhere("=",cNumero)+;
        " AND   MOV_INVACT=1 "+;
        " GROUP BY MOV_ITEM "+;
        " ORDER BY MOV_ITEM " 

  oTable:=OpenTable(cSql,.T.)
  oBema:cSql    :=cSql

  aMemo:=_VECTOR(STRTRAN(oTable:SFI_MEMO,CRLF,CHR(10)),CHR(10))

  // Valida si fue impreso
  IF oTable:DOC_IMPRES

     oBema:cError:="Documento fué Impreso"
     oBema:oFile:AppStr(oBema:cError+CRLF)

     IF !oDp:lImpFisModVal
       oTable:End()
       BEMA_END()
       BEMA_CLOSE()
       RETURN .F.
     ENDIF

  ENDIF
  
  // 
  // cMensaje1:=oTable:SFI_COMEN1
  // cMensaje2:=oTable:SFI_COMEN2
  // cMensaje3:=oTable:SFI_COMEN3
  // cError:=BEMA_INI()
/*
  IF !Empty(cError)

    IF oDp:lImpFisModVal

      oBema:oFile:AppStr("Error Inicializando Bematech"+CRLF)

    ELSE

      MensajeErr("Error Inicializando Bematech")
      BEMA_CLOSE()
      RETURN .F.

     ENDIF

  ENDIF
*/
  //cError:IFESTATUS()
  //nPreTotal:= ALLTRIM(STRTRAN(TRAN(oTable:MOV_TOTAL,"999999999999.99"),".",""))

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

  WHILE !oTable:Eof()

    cCodigo  := oTable:MOV_CODIGO
    cDescr   := oTable:INV_DESCRI  
    cAlicuota:= AllTRIM(STR(oTable:MOV_IVA,6,2))
    cIva     := StrTran(cAlicuota,".","")
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
 
   //MONTO EN DIVISA 1$ - cVALOR = Valor del dolar 
   // cMtoDivisa:=1
   // cPagoDolar:=STRZERO((cMtoDivisa*cVALOR/1)*100,14)

   IF nDivisa>0
     cPagoDolar:=LSTR(nDivisa,14,2) //  STRZERO(nDivisa*100,14)
     // cPagoDolar:=STRTRAN(cPagoDolar,",", ".")
     nRet:=BmIniFecCupIGTF(cPagoDolar)    
   ELSE
     nRet:=BmIniFecCupIGTF("0")    
   ENDIF

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
  AEVAL(DIRECTORY("TEMP\*.ERR"),{|a,n,cLine| cLine:=MEMOREAD("TEMP\"+a[1]),MsgMemo(cLine),cMemo:=cMemo+cLine+CRLF})

  IF !Empty(cMemo)
    oBema:oFile:AppStr(cMemo+CRLF)
  ENDIF

  oBema:oFile:Close()

  IF oBema:lShow

    DEFINE FONT oFont     NAME "Courier"   SIZE 0, -10

    VIEWRTF(oBema:cFileLog,"Archivo "+oBema:cFileLog,oFont)

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


////////////////////////////
// FUNCIONES BEMATECH.DLL //

FUNCTION BmAbreCupom(cCupom)
  LOCAL cFarProc:= NIL
  LOCAL uResult := NIL

  IF !oDp:lImpFisModVal
    cFarProc:= GetProcAddress( oDp:nBemaDLL, If( Empty( "Bematech_FI_AbreCupom" ) == .T., "BmAbreCupom", "Bematech_FI_AbreCupom" ), .T., 7,9 )
    uResult := CallDLL( cFarProc,cCupom)
  ENDIF

  oBema:oFile:AppStr("BmAbreCupom(cCupom),cCupom->"+CTOO(cCupom,"C")+CRLF+",nResult= "+CTOO(uResult,"C")+CRLF)

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

FUNCTION BmIniFecCupIGTF( cPagoDolar )
 LOCAL cFarProc:= NIL
 LOCAL uResult := NIL
 LOCAL cFunc   :="Bematech_FI_IniciaCierreCuponIGTF"

 IF !oDp:lImpFisModVal
    cFarProc:= GetProcAddress( oDp:nBemaDLL,cFunc, .T., 7,8 )
    uResult := CallDLL( cFarProc,cPagoDolar )
 ENDIF

 oBema:oFile:AppStr("BmIniFecCupIGTF( cPagoDolar )"+CRLF+;
                     "cPagoDolar->"   +CTOO(cPagoDolar,"C")+","+CRLF+;
                     "nResult="       +CTOO(uResult   ,"C")+CRLF)

RETURN uResult

FUNCTION BmIniFecCup( Acrescimo,TipAcresc,ValAcresc )
 LOCAL cFarProc:= NIL
 LOCAL uResult := NIL

 IF !oDp:lImpFisModVal
    cFarProc:= GetProcAddress( oDp:nBemaDLL, If( Empty( "Bematech_FI_IniciaCierreCupon" ) == .T., "BmIniFecCup", "Bematech_FI_IniciaCierreCupon" ), .T., 7,8,8,8 )
    uResult := CallDLL( cFarProc,Acrescimo,TipAcresc,ValAcresc )
 ENDIF

 oBema:oFile:AppStr("BmIniFecCup( Acrescimo,TipAcresc,ValAcresc )"+CRLF+;
                    "Acrescimo->"+CTOO(Acrescimo,"C")+","+CRLF+;
                    "TipAcresc->"+CTOO(TipAcresc,"C")+","+CRLF+;
                    "ValAcresc->"+CTOO(ValAcresc,"C")+","+CRLF+;
                    "nResult="   +CTOO(uResult  ,"C")+CRLF)

RETURN uResult

FUNCTION BmFormasPag( FormaPgto,ValorPago )
  LOCAL cFarProc:= NIL
  LOCAL uResult := NIL
  LOCAL cFunc   :="Bematech_FI_EfectuaFormaPago"

  IF !oDp:lImpFisModVal
     cFarProc:= GetProcAddress( oDp:nBemaDLL, cFunc, .T., 7,8,8 )
     uResult := CallDLL( cFarProc,FormaPgto,ValorPago )
  ENDIF

  oBema:oFile:AppStr("BmFormasPag( FormaPgto,ValorPago )"+CRLF+;
                     "FormaPgto->"   +CTOO(FormaPgto,"C")+","+CRLF+;
                     "ValorPago->"   +CTOO(ValorPago,"C")+","+CRLF+;
                     "nResult="      +CTOO(uResult  ,"C")+CRLF)

RETURN uResult

FUNCTION BmTerFecCup( Mensagem )
  LOCAL cFarProc:= NIL
  LOCAL uResult := NIL
  LOCAL cFunc   :="Bematech_FI_FinalizarCierreCupon"

  IF !oDp:lImpFisModVal
     cFarProc:= GetProcAddress( oDp:nBemaDLL,Func, .T., 7,8 )
     uResult := CallDLL( cFarProc,Mensagem )
  ENDIF

  oBema:oFile:AppStr("BmTerFecCup( Mensagem ), FUNCTION "+cFunc+"(),"+CRLF+;
                    "Mensagem ->"   +CTOO(Mensagem ,"C")+","+CRLF+;
                    "nResult="      +CTOO(uResult  ,"C")+CRLF)

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

    cError:=EJECUTAR("DLL_BEMATECH_CHECK")

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
 nRet:=BmSimboloMoneda("Bs")
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

  IF oBema:lShow

    DEFINE FONT oFont     NAME "Courier"   SIZE 0, -10

    VIEWRTF(oBema:cFileLog,"Archivo "+oBema:cFileLog,oFont)

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
// Ejecuta funciones Bematecha, ahorra uso innecesario de funciones
*/
FUNCTION BMRUNFUNCION(cFunc,cName)
  LOCAL uResult :=NIL
  LOCAL cFarProc:=NIL

  DEFAULT cName:=""

  IF !oDp:lImpFisModVal
    cFarProc:= GetProcAddress(oDp:nBemaDLL,cFunc,.T.,7 ) 
    uResult := CallDLL(cFarProc ) 
  ENDIF

  IF ValType(oBema:oFile)="O"
     oBema:oFile:AppStr(cName+","+cFunc+",Result->"+CTOO(uResult,"C")+CRLF)
  ENDIF

RETURN uResult

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



// ADICIONALES

//IF PADR(TIK_IVA,5) = "0.00" AND TIK_CONTRI ="S"
//cAlicuota = "II"
//ENDIF 
   
//////////////////////////////////////////    
// Entero o "F" fraccionado
// Siempre va a ser una "F"
//cTipCant:=IIF(nCant=INT(nCant),"I","F")
//IF cTipCant="F"
//   cCantid :=STR(nCant,7,3)
//ELSE
//   cCantid :=STR(nCant,4,0)
//ENDIF
//cCantid :=StrTran(cCantid,".","")
///////////////////////////////////////////

//////////////////////////////////////////////////////////
//IF cTipDesc="%"
//   cValDesc:=STRZERO(nDesc*100,4) // STR(nDesc*100,4,0)
//ELSE
//   cValDesc:=STRZERO(nDesc*100,8)
//ENDIF
//////////////////////////////////////////////////////////
// EOF
//
