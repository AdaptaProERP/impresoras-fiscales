// Programa   : DPDOCCLIIMPFIS
// Fecha/Hora : 01/09/2006 07:55:37
// Propósito  : Imprimir Documento de Venta en Impresora Fiscal
// Creado Por : Juan Navas
// Modificado : Marlon Ramos 07-08-2008 (utilizar fecha y hora para evitar tickets kilómetricos)
// Llamado por: DPDOCNUMFIS
// Aplicación : Ventas
// Tabla      : DPDOCCLI

#INCLUDE "DPXBASE.CH"

PROCE MAIN(cImpFis,cCodSuc,cTipDoc,cCodCli,cNumero,lUpdate,dImpFecha,cImpHora,cClicero,cRifcero,cDircero)
LOCAL cNroAsoc:="", lRetorno:=.F.

DEFAULT dImpFecha:=MYSQLGET("DPDOCCLI","DOC_FECHA",oDocCli:cWhere),cImpHora:=MYSQLGET("DPDOCCLI","DOC_HORA",oDocCli:cWhere),cClicero:="",cRifcero:="",cDircero:=""

// IF UPPER(LEFT(cImpFis,8)) = "BEMATECH"
//    RETURN EJECUTAR("DLL_EXE_TFHKA",cCodSuc,cTipDoc,cCodCli,cNumero,0,cClicero,cRifcero)
// ENDIF
//RETURN .T.

// 16-09-2008 Marlon Ramos 
IF cTipDoc="DEV"
   IF VALTYPE(oGrid:cNumDoc)="C" .AND. !EMPTY(oGrid:cNumDoc)
      cNroAsoc:=oGrid:cNumDoc
   ELSE
      //cNroAsoc:=MYSQLGET("DPDOCCLI", "DOC_FACAFE","DOC_NUMERO"+GetWhere("=",cNumero)+" AND DOC_TIPDOC"+GetWhere("=",cTipDoc)+" AND DOC_CODSUC"+GetWhere("=",cCodSuc))
      cNroAsoc:=MYSQLGET("DPDOCCLI", "DOC_FACAFE",oDocCli:cWhere)
   ENDIF
   //?"cNroAsoc",cNroAsoc,cTipDoc,cNumero
ENDIF
// Fin 16-09-2008 Marlon Ramos 

 // ?"XXXXXXXXXX", cImpFis,cCodSuc,cTipDoc,cCodCli,cNumero,lUpdate,dImpFecha,cImpHora,cClicero,cRifcero,cDircero
 IF cImpFis="BMC"
    //07-08-2008 Marlon Ramos RETURN EJECUTAR("BMC",cNumero,cTipDoc)
    
    // 15-10-2008 Marlon Ramos (Implementación de DLL) RETURN EJECUTAR("BMC",cNumero,cTipDoc,dImpFecha,cImpHora,cNroAsoc)
       MsgRun("Imprimiento Ticket Nº: "+cNumero,"Impresora Fiscal "+oDp:cImpFiscal,;
             {||lRetorno:=EJECUTAR("BMC_DLL",cNumero,cTipDoc,dImpFecha,cImpHora,cNroAsoc,cClicero,cRifcero,cDircero)})
       RETURN lRetorno 
 ENDIF

 // 01-09-2008 Marlon Ramos IF "TMU220AF"$ALLTRIM(UPPE(cImpFis))
 IF ASCAN(oDp:aImprFiscEps,{|c,n| IIF( ValType(c)="C", (cImpFis $ c) , .F.) }) > 0
    //18-08-2008 Marlon Ramos EJECUTAR("TICKETEPSON",cNumero,cTipDoc,0)
//? "esto"
    EJECUTAR("TICKETEPSON",cNumero,cTipDoc,0,dImpFecha,cImpHora,cClicero,cRifcero,cDircero)
    RETURN .T.
 ENDIF

 IF LEFT(cImpFis,5)="EPSON"

//? "este"
    //18-08-2008 Marlon Ramos EJECUTAR("EPSONTMU200",cNumero,cTipDoc,0)
    EJECUTAR("EPSONTMU200",cNumero,cTipDoc,0,dImpFecha,cImpHora,cClicero,cRifcero,cDircero)

 ENDIF

//** IGTF **//
// ? "PASA POR L 58 DPDOCCLIIMPFIS"
//  EJECUTAR('DPDOCCLIIGTF',oDocCli:DOC_CODSUC,oDocCli:DOC_TIPDOC,oDocCli:DOC_CODIGO,oDocCli:DOC_NUMERO,oDocCli:cNomDoc,'V',oDocCli:DOC_NETO)


// IF UPPER(LEFT(cImpFis,8)) = "BEMATECH"
//    EJECUTAR('DPDOCCLIIGTF',oDocCli:DOC_CODSUC,oDocCli:DOC_TIPDOC,oDocCli:DOC_CODIGO,oDocCli:DOC_NUMERO,oDocCli:cNomDoc,'V',oDocCli:DOC_NETO)
// ENDIF

//IGTF 25-08-2022    
// IF UPPER(LEFT(cImpFis,8)) = "BEMATECH"
//    // 16-09-2008 RETURN EJECUTAR("BEMATECH",cTipDoc,ºcNumero,dImpFecha,cImpHora,cClicero,cRifcero,cDircero)
//    //RETURN EJECUTAR("BEMATECH",cTipDoc,cNumero,dImpFecha,cImpHora,cClicero,cRifcero,cDircero,cNroAsoc)
//    RETURN EJECUTAR("BEMAPRINT",cCodSuc,cTipDoc,cCodCli,cNumero,0,cClicero,cRifcero)
// ENDIF
// Fin 02-09-2008 Marlon Ramos 


// 10-10-2008 Marlon Ramos 
 // 27-01-2009 Marlon Ramos IF UPPER(cImpFis)="SAMSUNG"
 IF UPPER(cImpFis)="SAMSUNG" .OR. UPPER(LEFT(cImpFis,5))="ACLAS" .OR. UPPER(LEFT(cImpFis,7))="OKIDATA" .OR. UPPER(LEFT(cImpFis,4))="STAR"
    MsgRun("Imprimiento Ticket Nº: "+cNumero,"Impresora Fiscal "+oDp:cImpFiscal,;
           {||lRetorno:=EJECUTAR("SAMSUNG",cNumero,cTipDoc,dImpFecha,cImpHora,cNroAsoc,cClicero,cRifcero,cDircero)})
    RETURN lRetorno 
 ENDIF
// Fin 10-10-2008 Marlon Ramos 

RETURN .T.