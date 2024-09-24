// Programa   : DPDOCCLIZFF
// Fecha/Hora : 10/09/2024 15:01:39
// Propósito  : Zeta de Impresora Fiscal
// Creado Por : Juan Navas
// Llamado por:
// Aplicación :
// Tabla      :

#INCLUDE "DPXBASE.CH"

PROCE MAIN(cLetra,lView)
  LOCAL cCodSuc,cTipDoc:="ZFF",cNumero,cCodCli,nCxC:=0,nNeto:=0,nNumMem
  LOCAL aData:={},aLines:={},cMemo,nAt,cFile,cWhere,dFecha,cHora,I
  LOCAL nLen,cLine,cBas,cMto,aVta:={},aCre:={},aVars:={},aFields,aValues
  LOCAL oDb:=OpenOdbc(oDp:cDsnData)
  LOCAL aFiles:={},cFileOut,cZeta,oFont

  DEFAULT lView:=.F.

  IF !lView .AND. Empty(cLetra)

     IF !EJECUTAR("DPSERIEFISCALLOAD",NIL,.T.)
        RETURN .F.
     ENDIF

     cLetra:=oDp:cImpLetra

     // Ultimo Zeta
     IF Empty(oDp:cZeta)
       // debe buscar en la memoria fiscal
       oDp:cZeta    :="0028"
     ENDIF

  ENDIF

  DEFAULT cLetra       :="B",;
          oDp:cFileBema:="BEMAFI32.INI"

  cZeta:=oDp:cZeta
  nLen :=LEN(cZeta)
  cZeta:=STRZERO(VAL(cZeta)+1,nLen)

  cMemo  :=MemoRead(oDp:cFileBema)

  IF !FILE(oDp:cFileBema)
     MsgMemo("Archivo "+oDp:cFileBema+" no Existe")
  ENDIF

  nAt    :=AT("Path",cMemo)
  cFile  :=SUBS(cMemo,nAt+5,LEN(cMemo))
  nAt    :=AT(CHR(10),cFile)
  cFile  :=LEFT(cFile,nAt-1)+"\retorno.txt"
  cFile  :=STRTRAN(cFile,CHR(10),"")
  cFile  :=STRTRAN(cFile,CHR(13),"")

  aFiles :=DIRECTORY(cFile)
  dFecha :=aFiles[1,3]
  cFileOut:="repzeta\zeta_"+cZeta+"_"+RIGHT(DTOS(dFecha),6)+".txt"

  lmkdir("repzeta")

  COPY FILE (cFile) to (cFileOut)

  IF lView

    DEFINE FONT oFont     NAME "Courier"   SIZE 0, -10

    VIEWRTF(cFileOut,"Archivo "+cFileOut,oFont)

    RETURN .F.

  ENDIF

  cMemo  :=MemoRead(cFile)
  cCodSuc:=SQLGET("DPSERIEFISCAL","SFI_CODSUC","SFI_LETRA"+GetWhere("=",cLetra))

  MsgRun("Registrando Cierre Zeta en "+cCodSuc+" Serie Fiscal "+cLetra)

  IF Empty(cCodSuc)
     cCodSuc:=oDp:cSucursal
  ENDIF

  oDb:EXECUTE([ UPDATE DPDOCCLI SET DOC_CODSUC]+GetWhere("=",cCodSuc)+[ WHERE DOC_TIPDOC="ZFF" AND DOC_CODSUC="" AND DOC_CODSUC IS NULL ])
  oDb:EXECUTE(" SET FOREIGN_KEY_CHECKS = 0")

  IF !ISSQLFIND("DPTIPDOCCLI","TDC_TIPO"+GetWhere("=",cTipDoc))
    EJECUTAR("DPTIPDOCCLICREA",cTipDoc,"Reporte Z Factura Fiscal","N")
  ENDIF

  EJECUTAR("DPEMPGETRIF")

  cCodCli:=SQLGET("DPCLIENTES","CLI_CODIGO","CLI_RIF"+GetWhere("=",oDp:cRif)) // RIF de la empresa

  IF Empty(cCodCli)
    cCodCli:=EJECUTAR("DPCLIENTECREA",oDp:cRif,oDp:cEmpresa,oDp:cRif)
  ENDIF

  cNumero:=cLetra+oDp:cZeta

  cWhere:="DOC_CODSUC"+GetWhere("=",cCodSuc)+" AND "+;
          "DOC_TIPDOC"+GetWhere("=",cTipDoc)+" AND "+;
          "DOC_NUMERO"+GetWhere("=",cNumero)+" AND "+;
          "DOC_TIPTRA"+GetWhere("=","D"    )

  IF !ISSQLFIND("DPDOCCLI",cWhere)
     EJECUTAR("DPDOCCLICREA",cCodSuc,cTipDoc,cNumero,cCodCli,oDp:dFecha,oDp:cMoneda,"D",NIL,nNeto,0,1,CTOD(""),NIL,NIL,NIL,nCxC)
  ENDIF

  nNumMem:=SQLGET("DPDOCCLI","DOC_NUMMEM",cWhere)

  IF nNumMem=0

     nNumMem:=EJECUTAR("DPMEMONEW",nNumMem,NIL,cMemo,NIL,NIL,NIL,cCodSuc)

     IF nNumMem>0
       SQLUPDATE("DPDOCCLI","DOC_NUMMEM",nNumMem,cWhere)
     ENDIF

  ENDIF

  aData:=STRTRAN(cMemo,CRLF,CHR(10))

  aData   :=_VECTOR(aData,CHR(10))
  
  IF !TYPE("oZetaB")="O"
    TDpClass():New(NIL,"oZetaB")
  ENDIF

  oZetaB:nNeto:=0
  oZetaB:VTAB_Exentos:=0
  oZetaB:VTAB_IGTF03:=0.00 // Base
  oZetaB:VTAM_IGTF03:=0.00 // Monto
  oZetaB:VTAB_BIG16 :=0.00
  oZetaB:VTAM_IVAG16:=0.00
  oZetaB:VTAB_BIR08 :=0.00
  oZetaB:VTAM_IVAR08:=0.00
  oZetaB:VTAB_BIA31 :=0.00
  oZetaB:VTAM_IVAA31:=0.00
  oZetaB:CREB_IGTF03:=0.00
  oZetaB:CREM_IGTF03:=0.00
  oZetaB:CREB_BIG16 :=0.00
  oZetaB:CREM_IVAG16:=0.00
  oZetaB:CREB_BIR08 :=0.00
  oZetaB:CREM_IVAR08:=0.00
  oZetaB:CREB_BIA31 :=0.00
  oZetaB:CREM_IVAA31:=0.00
  oZetaB:nMtoIgtf   :=0.00

  // Fecha
  nAt    :=ASCAN(aData,{|a,n| "RIF"$a} )
  // OJO, aqui debemos validar el ZETA corresponda con la empresa
  oZetaB:dFecha:=oDp:dFecha

  IF nAt>0
    oZetaB:dFecha:=CTOD(LEFT(aData[nAt+1],10))
  ENDIF

  oZetaB:cFavFin :=GETULTIMOS("Última Factura")
  oZetaB:cCreFin :=GETULTIMOS("Nota Crédito")
  oZetaB:cZetaFin:=GETULTIMOS("Reporte Z")

  oZetaB:cFavCant:=GETCONTADORES("Facturas desde la Última Z") // Cantidad de Facturas, Obtenemos la Factura Inicial
  oZetaB:cFavIni :=STRZERO(VAL(oZetaB:cFavFin)-VAL(oZetaB:cFavCant),6) // factura Inicial

  nAt:=ASCAN(aData,{|a,n|"-Totales Por Base Imponible-"$a})
  IF nAt>0

    aVta:={}
    WHILE (nAt++,!("-"$aData[nAt]))
       AADD(aVta,aData[nAt])
    ENDDO
  ENDIF

  // Ventas
  ZFFSETVAR(aVta,"VTA")

  // Notas de Crédito / Devoluciones
  nAt:=ASCAN(aData,{|a,n|"-------Notas de Crédito y/o Devoluciones"$a})
  IF nAt>0

    aCre:={}
    WHILE (nAt++,!("*"$aData[nAt]))
       AADD(aCre,aData[nAt])
    ENDDO

  ENDIF

  // Ventas
  ZFFSETVAR(aCre,"CRE")

  aData:={}

  FOR I=1 TO LEN(aVars)

     IF (aVars[I,3]+aVars[I,5]>0) .AND. ISSQLFIND("DPIVATIP","TIP_CODIGO"+GetWhere("=",aVars[I,1]))

        AADD(aData,{oDp:cCtaIndef,aVars[I,2],aVars[I,3],aVars[I,1],aVars[I,6],aVars[I,3]+IF(aVars[I,1]="EX",0,aVars[I,5])})
        oZetaB:nNeto:=oZetaB:nNeto+aVars[I,3]+IF(aVars[I,1]="EX",0,aVars[I,5])

     ENDIF

  NEXT I

  aFields:={"DOC_GIRNUM","DOC_MTOEXE"        ,"DOC_NETO"  ,"DOC_FECHA","DOC_HORA","DOC_SERFIS","DOC_OTROS","DOC_CODIGO","DOC_IMPOTR",;
            "DOC_NUMFIS","DOC_PLAEXP"}

  aValues:={oDp:cZeta   ,oZetaB:VTAB_Exentos,oZetaB:nNeto,oZetaB:dFecha,cHora    ,cLetra      ,oZetaB:nMtoIgtf   ,cCodCli      ,oZetaB:VTAB_Percibidos,;
            oZetaB:cFavFin,oZetaB:cFavIni}

  SQLUPDATE("DPDOCCLI",aFields,aValues,cWhere)

  EJECUTAR("DPDOCCLICTAADD",cCodSuc,cTipDoc,cNumero,NIL,cLetra,aData)

  oDb:EXECUTE(" SET FOREIGN_KEY_CHECKS = 1")

RETURN .T.

FUNCTION ZFFSETVAR(aData,cVar)
   LOCAL I,cLine,cBas,cMto,aQuitar:={"%"," ","_00","."}
   LOCAL nValBas,nValMto,aBas,aMto,cIVA:="",aLine,nPor:=0

   FOR I=1 TO LEN(aData)
     cLine:=aData[I] // STRTRAN(aData[I],",00%","___")
     // cLine:=STRTRAN(cLine,"%","_")
     cBas :=ALLTRIM(LEFT(cLine ,24))
     cMto :=ALLTRIM(RIGHT(cLine,24))

     AEVAL(aQuitar,{|a,n| cBas:=STRTRAN(cBas,a,""),;
                          cMto:=STRTRAN(cMto,a,"")})

     // Base
     aBas   :=_VECTOR(cBas,"=")
     aBas[1]:=cVar+"B_"+STRTRAN(aBas[1],",","_")
     aBas[1]:=STRTRAN(aBas[1],"_00")

     cIVA:=""

     IF "IGTF"$aBas[1]
       cIVA:="IGTF"
     ENDIF

     IF "Exe"$aBas[1]
       cIVA:="EX"
     ENDIF

     IF "Perci"$aBas[1]
       cIVA:="IP" // iva Percibido
     ENDIF

     IF "BIG"$aBas[1]
       cIVA:="GN"
     ENDIF

     IF "BIR08"$aBas[1]
       cIVA:="RD"
     ENDIF

     IF "A31"$aBas[1]
       cIVA:="S1"
     ENDIF

     IF LEN(aBas)=1
        AADD(aBas,0)
     ELSE
        aBas[2]:=VAL(STRTRAN(aBas[2],",","."))
     ENDIF

     oZetaB:SET(aBas[1],aBas[2])

     // Monto
     aMto:=_VECTOR(cMto,"=")
     aMto[1]:=cVar+"M_"+STRTRAN(aMto[1],",","_")
     aMto[1]:=STRTRAN(aMto[1],"_00")

     IF LEN(aMto)=1
       AADD(aMto,0)
     ELSE
       // aMto[2]:=STRTRAN(aMto[2],".",""))
       aMto[2]:=VAL(STRTRAN(aMto[2],",","."))
     ENDIF

     nPor:=VAL(RIGHT(aBas[1],2))


     AADD(aVars,{cIVA,aBas[1],aBas[2],aMto[1],aMto[2],nPor})

   NEXT 

RETURN .T.
/*
// ---------------Últimos Documentos---------------
*/
FUNCTION GETULTIMOS(cName)
   LOCAL cValue:="",nAt

   nAt:=ASCAN(aData,{|a,n| cName$a})
   IF nAt>0
      cValue:=SUBS(aData[nAt],16,6)
   ENDIF

RETURN cValue

/*
//-------------------CONTADORES-------------------
*/
FUNCTION GETCONTADORES(cName)
   LOCAL cValue:="",nAt

   nAt:=ASCAN(aData,{|a,n| cName$a})

   IF nAt>0
      cValue:=RIGHT(aData[nAt],6)
   ENDIF

RETURN cValue

/*
          SOLUCIONES POS VENEZUELA, C.A
  AV. PRINCIPAL DE LOS CHORROS EDIFICIO OZALID
        PISO MEZZANINA, MUNICIPIO SUCRE
   PARROQUIA LEONCIO MARTINEZ LOS DOS CAMINOS
         EDO. MIRANDA, ZONA POSTAL 1070
            "EQUIPO DE LABORATORIO"
RIF:J-313526010         
24/09/2024 17:17:54                   COO:000195
       LECTURA X        
                   NO FISCAL                    
-------------------CONTADORES-------------------
Contador General de Operación No Fiscal:  000008
Contador de Factura:                      000109
Contador de Nota de Crédito:              000009
Operaciones No Fiscales desde la Última Z 000000
Facturas desde la Última Z                000002
Notas de Crédito desde la Última Z        000000
RMF desde la Última Z                     000000
----------------TOTALES DEL DÍA-----------------
VENTA BRUTA DIARIA:                    11.092,65
DESCUENTOS:                                 0,00
NOTAS DE CRÉDITO:                           0,00
VENTA NETA:                            11.092,65
---------------Resumen Tributados---------------
Tot.     Valor Acumulado(Bs  )    Impuesto(Bs  )
Tributados            1.472,40            235,58
Exentos               9.620,25
Percibidos                0,00
Notas de Crédito          0,00              0,00
Suma:                11.092,65            235,58
-----------Totales Por Base Imponible-----------
IGTF03,00% =    2.628,23 IGTF 03,00% =     78,85
Exentos    =    9.620,25
Percibidos =        0,00
BI G16,00% =    1.472,40 IVA G16,00% =    235,58
BI R08,00% =        0,00 IVA R08,00% =      0,00
BI A31,00% =        0,00 IVA A31,00% =      0,00
-------Notas de Crédito y/o Devoluciones--------
IGTF03,00% =        0,00 IGTF 03,00% =      0,00
Exentos    =        0,00
Percibidos =        0,00
BI G16,00% =        0,00 IVA G16,00% =      0,00
BI R08,00% =        0,00 IVA R08,00% =      0,00
BI A31,00% =        0,00 IVA A31,00% =      0,00
***********GRANDES TOTALES ACUMULADOS***********
*GT:              186.352,06 * GT IVA:                  385,34 *
---------------Últimos Documentos---------------
Última Factura 000109 24/09/2024 15:16:03 Bs           2.846,72
Nota Crédito   000009 09/08/2024 10:15:22 Bs             917,07
Doc. No Fiscal 000008 23/09/2024 00:00:21 Bs               0,00
Reporte Z      000032 23/09/2024 00:00:01
---------Descuentos Por Base Imponible----------
IGTF03,00% =        0,00 IGTF 03,00% =      0,00
Exentos    =        0,00
Percibidos =        0,00
BI G16,00% =        0,00 IVA G16,00% =      0,00
BI R08,00% =        0,00 IVA R08,00% =      0,00
BI A31,00% =        0,00 IVA A31,00% =      0,00
---------Anulaciones Por Base Imponible---------
IGTF03,00% =        0,00 IGTF 03,00% =      0,00
Exentos    =        0,00
Percibidos =        0,00
BI G16,00% =        0,00 IVA G16,00% =      0,00
BI R08,00% =        0,00 IVA R08,00% =      0,00
BI A31,00% =        0,00 IVA A31,00% =      0,00
---------Incrementos Por Base Imponible---------
IGTF03,00% =        0,00 IGTF 03,00% =      0,00
Exentos    =        0,00
Percibidos =        0,00
BI G16,00% =        0,00 IVA G16,00% =      0,00
BI R08,00% =        0,00 IVA R08,00% =      0,00
BI A31,00% =        0,00 IVA A31,00% =      0,00
-----------TOTALIZADORES NO FISCALES------------
29 Retirada de caja   : 0000                0,00
30 Fondo de caja      : 0000                0,00
Total de Oper. No Fiscales Bs               0,00
RECARGO   NO FISCAL:                        0,00
DESCUENTO NO FISCAL:                        0,00
ANULACIÓN NO FISCAL:                        0,00
--------------INFORME GERENCIAL  ---------------
01 Informe General                          0000
02 Informe de Trans.                        0000
---------------FORMAS DE PAGO    ---------------
01 Efectivo             (0002)         11.407,08
02 Depósito         (V) (0000)              0,00
03 Pago por Transf  (V) (0000)              0,00
04 EFECTIVO         (V) (0000)              0,00
RZ restantes:    2209  MA restante :      99,99%
BEMATECH        MP-4000 TH FI        ECF-IF 
IQQQQQQQQQQQQWOURYEQU      CAJA:0001 TIENDA:0001
                 VERSIÓN:01.00.23 1FC9380014 




         SENIAT         
*/

// EOF
