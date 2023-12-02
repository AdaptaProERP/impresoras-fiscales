// Programa   : DLL_TFHKA
// Fecha/Hora : 31/07/2022 00:00:00
// Propósito  : LLamadas TFHKA DLL
// Creado Por :
// Llamado por:DLL_IMPFISCAL
// Aplicación :
// Tabla      :

#INCLUDE "DPXBASE.CH"

PROCE MAIN(cCodSuc,cTipDoc,cNumero,lMsgErr,lShow,lBrowse)
  LOCAL oTable,cNombre,cRif, cDir1, cDir2:="", cTel1:="",cAlicuota:="", cMemo:="",lRet:=.T.
  LOCAL cAuxSerial,status, error:=.F., lDevolu
  LOCAL cDescDev1:="", cDescDev2:="", cDescDev3:="", cNumSer:="",cNumAsoc:="",cFechAso:="",cHorAso:="",cSql
  LOCAL cTasaAsc
  LOCAL cFile:="dpticket.txt",oTable,cNomVald,cCant,cPrecio,cTasa,nDesc:=0,nDescT,cMemo:="",cPagado,cUS,nDocOtr:=0,nDocDcto:=0
  LOCAL cTicket:="",cTicketErr,cDesc,cDescT,cDescri,cDescriV:="",nHandler,cPrec,cDescu,nPrecio,nPreTotal:=0,cNombre,cRIF,cNUNFAC,cTel1,cDir1,cAlicuota,cMAQUI
  LOCAL cFileLog:=""
  LOCAL oSerFis :=NIL
  LOCAL lDemo   :=(cTipDoc=NIL)
  Local lStatus,lError
  LOCAL lRespuesta,lRespuesta2

  PRIVATE aTipoPago:={}

  IF !TYPE("oTFHKA")="O"
     TDpClass():New(NIL,"oTFHKA")
     EJECUTAR("DLL_TFHKA_DOWNLOAD") // Valida y descarga tfhkaif.dll
  ENDIF

  oTFHKA:hDll    :=NIL
  oTFHKA:cName   :="TFHKA"
  oTFHKA:cFileDll:="tfhkaif.dll"
  oTFHKA:cEstatus:=""
  oTFHKA:oFile   :=NIL

  cFileLog:="TEMP\"+cTicket+"LOG"

  IF !FILE(oTFHKA:cFileDll)
    MsgMemo("No se Encuenta Archivo "+oTFHKA:cFileDll)
    RETURN NIL
  ENDIF

  oTFHKA:oFile:=TFile():New(cFileLog)

  oTFHKA:hDll    := LoadLibrary(oTFHKA:cFileDll)
  oTFHKA:cPort   :="COM4" // Valor por Defecto

  IF !(Abs(oTFHKA:hDLL) > 32)
     MensajeErr("Error Leyendo Libreria "+oTFHKA:cFileDll)
     oTFHKA:IFCERRARDLL()
     RETURN NIL
  ENDIF

  MSGALERT(oTFHKA:hDll,"LEE EL DLL: ")

  DEFAULT cTicket:=ALLTRIM(STR(cTicket)),;
          cTipDoc:="TIK"

  cTicket:=cNumero 
  Integer=""
  lRespuesta=0
  lRespuesta2=0

  //cResp:=oTFHKA:PFRUNCMD("CheckFprinter","")
  //MSGALERT(cResp,"IMPRESORA NO ESTA CONECTADA AL PC: ")

  //cResp:=oTFHKA:PFRUNCMD("ReadFpStatus",@lStatus,@lError)
  //MSGALERT(cResp,"ESTATUS DE LA IMPRESORA: ")

  oTFHKA:IFOPEN()

/*
  IF !oTFHKA:IFOPEN()
      oTable:END()
     ? "PUERTO COMx NO PUEDE ABRIR"
      oTFHKA:IFCLOSE()
      RETURN NIL
  ENDIF
*/

//oTFHKA:IFREPORTEX()
//oTFHKA:IFREPORTEZ()


   oTable:=OpenTable(" SELECT  MOV_CODIGO,INV_DESCRI,MOV_TOTAL,DOC_OTROS,DOC_DCTO,MOV_PRECIO,MOV_DESCUE,MOV_CANTID,MOV_IVA,CCG_NOMBRE,CCG_RIF,CCG_DIR1,CCG_TEL1"+;
			   " FROM DPMOVINV INNER JOIN DPINV ON MOV_CODIGO=INV_CODIGO"+;
			   " INNER  JOIN DPDOCCLI ON MOV_CODSUC=DOC_CODSUC AND MOV_TIPDOC=DOC_TIPDOC AND DOC_NUMERO=MOV_DOCUME AND DOC_TIPTRA='D'"+;
			   " LEFT   JOIN DPCLIENTESCERO ON CCG_CODSUC=DOC_CODSUC AND CCG_TIPDOC=DOC_TIPDOC AND CCG_NUMDOC=DOC_NUMERO "+;
			   " WHERE MOV_TIPDOC"+GetWhere("=",oPos:cTipDoc)+;
			   " AND   MOV_USUARI"+GetWhere("=",oDp:cUsuario)+;
			   " AND   MOV_DOCUME"+GetWhere("=",oPos:DOC_NUMERO),.T.)

  IF oTable:RecCount()=0 
     ? " Número "+oPos:DOC_NUMERO+" no Existe"
     oTFHKA:IFCLOSE()
     RETURN .F.
  ENDIF
 
//  oTable:Browse()
//  oTFHKA:IFESTATUS()

  cMAQUI:=ALLTRIM(PADR(MYSQLGET("DPEQUIPOSPOS","EPV_IMPFIS","EPV_SERIEF"=oTable:DOC_SERFIS),10))
 
  oTable:CCG_NOMBRE:= ALLTRIM(PADR(oTable:CCG_NOMBRE,35))
  oTable:CCG_RIF   := ALLTRIM(PADR(oTable:CCG_RIF,12))
  oTable:CCG_DIR1  := ALLTRIM(PADR(oTable:CCG_DIR1,15))
  oTable:CCG_TEL1  := ALLTRIM(PADR(oTable:CCG_TEL1,12))
  oTable:DOC_NUMERO:= ALLTRIM(PADR(oTable:DOC_NUMERO,10))

// ? cMAQUI
// ? oTable:CCG_NOMBRE

  oTFHKA:IFABREFISCAL()

// oTFHKA:IFIMPRESO()

  oTable:Gotop()

  WHILE !oTable:Eof()

    IF oTable:Eof()
       EXIT
    ENDIF

    //oTFHKA:IFRENGLON() 
    cAlicuota:=STRZERO(oTable:MOV_IVA*100,4)
    //cTasa    :=IIF(oTable:MOV_IVA>0,cTasa:=CHR(33),cTasa:=CHR(32))
    cPrecio  :=ALLTRIM(TRANSFORM(oTable:MOV_PRECIO,"999999999.99"))
    cCant    :=ALLTRIM(TRANSFORM(oTable:MOV_CANTID,"999999.999"))
    cDescri  :=PADR(oTable:INV_DESCRI,20)

    //la impresora interpreta la tasa con caracteres ascii chr(33) = !
    cTasaAsc:=IIF(cAlicuota=16,CHR(33),IIF(cAlicuota=0,CHR(32),IIF(cAlicuota=7.00,CHR(35),IIF(cAlicuota=0,CHR(32),CHR(32) ))))

    lCadena = cTasaAsc+right("0000000000"+alltrim(str(oTable:MOV_PRECIO*100,12,0)),10)+right("00000000"+ alltrim( str(oTable:MOV_CANTID*1000,8,0)),8)+LEFT(oTable:INV_DESCRI+SPACE(40),40)+CHR(13)+CHR(10)
    cResp:=oTFHKA:PFRUNCMD("sendcmd",lStatus,lError,lCadena)
    MSGALERT(lError,"error ITEM     : ")
    //MSGALERT(cResp,"REVISA LA FUNCION SENDCMD:")

    oTable:DbSkip()

    SysRefresh(.T.)

  ENDDO

  oTable:End()

  oTFHKA:IFPRINT()
  oTFHKA:IFCLOSE()

  SysRefresh(.T.)

RETURN .T.

//////////////////////////////////////
//////////// FUNCIONES////////////////
//////////////////////////////////////
FUNCTION IFOPEN()
  LOCAL cResp

  lRespuesta=oTFHKA:PFRUNCMD("OpenFpCtrl","COM4")

  IF lRespuesta#1
     lRespuesta=oTFHKA:IFCLOSE()
     lRespuesta2=oTFHKA:PFRUNCMD("OpenFpCtrl","COM4")
     IF lRespuesta2#1
  	   MSGALERT("No se pudo abrir el puerto.",16,"Error") 		
        RETURN NIL
     ENDIF
  ENDIF
MSGALERT("EL PUERTO ESTA ABIERTO") 		
RETURN .T.

FUNCTION IFABREFISCAL()
  LOCAL cResp
  LOCAL lResp,edlinea1,edlinea2,edlinea3,edlinea4 
  LOCAL lCadena, lError, lStatus, lResult, lFactura,
  LOCAL lPrecio, lCantidad, lDescrip, lResult, lPorcen,lRifcliente
  LOCAL lStatus,lError,lCadena

  lStatus:=0
  lError :=0
  lCadena:=""
    
 IF oTable:DOC_TIPDOC = "TIK" .OR. oTable:DOC_TIPDOC="FAV"
    //i=CHR(105)    //0=CHR(48)    //*=CHR(42)  
    ///×××××××××××××××××××××××××××××××××××××××××××××××××××××××××××××××××××××××//
    //iF*1000 //iD*29-08-2022 //iS*JUAN //iR*V2 //i00TIPO: CREDITO //i00Telf: 04
    //i00DIR CARACAS //i00CAJERO KELVIS //i00REF 00P1C16XLGGW
    //!000000000000043000000000000001000ABCDEFGHIJKLMNÑOPQST
    //101
    //××××××××××××××××××××××××××××××××××××××××××××××××××××××××××××××××××××××××//
 	lCadena = CHR(105)+CHR(70)+CHR(42) + "Nro. Factura: " + oTable:DOC_NUMERO
     cResp:=oTFHKA:PFRUNCMD("sendcmd",@lStatus,@lError,lCadena)
     MSGALERT(cResp,"Abre ticket : ")
     MSGALERT(lStatus,"estatus   : ")
     MSGALERT(lError,"error      : ")
     // IFERROR(lError) ------ Despues crear una funcion para buscar el error------

 	lCadena = CHR(105)+CHR(68)+CHR(42) + "Fecha: " + oTable:DOC_FECHA
     cResp:=oTFHKA:PFRUNCMD("sendcmd",@lStatus,@lError,lCadena)
     MSGALERT(lError,"error      : ")

 	lCadena = CHR(105)+CHR(83)+CHR(42) + "Nombre : " + oTable:CCG_NOMBRE 
     cResp:=oTFHKA:PFRUNCMD("sendcmd",@lStatus,@lError,lCadena)
     MSGALERT(lError,"error      : ")

 	lCadena = CHR(105)+CHR(82)+CHR(42) + "Rif/Cedula : " + oTable:CCG_RIF 
     cResp:=oTFHKA:PFRUNCMD("sendCmd",@lStatus,@lError,lCadena)
     MSGALERT(lError,"error      : ")

 	lCadena = CHR(105)+CHR(48)+CHR(48) + "Telefono : " + oTable:CCG_TEL1 
     cResp:=oTFHKA:PFRUNCMD("sendCmd",@lStatus,@lError,lCadena)
     MSGALERT(lError,"error      : ")

 	lCadena = CHR(105)+CHR(48)+CHR(48) + "Direccion : " + oTable:CCG_DIR1 
     cResp:=oTFHKA:PFRUNCMD("sendCmd",@lStatus,@lError,lCadena)
     MSGALERT(lError,"error      : ")

 ENDIF
 //
 IF oTable:DOC_TIPDOC = "DEV" .OR.  oTable:DOC_TIPDOC = "CRE"
     //×××××××××××××××××××××××××××××××××××××××××××××××××××××××××××××××××××××××××××××××××××××××××//
     //iR*12345678  //iS*JUAN //iF*00000000001 //iD*30-09-2022 //iI*S0010101011 //i00"COMENTARIOS" 
     //    precio=17        cantidad=16 
     //!000000000000043000000000000001000ABCDEFGHIJKLMNÑOPQST
     //101
     //×××××××××××××××××××××××××××××××××××××××××××××××××××××××××××××××××××××××××××××××××××××××××//
 	lCadena = CHR(105)+CHR(82)+CHR(42) + "Rif/Cedula : " + oTable:CCG_RIF 
     cResp:=oTFHKA:PFRUNCMD("sendCmd",@lStatus,@lError,lCadena)
     MSGALERT(lError,"error      : ")

 	lCadena = CHR(105)+CHR(83)+CHR(42) + "Nombre : " + oTable:CCG_NOMBRE 
     cResp:=oTFHKA:PFRUNCMD("sendcmd",@lStatus,@lError,lCadena)
     MSGALERT(lError,"error      : ")

 	lCadena = CHR(105)+CHR(70)+CHR(42) + "Nro. Factura: " + oTable:DOC_NUMERO
     cResp:=oTFHKA:PFRUNCMD("sendcmd",@lStatus,@lError,lCadena)
     MSGALERT(lError,"error      : ")

 	lCadena = CHR(105)+CHR(68)+CHR(42) + "Fecha: " + oTable:DOC_FECHA
     cResp:=oTFHKA:PFRUNCMD("sendcmd",@lStatus,@lError,lCadena)
     MSGALERT(lError,"error      : ")

 	lCadena = CHR(105)+CHR(73)+CHR(42) + "Serial Fiscal: " + "aqui el serial" 
     cResp:=oTFHKA:PFRUNCMD("sendCmd",@lStatus,@lError,lCadena)
     MSGALERT(lError,"error      : ")

 	lCadena = CHR(105)+CHR(48)+CHR(48) + "Escribir comentario " 
     cResp:=oTFHKA:PFRUNCMD("sendCmd",@lStatus,@lError,lCadena)
     MSGALERT(lError,"error      : ")

 ENDIF

RETURN .T.


FUNCTION IFRENGLON()   

  LOCAL cResp,cTasaAsc
  LOCAL lStatus,lError,lCadena

  lStatus:=0
  lError :=0
  lCadena:=""

  cAlicuota:=STRZERO(oTable:MOV_IVA*100,4)
  cTasaAsc:=IIF(cAlicuota=16,CHR(33),IIF(cAlicuota=0,CHR(32),IIF(cAlicuota=7.00,CHR(35),IIF(cAlicuota=0,CHR(32),CHR(32) ))))
  lCadena = cTasaAsc+right("000000000000"+alltrim(str(oTable:MOV_PRECIO*100,14,0)),10)+right("00000000"+ alltrim( str(oTable:MOV_CANTID*1000,8,0)),8)+LEFT(oTable:INV_DESCRI+SPACE(40),40)
  cResp:=oTFHKA:PFRUNCMD("sendcmd",@lStatus,@lError,lCadena)
  MSGALERT(lError,"error en item      : ")

RETURN lResp


FUNCTION IFESTATUS()
  LOCAL cEstatus,lStatus
  //cEstatus:=oTFHKA:PFRUNCMD("status",""),""
  //oTFHKA:cEstatus:=""

   IF lStatus = 0
      //oTFHKA:cEstatus:="Puerto no Abierto"
      ? "Estado desconocido"
   ENDIF
   IF lStatus = 1
      ? "En modo prueba y en espera"
   ENDIF

   IF lStatus = 2
      ? "En modo prueba y emisión de documentos fiscales"
   ENDIF

   IF lStatus = 3
      ? "En modo prueba y emisión de documentos no fiscales"
   ENDIF

   IF lStatus = 4
      ? "En modo fiscal y en espera"
   ENDIF

   IF lStatus = 5
      ? "5 En modo fiscal y emisión de documentos fiscales"
   ENDIF

   IF lStatus = 6
      ? "En modo fiscal y emisión de documentos no fiscales"
   ENDIF

   IF lStatus = 7
      ? "En modo fiscal, cercana carga completa de la memoria fiscal y en espera"
   ENDIF

   IF lStatus = 8
      ? "En modo fiscal, cercana carga completa de la memoria fiscal y en emisión de documentos fiscales"
   ENDIF

   IF lStatus = 9
      ? "En modo fiscal, cercana carga completa de la memoria fiscal y en emisión de documentos no fiscales"
   ENDIF

   IF lStatus = 10
      ? "En modo fiscal, carga completa de la memoria fiscal y en espera"
   ENDIF

   IF lStatus = 11
      ? "En modo fiscal, carga completa de la memoria fiscal y en emisión de documentos fiscales"
   ENDIF

   IF lStatus = 12
      ? "En modo fiscal, carga completa de la memoria fiscal y en emisión de documentos no fiscales"
   ENDIF

RETURN //oTFHKA:cEstatus

FUNCTION IFERROR()

  LOCAL lError

   IF lError = 0
      ? "No hay Error"
   ENDIF

   IF lError = 1
      ? "Fin en la entrega de papel"
   ENDIF

   IF lError = 2
      ? "Error de índole mecánico en la entrega de papel"
   ENDIF

   IF lError = 3
      ? "Fin en la entrega de papel y error mecánico"
   ENDIF

   IF lError = 80
      ? "Comando invalido o valor invalido"
   ENDIF

   IF lError = 84
      ? "Tasa invalida"
   ENDIF

   IF lError = 88
      ? "No hay asignadas directivas"
   ENDIF

   IF lError = 92
      ? "Comando invalido"
   ENDIF

   IF lError = 96
      ? "Error Fiscal"
   ENDIF

   IF lError = 100
      ? "Error de la memoria Fiscal"
   ENDIF

   IF lError = 108
      ? "Memoria Fiscal llena"
   ENDIF

   IF lError = 112
      ? "Buffer completo. debe enviar el comando de reinicio"
   ENDIF

   IF lError = 128
      ? "Error en la comunicación"
   ENDIF

   IF lError = 137
      ? "No hay respuesta"
   ENDIF

   IF lError = 144
      ? "Error LRC"
   ENDIF

   IF lError = 145
      ? "Error interno api"
   ENDIF

   IF lError = 153
      ? "Error en la apertura del archivo"
   ENDIF
/*
0 No hay error.
1 Fin en la entrega de papel.
2 Error de índole mecánico en la entrega de papel.
3 Fin en la entrega de papel y error mecánico.
80 Comando invalido o valor invalido. 
84 Tasa invalida.
88No hay asignadas directivas. 
92 Comando invalido.
96Error fiscal. 
100 Error de la memoria fiscal.
108Memoria fiscal llena. 
112 Buffer completo. (debe enviar el comando de reinicio)
128Error en la comunicación. 
137 No hay respuesta.
144Error LRC. 
145 Error interno api.
153Error en la apertura del archivo.
*/
RETURN

FUNCTION IFPRINT()
  LOCAL cResp,cMonto

    oTFHKA:PFRUNCMD("Sendcmd",@lstatus, @lerror, "3")
    oTFHKA:PFRUNCMD("Sendcmd",@lstatus, @lerror, "110")
    oTFHKA:PFRUNCMD("Sendcmd",@lstatus, @lerror, "199")

//  cPagado  :=IIF(nPagado<>0,ALLTRIM(STR(nPagado*100,8,0)),0)
//  If cTipDoc <> "DEV" 
//     If nPagado<>0
//        oTFHKA:PFRUNCMD("SendCmd",Status, Error, "110")
//        oTFHKA:PFRUNCMD("SendCmd",Status, Error, "110")
//     Else
//        oTFHKA:PFRUNCMD("SendCmd",Status, Error, "110")
//     EndIf
//  EndIf
//oTFHKA:PFRUNCMD("closefpctrl","")
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// todo lo hice en un solo formato para datapro texto y es algo limitado pero hay creatividad para que funcione y funciona
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//@:MOVER(GEN->FAC_GIRO<MTONET,"cMENORD") // monto divisa < neto
//@:MOVER(GEN->FAC_GIRO>0,"cMAYORCERO")   //monto divisa > 0
//@:MOVER(GEN->FAC_GIRO!=0,"cDIFECERO")  //monto divisa <> 0
//@:MOVER(SUBST(FORMA,1,1)="E","cEFECTIVO") // forma de pago  = efectivo bs
//@:MOVER(IIF(cMAYORCERO,"3",""),"cNIGTF") // monto divisa mayor que 0

// divisa mayor que 0, coloca un numero 3 
//@:fwrite(ncontrol,cNIGTF+IIF(cMAYORCERO,CHR(13)+CHR(10),ALLTRIM(SPACE(13))))

// 22 pago parcial en divisa
//@:fwrite(ncontrol,IIF(SUBST(FORMA,1,1)="C".AND.GEN->FAC_GIRO<=MTONET,"22"+RIGHT("0000000000000"+ALLTRIM(STR(GEN->FAC_GIRO*100,13,0)),13),"")+IIF(SUBST(FORMA,1,1)="C",CHR(13)+CHR(10),ALLTRIM(SPACE(13))))

// 101 pago en efectivo bs para cerrar la factura parcial
//@:fwrite(ncontrol,IIF(SUBST(FORMA,1,1)="C".AND.GEN->FAC_GIRO<=MTONET.AND.GEN->FAC_GIRO>0,"101","")+IIF(SUBST(FORMA,1,1)="C",CHR(13)+CHR(10),ALLTRIM(SPACE(13))))

// 201 pago parcial en bs
//@:fwrite(ncontrol,IIF(cMAYORCERO.AND.cMENORD.AND.SUBST(FORMA,1,1)="E","201"+RIGHT("000000000000"+ALLTRIM(STR(MTONET*100,12,0)),12),"")+IIF(cDIFECERO.AND.cEFECTIVO,CHR(13)+CHR(10),ALLTRIM(SPACE(12))))

// 120 pago en dolares para cerrar la factura parcial
//@:fwrite(ncontrol,IIF(cEFECTIVO.AND.cDIFECERO,"120","")+IIF(cDIFECERO.AND.cEFECTIVO,CHR(13)+CHR(10),ALLTRIM(SPACE(13))))

//GIRO 0 - un pago clasico que solo cierra la factura sin mas condicionales
//@:fwrite(ncontrol,IIF(SUBST(FORMA,1,1)="E".AND.GEN->FAC_GIRO=0,"101","")+IIF(SUBST(FORMA,1,1)="E" .AND. GEN->FAC_GIRO=0,CHR(13)+CHR(10),ALLTRIM(SPACE(13))))

// comando obligatorio para cerrar todas las facturas cuando esté la impresora programada con el 3% IGTF
//@:fwrite(ncontrol,"199"+chr(13)+chr(10))

//PENDIENTE no
//@:fwrite(ncontrol,iif(SUBST(FORMA,1,1)=" ","110",""))  //101
//@:fwrite(ncontrol,iif(SUBST(FORMA,1,1)="E","110",""))  //101
//@:fwrite(ncontrol,iif(SUBST(FORMA,1,1)="C","110",""))  //105
//@:fwrite(ncontrol,iif(SUBST(FORMA,1,1)="T","110",""))
//@:fwrite(ncontrol,iif(SUBST(FORMA,1,1)="D","110",""))

RETURN .T.


FUNCTION IFREPORTEX()
  oTFHKA:PFRUNCMD("Sendcmd",@lstatus,@lerror, "I0X")
//  oTFHKA:PFRUNCMD("PFcierraNF"  ,"")
RETURN

FUNCTION IFREPORTEZ()
  oTFHKA:PFRUNCMD("Sendcmd",@lstatus,@lerror, "I0Z")
  oTFHKA:PFRUNCMD("closefpctrl","")
RETURN 

FUNCTION PFRUNCMD(cFunc,cPar1,cPar2,cPar3,cPar4,cPar5,cPar6,cPar7,cPar8,cPar9)
   
  LOCAL uResult, cFarProc, hDLL:=oTFHKA:hDll 
     
  cFarProc:= GetProcAddress(hDLL,cFunc,.T.,7,8,8,8,8,8,8,8,8,8 )
  uResult := CallDLL(cFarProc,cPar1,cPar2,cPar3,cPar4,cPar5,cPar6,cPar7,cPar8,cPar9)  
RETURN uResult

FUNCTION IFCLOSE()

   IF oTFHKA:hDLL>0
     oTFHKA:PFRUNCMD("closefpctrl","")
   ENDIF

   oTFHKA:IFCERRARDLL()

   IF(oTFHKA:oFile=NIL,NIL,oTFHKA:oFile:Close())

RETURN 


FUNCTION IFCERRARLL()

? oTFHKA:hDLL,"oTFHKA:hDLL "
  FreeLibrary(oTFHKA:hDLL ) 
  oTFHKA:hDLL:=NIL

RETURN .T.

FUNCTION MSGLOG(cMsg,lMsgErr)

  IF oTFHKA:lMsgErr .AND. Empty(cMsg)
     cMsg:=MemoRead(oTFHKA:cFileLog)
  ENDIF

  IF !Empty(cMsg)
     MsgMemo(cMsg)
  ENDIF

RETURN .T.

FUNCTION MSGERR()
  LOCAL cMsg:=""

  IF oTFHKA:lShow 
    cMsg:=EJECUTAR("MSGTEMPERR")
  ENDIF

  IF !Empty(cMsg)
     MsgMemo(cMsg)
  ENDIF

RETURN .T.
// EOF

/*
  IF lDemo

     cAlicuota = AllTRIM(STR(oTable:MOV_IVA,6,2))
     nPreTotal:= ALLTRIM(STRTRAN(TRAN(oTable:MOV_TOTAL,"999999999999.99"),".",""))
     nDivisa  := ALLTRIM(STRTRAN(TRAN(oTable:DOC_DIVISA,"999999999999.99"),".",""))
     cCant    :=ALLTRIM(TRANSFORM(oTable:MOV_CANTID,"999999.999"))
     cPrecio  :=ALLTRIM(TRANSFORM(oTable:MOV_PRECIO,"999999999.99"))
     cDescri  :=ALLTRIM(PADR(oTable:INV_DESCRI,20))

    oTable:DOC_TIPDOC := "TIK"
    cMAQUI:="EOG0000000"
   

    cNombre := ALLTRIM(PADR("PRUEBA CLIENTE",35))
    cRIF    := ALLTRIM(PADR("J00000000",12))
    cDIR1   := ALLTRIM(PADR("DIRECCION DEMO",15))
    cTel1   := ALLTRIM(PADR("000000000",12))
    cNUNFAC := ALLTRIM(PADR("0000000001",10))
    cAlicuota = AllTRIM(STR(16.00,6,2))
    nPreTotal:= ALLTRIM(STRTRAN(TRAN(1.00,"999999999999.99"),".",""))
    nDivisa  := ALLTRIM(STRTRAN(TRAN(1.00,"999999999999.99"),".",""))
    cCant    :=ALLTRIM(TRANSFORM(1.00,"999999.999"))
    cPrecio  :=ALLTRIM(TRANSFORM(1.00,"999999999.99"))
    cDescri  :=ALLTRIM(PADR("PRODUCTO DE PRUEBA",20))

 ENDIF
*/
/////////////////////////////////////////////////
//iF*0
//iD*30-09-2022
//iS*PRUEBA
//iR*V1111111
//i00TIPO: CONTADO 
//i00Telf: 041425100000
//i00DIR: DIRECCC
//i00Vendedor: VENDE
//!000000010000004000LECHE EN POLVO NIDO
//!000000010000010000LECHE DE ALMENDRA SI
//200000020000000
//200000020000000
//200000020000000
//210000020000000
//115
/////////////////////////////////////////////////
///////////DEBITO////////////////////////////////
//iF*0000001
//iI*Z4A1234567
//iD*18-01-2014
//iS*Pedro Mendez
//iR*12.345.678
//i00COMENTARIO
//`1000000010000001000EL PRODUCTO EXE
//`1000000010000001000EL PRODUCTO ADIC
//101
//////////////////////////////////////////////////
////////////////CREDITO///////////////////////////
//iR*12345678
//iS*PRUEBA
//iF*10000000000
//iD*30-09-2022
//iI*SERIAL IMPRE
//i00UN COMENTARIO
//d0000000010000001000PRODUCTO EXE
//d1000000020000001000PRODUCTO GRENERAL
//d2000000030000001000PRODUCTO REDU
//d3000000040000001000PRODUCTO ADIC
//101
///////////////////////////////////////////////////
//////////////REIMPRIMIR FACTURA O FECHAS//////////
//cambiar las tablas de document_id a default 1 para prevenir el error de array null de php al mover entre tablas
//-------------------
//Verificar Flags con comando D 
//    en el bodegon, no he podido verificarlas personalmente por no tener a la mano un reporte D
//Cocos:
//    21 - 30
//    63 - 02 < --- Verificar
//Hacer archivo de configuracion
//---------------------
//crear archivos configuracion parl padding fiscales
//    BIXOLON 350
//    SRP-350
//    HKA-80
//    HKA80_VE (con flags)
//----------------------
//T.Débito
//Efectivo Bs
//Efectivo $
//Zelle
//Cheque
//Transf/Dep
//T.Crédito
//Cesta Ticket
//Saldo
//Credito
//Pago Movil

//estado facturas dias 19-20 del 09/ 22
//IntTFHKA.exe UploadReportCmd(U4f02209190220920 retorno.txt

//reimprimir factura 15973
//IntTFHKA.exe SendCmd(RF00159730015973

//reimprimir Z de estos dias... 19-09-2022
//IntTFHKA.exe SendCmd(Rz02209190220919
//////////////////////////////////////////////////////////////////////////

/*

ANEXO 1: Lista de códigos de Status 
STATUS 
Retorno (Hex) Retorno (Decimal) Comentario
0 0   Estado desconocido. 
1 1   En modo prueba y en espera.
2 2   En modo prueba y emisión de documentos fiscales. 3 3 En modo prueba y emisión de documentos no fiscales.
4 4   En modo fiscal y en espera. 5 5 En modo fiscal y emisión de documentos fiscales.
6 6   En modo fiscal y emisión de documentos no fiscales. 7 7 En modo fiscal, cercana carga completa de la memoria fiscal y en espera.
8 8   En modo fiscal, cercana carga completa de la memoria fiscal y en emisión de documentos fiscales. 9 9 En modo fiscal, cercana carga completa de la memoria fiscal y en emisión de documentos no fiscales.
0A 10 En modo fiscal, carga completa de la memoria fiscal y en espera. 0B 11 En modo fiscal, carga completa de la memoria fiscal y en emisión de documentos fiscales.
0C 12 En modo fiscal, carga completa de la memoria fiscal y en emisión de documentos no fiscales.


Lista de códigos de Error 
ERROR 
Retorno (Hex) Retorno (Decimal) Comentario
00 0   No hay error. 01 1 Fin en la entrega de papel.
02 2   Error de índole mecánico en la entrega de papel. 03 3 Fin en la entrega de papel y error mecánico.
50 80  Comando invalido o valor invalido. 54 84 Tasa invalida.
58 88  No hay asignadas directivas. 5C 92 Comando invalido.
60 96  Error fiscal. 64 100 Error de la memoria fiscal.
6C 108 Memoria fiscal llena. 70 112 Buffer completo. (debe enviar el comando de reinicio)
80 128 Error en la comunicación. 89 137 No hay respuesta.
90 144 Error LRC. 91 145 Error interno api.
99 153 Error en la apertura del archivo.

*/


/*
marcelo
Sugiero usar un módulo .C con código para acceder a la impresora

aquí un ejemplo para una de las funciones

Declare la función SendNCmd Lib "FPCTRL.DLL" (estado tan largo, error tan
largo, búfer ByVal como cadena) tan largo

#incluye "windows.h
" #incluye "hbapi.h"

typedef LONG (WINAPI * _SENDNCMD)(estado LONG, error LONG, búfer LPSTR);

HB_FUNC( ENVIARNCMD )
{

identificador HINSTANCE = LoadLibrary("FPCTRL.DLL");

si (manejar)
{
estado LARGO ;
Error LARGO;
Búfer LPSTR = hb_parc( 3 ) ;

_SENDNCMD pFunc;

pFunc = (_SENDNCMD) GetProcAddress(manejar, "SendNCmd");
hb_retnl( pFunc( estado, error, Búfer ) );
hb_stornl(estado, 1);
hb_stronl( error, 2 );
FreeLibrary(manejador);
}
}

*/


/*

a
marcelo,
> error LARGO;
> Búfer LPSTR = hb_parc( 3 ) ;
>
> _SENDNCMD pFunc;
>
> pFunc = (_SENDNCMD) GetProcAddress(manejar, "SendNCmd");
> hb_retnl(pFunc(estado, error, Búfer));
> hb_stornl(estado, 1);
> hb_stronl( error, 2 );

¿Supongo que quieres obtener un error de la llamada SendNCmd?
Luego intente:
typedef LONG (WINAPI * _SENDNCMD) (estado LONG, error LONG *, búfer LPSTR);
y
pFunc(estado, &error, Búfer)

Saludos,
Saulio

*/
//https://webcache.googleusercontent.com/search?q=cache:IQbabAND0sUJ:https://groups.google.com/g/comp.lang.xharbour/c/EdOz2xrTWW0&cd=13&hl=es&ct=clnk&gl=ve
//https://webcache.googleusercontent.com/search?q=cache:9VpmieYMoS4J:https://comp.lang.xharbour.narkive.com/5L8weElg/immediate-backup-printing-to-lpt-port&cd=2&hl=es&ct=clnk&gl=ve
//https://webcache.googleusercontent.com/search?q=cache:U3ZelSLwcOQJ:https://www.lawebdelprogramador.com/codigo/Access/6239-Impresora-Fiscal-en-Access.html&cd=11&hl=es&ct=clnk&gl=ve
//https://github.com/KijamDev/API-Impresora-Fiscal-The-Factory/tree/master/FiscalMachine
//http://181.197.158.245/
/*

typedef LONG (WINAPI * _SENDNCMD)(LONG status, LONG error, LPSTR
buffer);

HB_FUNC( SENDNCMD )
{

HINSTANCE handle = LoadLibrary("FPCTRL.DLL");

if (handle)
{
LONG status ;
LONG error;
LPSTR Buffer = hb_parc( 3 ) ;

_SENDNCMD pFunc;

pFunc = (_SENDNCMD) GetProcAddress(handle, "SendNCmd");

hb_retnl( pFunc( status, error, Buffer ) );

hb_stornl( status, 1 );
hb_stronl( error, 2 );
FreeLibrary( handle );
}


}

*/

