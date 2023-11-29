//Inicio re-implementación impresoras fiscales mediante Objetos
// que faciliten implementación Unica.

//Adaptapro Datapro
//10 may 2022, 16:06 (hace 4 días)

//para Foro, Ejecutivos, Foro

// Programa   : DLL_EPSON
// Fecha/Hora : 26/04/2022 14:46:55
// Propósito  : LLamadas Epson DLL
// Creado Por :
// Llamado por:
// Aplicación :
// Tabla      :
//     Alicuota = 16.00 G
//     Alicuota =  8.00 R 
//     Alicuota = 00.00 E
//     Alicuota =  0.01 P
//     Alicuota = 31.00 A


#INCLUDE "DPXBASE.CH"

PROCE MAIN()
  LOCAL oTable,cNombre,cRif, cDir1, cDir2:="", cTel1:="",cAlicuota:="", cMemo:="",lRet:=.T.
  LOCAL cAuxSerial,status, error:=.F., lDevolu
  LOCAL cDescDev1:="", cDescDev2:="", cDescDev3:="", cNumSer:="",cNumAsoc:="",cFechAso:="",cHorAso:=""
  LOCAL cFile:="dpticket.txt",oTable,cNomVald,cCant,cPrecio,cTasa,nDesc:=0,nDescT,cMemo:="",cPagado,cUS,nDocOtr:=0,nDocDcto:=0
  LOCAL cTicket:="",cTicketErr,cDesc,cDescT,cDescri,cDescriV:="",nHandler,cPrec,cDescu,nPrecio,nPreTotal:=0,cNombre,cRIF,cNUNFAC,cTipDoc,cTel1,cDir1,cAlicuota,cMAQUI
  LOCAL nComando

  PRIVATE aTipoPago:={}

  TDpClass():New(NIL,"oEpson")
  oEpson:hDll    :=NIL
  oEpson:cName   :="EPSON"
  oEpson:cFileDll:="pnpdll.dll"

 IF !FILE(oEpson:cFileDll)
    MsgMemo("No se Encuenta Archivo "+oEpson:cFileDll)
    RETURN NIL
  ENDIF

  oEpson:hDll    := LoadLibrary(oEpson:cFileDll)
  oEpson:cPort   :="3" // Valor por Defecto

  IF !(Abs(oEpson:hDLL) > 32)
     MensajeErr("Error Leyendo Libreria "+oEpson:cFileDll)
     oEpson:IFCERRARDLL()
     RETURN NIL
  ENDIF

//,oEpson:cFileDll:=.f.
  DEFAULT cTicket:=ALLTRIM(STR(cTicket)),;
          cTipDoc:="TIK",nComando:=0

    oEpson:IFOPEN()

//  IF !oEpson:IFOPEN("3")
//     oTable:END()
//     oEpson:oFile:AppStr("Puerto:"+cPort+" no pudo Abrir")
//     oEpson:IFCLOSE()
//     RETURN .F.
//  ENDIF

   oTable:=OpenTable(" SELECT  MOV_CODIGO,INV_DESCRI,MOV_TOTAL,DOC_OTROS,DOC_DCTO,MOV_PRECIO,MOV_DESCUE,MOV_CANTID,MOV_IVA,CCG_NOMBRE,CCG_RIF,CCG_DIR1,CCG_TEL1"+;
			   " FROM DPMOVINV INNER JOIN DPINV ON MOV_CODIGO=INV_CODIGO"+;
			   " INNER  JOIN DPDOCCLI ON MOV_CODSUC=DOC_CODSUC AND MOV_TIPDOC=DOC_TIPDOC AND DOC_NUMERO=MOV_DOCUME AND DOC_TIPTRA='D'"+;
			   " LEFT   JOIN DPCLIENTESCERO ON CCG_CODSUC=DOC_CODSUC AND CCG_TIPDOC=DOC_TIPDOC AND CCG_NUMDOC=DOC_NUMERO "+;
			   " WHERE MOV_TIPDOC"+GetWhere("=",oPos:cTipDoc)+;
			   " AND   MOV_USUARI"+GetWhere("=",oDp:cUsuario)+;
			   " AND   MOV_DOCUME"+GetWhere("=",oPos:DOC_NUMERO),.T.)

// ahorita es que me doy cuenta que esto es lo que "bloquea" la impresora
//   oEpson:IFESTATUS() Esta funcion, el codigo esta frenando la salida del ticket. despues lo reviso

  IF oPos:cTipDoc="DEV"
    cMAQUI:=ALLTRIM(PADR(MYSQLGET("DPEQUIPOSPOS","EPV_IMPFIS","EPV_SERIEF"=oTable:DOC_SERFIS),10))

    cNombre := ALLTRIM(PADR(oTable:CCG_NOMBRE,35))
    cRIF    := ALLTRIM(PADR(oTable:CCG_RIF,12))
    cDIR1   := ALLTRIM(PADR(oTable:CCG_DIR1,15))
    cTel1   := ALLTRIM(PADR(oTable:CCG_TEL1,12))
    cNUNFAC := ALLTRIM(PADR(oPos:DOC_NUMERO,10))
    cCant    :=ALLTRIM(TRANSFORM(oTable:MOV_CANTID,"999999.999"))
    cPrecio  :=ALLTRIM(TRANSFORM(oTable:MOV_PRECIO,"999999999.99"))
    cDescri  :=ALLTRIM(PADR(oTable:INV_DESCRI,20))
  ENDIF

  IF oPos:cTipDoc="TIK"
    cNombre := ALLTRIM(PADR(oTable:CCG_NOMBRE,35))
    cRIF    := ALLTRIM(PADR(oTable:CCG_RIF,12))
    cDIR1   := ALLTRIM(PADR(oTable:CCG_DIR1,15))
    cTel1   := ALLTRIM(PADR(oTable:CCG_TEL1,12))
    cNUNFAC := ALLTRIM(PADR(oPos:DOC_NUMERO,10))
  ENDIF

    cCant    :=ALLTRIM(TRANSFORM(oTable:MOV_CANTID,"999999.999"))
    cPrecio  :=ALLTRIM(TRANSFORM(oTable:MOV_PRECIO,"999999999.99"))
    cDescri  :=ALLTRIM(PADR(oTable:INV_DESCRI,20))
    //cAlicuota = AllTRIM(STR(oTable:MOV_IVA,6,2))

    nPreTotal:= ALLTRIM(STRTRAN(TRAN(oTable:MOV_TOTAL,"999999999999.99"),".",""))
    nComando:="E|U|"+nPreTotal


// oEpson:IFIMPRESO()

 oEpson:IFABREFISCAL()

 oTable:Gotop()

 WHILE !oTable:Eof()

    IF  oTable:Eof()
        EXIT
    ENDIF

    oEpson:IFRENGLON()

    oTable:DbSkip()

 SysRefresh(.T.)

 ENDDO

 oTable:End()

 oEpson:IFPRINT()
 oEpson:IFCLOSE()

SysRefresh(.T.)
RETURN .T.
//RETURN oEpson

/////////////////////////////////////////////////////
//                  FUNCIONES                      //
/////////////////////////////////////////////////////

FUNCTION IFOPEN()
  LOCAL cResp,cPort 
  cResp:=oEpson:PFRUNCMD("PFabrepuerto","3")
  MSGALERT(cResp,"Puerto : ")
RETURN .T.

FUNCTION IFABREFISCAL()
  LOCAL cResp
  LOCAL lResp,edlinea1,edlinea2,edlinea3,edlinea4 

  //FUNCTION IFABREFISCAL(cPar1,cPar2)
  //FUNCTION IFDEVOFISCAL(cPar1,cPar2,cPar3,cPar4,cPar5,cPar6)
    
 IF oPos:DOC_TIPDOC = "TIK"
  cResp:=oEpson:PFRUNCMD("PFabrefiscal",cNombre,cRif)
  edlinea1="Nro. Documento:  "+cNUNFAC
  edlinea2="DIRECCION:  "+cDIR1
  edlinea3="TELEFONO:  "+cTel1
  edlinea4="----------------------------------------"
  cResp:=oEpson:PFRUNCMD("PFTfiscal",edlinea1) 
  cResp:=oEpson:PFRUNCMD("PFTfiscal",edlinea2) 
  cResp:=oEpson:PFRUNCMD("PFTfiscal",edlinea3) 
  cResp:=oEpson:PFRUNCMD("PFTfiscal",edlinea4)
  //MSGALERT(cResp,"Abre ticket : ")
 ENDIF
 //
 IF oPos:DOC_TIPDOC = "DEV"
  cResp:=oEpson:PFRUNCMD("PFDevolucion",cNombre,cRIF,cNUNFAC,cMAQUI,DTOC(DATE()),TIME())
  edlinea2="DIRECCION:  "+cDIR1
  edlinea3="TELEFONO:  "+cTel1
  edlinea4="----------------------------------------"
  cResp:=oEpson:PFRUNCMD("PFTfiscal",edlinea2) 
  cResp:=oEpson:PFRUNCMD("PFTfiscal",edlinea3) 
  cResp:=oEpson:PFRUNCMD("PFTfiscal",edlinea4)
  MSGALERT(cResp,"Abre Devolución : ")
 ENDIF
//No se puede ejecutar PFTfiscal para llamar a las variables; cNUMERO,cDir1,cTel1, fuera de esta Función. 
RETURN .T.

FUNCTION IFTEXTOFISCAL()   
  LOCAL cResp
  cResp:=oEpson:PFRUNCMD("PFTfiscal","") 
RETURN lResp

FUNCTION IFRENGLON()   
  LOCAL cResp //,cAlicuota

  cAlicuota:=STRZERO(oTable:MOV_IVA*100,4)
  cResp:=oEpson:PFRUNCMD("PFrenglon",cDescri,cCant,cPrecio,cAlicuota) 
RETURN lResp

FUNCTION IFCANCELADOC()
  cResp:=oEpson:PFRUNCMD("PFCancelaDoc","C","0")
RETURN 

FUNCTION IFESTATUS()
  LOCAL cResp 
  cResp:=oEpson:PFRUNCMD("PFestatus",""),""
//  cResp:=oEpson:PFRUNCMD("PFultimo","")
//  MSGALERT(cResp,"Ultimo: ")

      IF cResp = "TO"
        MsGALERT("Se excedió el tiempo de espera")
//        MsMemo("Se excedió el tiempo de espera")
      ENDIF
      IF cResp = "NP" 
       MsGALERT("Puerto no Abierto")
//        MsMemo("Puerto: "+cPort+" no Abierto")
      ENDIF
      IF cResp = "ER"
        MsGALERT("Existe un error")
//        MsMemo("Existe un error ")
      ENDIF
 oEpson:IFCLOSE()
RETURN 

FUNCTION IFCUTPAPER()
  LOCAL cResp 
  cResp:=oEpson:PFRUNCMD("PFCortar","")
  //MSGALERT(cResp,"Corta papel: ")
RETURN 

FUNCTION IFPRINT()
  LOCAL cResp

     cResp:=oEpson:PFRUNCMD("PFComando",nComando)

//  cResp:=oEpson:PFRUNCMD("PFComando","E|T|100")
//  ENDIF
  //MSGALERT(cResp,"Total mas IGTF: ")
  // U Para que calcule el 3% y de el total mas igtf
  // T totaliza sin el igtf
RETURN .T.

FUNCTION IFIMPRESO()
  IF oTable:DOC_IMPRES
     MensajeErr("Número Fiscal "+cTicket+" ya fué impreso")
  oTable:End()
  RETURN .F.
  ENDIF
RETURN 

FUNCTION IFREPORTEX()
  oEpson:PFRUNCMD("PFrepx"      ,"")
  oEpson:PFRUNCMD("PFcierraNF"  ,"")
RETURN

FUNCTION IFREPORTEZ()
  oEpson:PFRUNCMD("PFrepz"        ,"")
  oEpson:PFRUNCMD("PFcierrapuerto","")
RETURN 

FUNCTION PFRUNCMD(cFunc,cPar1,cPar2,cPar3,cPar4,cPar5,cPar6,cPar7,cPar8,cPar9)
   
  LOCAL uResult, cFarProc, hDLL:=oEpson:hDll 
     
  cFarProc:= GetProcAddress(hDLL,cFunc,.T.,8,8,8,8,8,8,8,8,8,8 )     
  uResult := CallDLL(cFarProc,cPar1,cPar2,cPar3,cPar4,cPar5,cPar6,cPar7,cPar8,cPar9)  
RETURN uResult

FUNCTION IFCLOSE()
   oEpson:PFRUNCMD("PFcierrapuerto","")
   oEpson:IFCERRARDLL()
SysRefresh(.T.)
RETURN 

//FUNCTION IFCLOSE()
//   IF oEpson:hDLL>0
//     oEpson:PFRUNCMD("PFcierrapuerto","")
//   ENDIF
//   oEpson:IFCERRARDLL()
//   IF(oEpson:oFile=NIL,NIL,oEpson:oFile:Close())
//RETURN 


FUNCTION IFCERRARDLL()
//  LOCAL cResp
? oEpson:hDLL,"oEpson:hDLL "
  FreeLibrary(oEpson:hDLL ) 
  oEpson:hDLL:=NIL
RETURN .T.

FUNCTION MSGLOG(cMsg,lMsgErr)

  IF oEpson:lMsgErr .AND. Empty(cMsg)
     cMsg:=MemoRead(oEpson:cFileLog)
  ENDIF

  IF !Empty(cMsg)
     MsgMemo(cMsg)
  ENDIF

RETURN .T.

FUNCTION MSGERR()
  LOCAL cMsg:=""

  IF oEpson:lShow 
    cMsg:=EJECUTAR("MSGTEMPERR")
  ENDIF

  IF !Empty(cMsg)
     MsgMemo(cMsg)
  ENDIF

RETURN .T.
// EOF

/*

