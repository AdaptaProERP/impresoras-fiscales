// Programa   : THFEXE_TXT
// Fecha/Hora : 00/00/0000 00:00:00
// Propósito  : Solo emision de un ticket de venta fiscal para impresora HKA-80
// Creado Por : 	
// Llamado por: IntTFHKA.EXE
// Aplicación : VENTAS Y CTAS X COBRAR
// Tabla      : DPMOVINV,DPCLIENTES,DPDOCCLI
// Fecha/Hora : 00/00/0000 00:00:00

#INCLUDE "DPXBASE.CH"
#INCLUDE "FILEIO.CH"

//PROCE MAIN(cNumero,cTipDoc,nPagado,dFecha,cHora,cClicero,cRifcero)
PROCE MAIN(cCodSuc,cTipDoc,cNumero)

LOCAL cDir:="C:\IntTFHKA\",cFile:="C:\INTTFHKA\dpticket.txt",oTable,cNomVald,cCant,cPrecio,cTasa,cDec:=1,nDescT,cMemo:="",cTFHKA:="C:\WINDOWS\SYSTEM32\PUERTO.DAT",cPagado,cUS,nDocOtr:=0,nDocDcto:=0
LOCAL cEnlace:="",cEnlaceErr,cDesc,cDescT,cDescri,cDescriV:="",nHandler,cPrec,cNumit,cDescu,nPrecio,nPreTotal:=0,cNombre,cRIF,cDireccion,cTelefono
LOCAL cNumSer:="",cFecha:="",I,cAuxSerial,cHorad:="",iFecha:=""
LOCAL cSerialFis, cFacAsocia, cSerialFec, cFacAsMovim
LOCAL cFilex,cFecha,cMemoA
LOCAL cCero:=0,cDivMenor:=0,cDIVISA:=0,cTasa:=0,nDIVISA
LOCAL cMtoDivisa
LOCAL cWhere,cSql
LOCAL cVALOR:=MYSQLGET("DPHISMON","HMN_VALOR","HMN_CODIGO"+GetWhere("=","USD")+"  ORDER BY CONCAT(HMN_FECHA,HMN_HORA) DESC LIMIT 1")
LOCAL nPagado:=0

   DEFAULT cCodSuc:=oDp:cSucursal,;
           cTipDoc:="TIK",;
           cNumero:=SQLGETMAX("DPDOCCLI","DOC_NUMERO","DOC_TIPDOC"+GetWhere("=",cTipDoc))

 If oPos:DOC_TIPDOC = "DEV" 
    cNumero:=oPos:cTicketDev
 ENDIF

   cSql:=" SELECT  MOV_CODIGO,INV_DESCRI,MOV_TOTAL,DOC_OTROS,DOC_DCTO,MOV_PRECIO,DOC_DIVISA,MOV_DESCUE,MOV_CANTID,MOV_IVA,"+;
         " CCG_NOMBRE,CCG_DIR1,CCG_TEL1,CCG_RIF,CLI_NOMBRE,CLI_RIF,CLI_TEL1,CLI_DIR1,DOC_SERFIS"+;
         " FROM DPDOCCLI "+;
         " INNER  JOIN DPMOVINV       ON MOV_CODSUC=DOC_CODSUC AND MOV_TIPDOC=DOC_TIPDOC AND DOC_NUMERO=MOV_DOCUME AND MOV_APLORG"+GetWhere("=","V")+;
         " INNER  JOIN DPINV          ON MOV_CODIGO=INV_CODIGO "+;
         " LEFT   JOIN DPCLIENTESCERO ON CCG_CODSUC=DOC_CODSUC AND CCG_TIPDOC=DOC_TIPDOC AND CCG_NUMDOC=DOC_NUMERO "+;
         " INNER  JOIN DPCLIENTES     ON DOC_CODIGO=CLI_CODIGO "+;
         " WHERE DOC_CODSUC"+GetWhere("=",cCodSuc)+;
         "   AND DOC_TIPDOC"+GetWhere("=",cTipDoc)+;
         "   AND DOC_NUMERO"+GetWhere("=",cNumero)+;
         "   AND DOC_ACT"   +GetWhere("=",1)

   oTable:=OpenTable(cSql,.T.)


   cMtoDivisa:=0


   //cDIVISA:=STRZERO((cMtoDivisa*cVALOR/1)*100,13)
//   ? cDIVISA
//   cPagoDolar:=STRZERO((cMtoDivisa*cVALOR/1)*100,14)

  cUS        :=oDp:cUsuario

//  cNombre    :=PADR(IIF(!EMPTY(oTable:CLI_RIF),oTable:CLI_NOMBRE,oTable:CCG_NOMBRE),20)
//  cRIF       :=PADR(IIF(!EMPTY(oTable:CLI_RIF),oTable:CLI_RIF,oTable:CCG_RIF),20)
//  cDireccion :=PADR(IIF(!EMPTY(oTable:CLI_RIF),oTable:CLI_DIR1,oTable:CCG_DIR1),20)
//  cTelefono  :=PADR(IIF(!EMPTY(oTable:CLI_RIF),oTable:CLI_TEL1,oTable:CCG_TEL1),20)

  cRIF       :=PADR(oTable:CLI_RIF,20)
  cNombre    :=PADR(oTable:CLI_NOMBRE,20)
  cDireccion :=PADR(oTable:CLI_DIR1,20)
  cTelefono  :=PADR(oTable:CLI_TEL1,20)

  If oPos:DOC_TIPDOC = "DEV"

     //cSerialFis:=ALLTRIM(MYSQLGET("DPEQUIPOSPOS","EPV_IMPFIS","EPV_SERIEF='"+LEFT(oTable:DOC_NUMERO,1)+"'"))
     //?? cSerialFis, "Serial Impresora"
     cEnlace:=cEnlace+CHR(105)+CHR(82)+CHR(42)+cRIF+CHR(13)+CHR(10)
     cEnlace:=cEnlace+CHR(105)+CHR(83)+CHR(42)+cNombre+CHR(13)+CHR(10)
     cEnlace:=cEnlace+CHR(105)+CHR(70)+CHR(42)+oPos:cTicketDev+CHR(13)+CHR(10)
     cEnlace:=cEnlace+CHR(105)+CHR(68)+CHR(42)+DTOC(DATE())+CHR(13)+CHR(10)
     cEnlace:=cEnlace+CHR(105)+CHR(73)+CHR(42)+"ZTTTTTTTTTTT"+CHR(13)+CHR(10)
  Else
     cEnlace:=cEnlace+CHR(105)+CHR(83)+CHR(42)+cNombre+CHR(13)+CHR(10)
     cEnlace:=cEnlace+CHR(105)+CHR(82)+CHR(42)+cRIF+CHR(13)+CHR(10)
     cEnlace:=cEnlace+CHR(105)+CHR(48)+CHR(51)+"Dir. :"+cDireccion+CHR(13)+CHR(10)
     cEnlace:=cEnlace+CHR(105)+CHR(48)+CHR(52)+"Tlf. :"+cTelefono+" Cajero: "+cUS+CHR(13)+CHR(10)
     cEnlace:=cEnlace+CHR(105)+CHR(48)+CHR(53)+"Ref. :"+cNumero+CHR(13)+CHR(10)
  EndIf

  While !oTable:Eof()
     nPreTotal:=nPreTotal+oTable:MOV_TOTAL
     cCant    :=ALLTRIM(STR(oTable:MOV_CANTID*1000,8,0))
     nPrecio  :=oTable:MOV_PRECIO //(oTable:MOV_TOTAL/oTable:MOV_CANTID)*1.16
     cPrecio  :=ALLTRIM(STR(nPrecio*100,13,0))
     cTasa    :=IIF(oTable:MOV_IVA>0,cTasa:=CHR(33),cTasa:=CHR(32))
     cDescri  :=ALLTRIM(PADR(oTable:INV_DESCRI+SPACE(40),40))
     If oPos:DOC_TIPDOC = "TIK"
        cEnlace:=cEnlace+cTasa+right("0000000000000"+cPrecio,13)+right("00000000"+cCant,8)+cDescri+CHR(13)+CHR(10)+""
     EndIf
     If oPos:DOC_TIPDOC = "DEV" //.AND. oPos:cTicketDev
        cEnlace:=cEnlace+"d"+cTasa+right("0000000000000"+cPrecio,13)+right("00000000"+cCant,8)+cDescri+CHR(13)+CHR(10)+""
     EndIf

   oTable:DbSkip()
  EndDo 
  oTable:Gotop()

  cPagado  :=IIF(nPagado<>0,ALLTRIM(STR(nPreTotal*100,10,2)),0)

 If oPos:DOC_TIPDOC = "DEV" .OR. oPos:DOC_TIPDOC = "TIK"

  cEnlace:=cEnlace+"3"+CHR(13)+CHR(10)

  If cMtoDivisa>1 
     cDIVISA:=cMtoDivisa  
     //? cDIVISA
     cEnlace:=cEnlace+"22"+RIGHT("0000000000000"+ALLTRIM(STR(cDIVISA*100,13,0)),13)+CHR(13)+CHR(10)
     //cEnlace:=cEnlace+"22"+RIGHT("0000000000000"+cDIVISA,13)+CHR(13)+CHR(10)
     cEnlace:=cEnlace+"101"+CHR(13)+CHR(10)
  EndIf 

  //0
  If cDIVISA=0
     cEnlace:=cEnlace+"101"+CHR(13)+CHR(10)
  EndIf
 
  cEnlace:=cEnlace+"199"+CHR(13)+CHR(10)

 EndIf

  DPWRITE(cDir+"dpticket.txt",cEnlace)
  SysRefresh(.T.)

   WinExec(  GetWinDir()+ "\NOTEPAD.EXE "+cDir+"dpticket.txt")

  SysRefresh(.T.)

  FERASE(cFile)
  CURSORWAIT()
  (MsgRun("Imprimiendo Ticket No.:"+cCodTick,"Por Favor Espere",{||WAITRUN("C:\INTTFHKA\FACTURA.bat",0)}))
  SysRefresh(.T.)

RETURN  .T.

//
