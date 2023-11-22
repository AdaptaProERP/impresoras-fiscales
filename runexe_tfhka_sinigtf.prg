// Programa   : RUNEXE_TFHKA_SINIGTF
// Fecha/Hora : 00/00/0000 00:00:00
// Propósito  : Solo emision de un ticket de venta fiscal para impresora HKA-80
// Creado Por : 	
// Llamado por: IntTFHKA.EXE
// Aplicación : VENTAS Y CTAS X COBRAR
// Tabla      : DPMOVINV,DPCLIENTES,DPDOCCLI
// Fecha/Hora : 00/00/0000 00:00:00

#INCLUDE "DPXBASE.CH"
#INCLUDE "FILEIO.CH"

PROCE MAIN(cNumero,cTipDoc,nPagado,dFecha,cHora,cClicero,cRifcero)
   LOCAL cFile:="C:\INTTFHKA\DPTICKET.TXT",oTable,cNomVald,cCant,cPrecio,cTasa,nDesc:=0,nDescT,cMemo:="",cPagado,cUS,nDocOtr:=0,nDocDcto:=0
   LOCAL cEnlace:="",cEnlaceErr,cDesc,cDescT,cDescri,cDescriV:="",nHandler,cPrec,cDescu,nPrecio,nPreTotal:=0,cNombre,cRIF,cDireccion,cTelefono
   LOCAL cNumSer:="",cFecha:="",I,cAuxSerial,cHorad:="",iFecha:=""
   LOCAL cSerialFis, cFacAsocia, cSerialFec, cFacAsMovim
   LOCAL cFilex,cNada:=0
   LOCAL cCero:=0,cDivMenor:=0,nDivisa:=0
   LOCAL cRun,cDir:="C:\IntTFHKA\",cSerie,cMemoLog:=""
   LOCAL cFileLog:=cDir+"STATUS_ERROR.TXT",cResp,cWhere

   DEFAULT cClicero:="",cRifcero:="",cTipDoc:="FAV" 

   DEFAULT cTipDoc:="TIK",;
           cNumero:=SQLGETMAX("DPDOCCLI","DOC_NUMERO","DOC_TIPDOC"+GetWhere("=",cTipDoc))

   cWhere:="DOC_CODSUC"+GetWhere("=",cCodSuc)+" AND "+;
           "DOC_TIPDOC"+GetWhere("=",cTipDoc)+" AND "+;
           "DOC_NUMERO"+GetWhere("=",cNumero)+" AND "+;
           "DOC_ACT"   +GetWhere("=",1      )+" AND "+;
           "DOC_TIPTRA"+GetWhere("=","D"    )

   IF Empty(oDp:cImpFisCom)
      cSerie        :=SQLGET("DPDOCCLI","DOC_SERFIS",cWhere)
      oDp:cImpFisCom:=SQLGET("DPSERIEFISCAL","SFI_PUERTO","SFI_LETRA"+GetWhere("=",cSerie))
   ENDIF

   IF Empty(oDp:cImpFisCom)
      MsgMemo("No tiene Puerto Serial")
   ENDIF

   IF !EJECUTAR("RUNEXE_TFHKA_STATUS",cSerie) 
      RETURN .F.
   ENDIF

   cWhere:="DOC_CODSUC"+GetWhere("=",oDp:cSucursal)+" AND "+;
           "DOC_TIPDOC"+GetWhere("=",cTipDoc      )+" AND "+;
           "DOC_NUMERO"+GetWhere("=",cNumero      )+" AND "+;
           "DOC_TIPTRA"+GetWhere("=","D"          )

/*
   nDivisa  :=EJECUTAR("DPDOCCLIPAGDIV",cCodSuc,cTipDoc,cNumero)
   nPagado  :=oDp:nPagoBs // Pago en Bs
   nPagoIGTF:=oDp:nPagIGTF

? nPagado,"nPagado"

   nDivisa  :=0
*/


   oTable:=OpenTable(" SELECT  MOV_CODIGO,INV_DESCRI,MOV_TOTAL,DOC_OTROS,DOC_DCTO,MOV_PRECIO,MOV_DESCUE,MOV_CANTID,MOV_IVA,CCG_NOMBRE,CCG_RIF,CLI_NOMBRE,CLI_RIF,CLI_TEL1,CLI_DIR1"+;
                     " FROM DPMOVINV "+;
                     " INNER JOIN DPINV ON MOV_CODIGO=INV_CODIGO"+;
			       " INNER JOIN DPDOCCLI ON MOV_CODSUC=DOC_CODSUC AND MOV_TIPDOC=DOC_TIPDOC AND DOC_NUMERO=MOV_DOCUME AND DOC_TIPTRA='D'"+;
			       " LEFT  JOIN DPCLIENTESCERO ON CCG_CODSUC=DOC_CODSUC AND CCG_TIPDOC=DOC_TIPDOC AND CCG_NUMDOC=DOC_NUMERO "+;
                     " INNER JOIN DPCLIENTES ON MOV_CODCTA=CLI_CODIGO "+;
                     " WHERE  MOV_CODSUC"+GetWhere("=",oDp:cSucursal)+;
                     "   AND  MOV_TIPDOC"+GetWhere("=",cTipDoc)+;
			       "   AND MOV_DOCUME"+GetWhere("=",cNumero ),.T.)


// nDivisa:=0.50   //oTable:DOC_DIVISA    
   nDivisa:=0   //oTable:DOC_DIVISA    
//? nDivisa

    cUS     :=oDp:cUsuario
    cNombre    :=PADR(IIF(!EMPTY(oTable:CLI_RIF),oTable:CLI_NOMBRE,oTable:CCG_NOMBRE),20)
    cRIF       :=PADR(IIF(!EMPTY(oTable:CLI_RIF),oTable:CLI_RIF,oTable:CCG_RIF),20)
    cDireccion :=PADR(IIF(!EMPTY(oTable:CLI_RIF),oTable:CLI_DIR1,oTable:CCG_DIR1),20)
    cTelefono  :=PADR(IIF(!EMPTY(oTable:CLI_RIF),oTable:CLI_TEL1,oTable:CCG_TEL1),20)


If cTipDoc = "DEV"

//      cSerialFis:=ALLTRIM(MYSQLGET("DPEQUIPOSPOS","EPV_IMPFIS","EPV_SERIEF='"+LEFT(oTable:DOC_NUMERO,1)+"'"))
     //?? cSerialFis, "Serial Impresora"
	 
   cEnlace:=cEnlace+"<TEXTO_CF,"+REPL("-",40)+",0>"+CRLF
   While !oTable:Eof()
    cCant    :=ALLTRIM(STR(oTable:MOV_CANTID*1000,8,0))
    nPrecio  :=(oTable:MOV_TOTAL/oTable:MOV_CANTID)*1.16
    cPrecio  :=ALLTRIM(STR(nPrecio*100,10,0))
    cTasa    :=AllTRIM(STR(IIF(oTable:MOV_IVA<>0,cTasa:=1,cTasa:=0)))
    cDescri  :=ALLTRIM(PADR(oTable:INV_DESCRI,20))
    oTable:DbSkip()
  EndDo 
  oTable:Gotop()
Else
//? "PASA POR FACTURA"
        cEnlace:=cEnlace+CHR(105)+CHR(83)+CHR(42)+"Nombre..: "+cNombre+CRLF
        cEnlace:=cEnlace+CHR(105)+CHR(82)+CHR(42)+"Rif/Cedula: "+cRIF+" Ref.: "+cNumero+CRLF
        cEnlace:=cEnlace+CHR(105)+CHR(82)+CHR(42)+"Direccion: "+cDireccion+CRLF
        cEnlace:=cEnlace+CHR(105)+CHR(82)+CHR(42)+"Telefono : "+cTelefono+" Cajero: "+cUS+CRLF
EndIf

   While !oTable:Eof()
// ? oTable:MOV_TOTAL
 	nPreTotal:=nPreTotal+oTable:MOV_TOTAL
	cCant    :=ALLTRIM(STR(oTable:MOV_CANTID*1000,8,0))
	nPrecio  :=(oTable:MOV_TOTAL/oTable:MOV_CANTID)*1.16
	cPrecio  :=ALLTRIM(STR(nPrecio*100,10,0))
	cTasa    :=AllTRIM(IIF(oTable:MOV_IVA<>0,cTasa:=CHR(33),cTasa:=CHR(32)))
	cDescri  :=ALLTRIM(PADR(oTable:INV_DESCRI+SPACE(40),40))
    	cEnlace:=cEnlace+cTasa+right("0000000000"+cPrecio,10)+right("00000000"+cCant,8)+cDescri+CRLF+""
  oTable:DbSkip()
  EndDo 
  oTable:Gotop()
// ? "SALE DE FACTURA"
//  cPagado  :=IIF(nPagado<>0,ALLTRIM(STR(nPreTotal*100,13,2)),0)
  If cTipDoc <> "DEV" 
     If nPagado<>0

        //? nDivisa

        cEnlace:=cEnlace+IIF( nPreTotal>0,"3","")+CRLF

//        cEnlace:=cEnlace+IIF( nDivisa < nPreTotal .AND. nDivisa > 0 , "22"+RIGHT( "0000000000000"+ALLTRIM( STR( oTable:DOC_DIVISA*100,13,0 ) ),13 ),"" )+IIF(nDivisa < nPreTotal .AND. nDivisa > 0,CRLF,ALLTRIM(SPACE(12)))
        cEnlace:=cEnlace+IIF( nDivisa < nPreTotal .AND. nDivisa > 0 , "22"+RIGHT( "0000000000000"+ALLTRIM( STR( 0.50*100,13,0 ) ),13 ),"" )+IIF(nDivisa < nPreTotal .AND. nDivisa > 0,CRLF)

//        cEnlace:=cEnlace+IIF( nDivisa < nPreTotal .AND. nDivisa > 0 , "101","" )+IIF(nDivisa < nPreTotal .AND. nDivisa > 0,CRLF,ALLTRIM(SPACE(12)))
        cEnlace:=cEnlace+IIF( nDivisa < nPreTotal .AND. nDivisa > 0 , "101","" )+IIF(nDivisa < nPreTotal .AND. nDivisa > 0,CRLF)

//        cEnlace:=cEnlace+IIF( nDivisa > 0 .AND. nDivisa < nPreTotal , "201"+RIGHT( "0000000000000"+ALLTRIM( STR( nPreTotal*100,13,0 ) ),13 ),"" )+CRLF
//        cEnlace:=cEnlace+IIF( nDivisa!=0,"120","" )+CRLF

        IF nDivisa>0
           cEnlace:=cEnlace+"199"+CRLF
        ENDIF

        IF nDivisa=0
           cEnlace:=cEnlace+"101"+CRLF
     //      cEnlace:=cEnlace+"199"+CRLF
        ENDIF

     ELSE

 //   ? "CIERRE FACTURA"
           cEnlace:=cEnlace+"101"+CRLF
           cEnlace:=cEnlace+"199"+CRLF

   	   //cEnlace:=cEnlace+"110"+CRLF
     EndIf
  EndIf

  FERASE(cFile)
  DPWRITE(cFile,cEnlace)

  cRun:="CD\INTTFHKA "+CRLF+;
        "IntTFHKA.EXE SendFileCmd(DPTICKET.TXT) > STATUS_ERROR.TXT "

  DPWRITE("RUN_TFHKA.BAT",cRun)
  CURSORWAIT()

  ferase(cFileLog)

  MsgRun("Imprimiendo Ticket No.:"+cNumero,"Por Favor Espere",{||WAITRUN("RUN_TFHKA.BAT",0)  })

  cMemoLog:=ALLTRIM(MemoRead(cFileLog))
  cResp   :=ALLTRIM(RIGHT(cMemoLog,2))

  IF cResp="0" 
     SQLUPDATE("DPDOCCLI","DOC_IMPRES",.T.,cWhere)
  ELSE
     MsgMemo(cMemoLog,"Error de Impresión "+cNumero)
  ENDIF
  
RETURN .F.
//::::::::
