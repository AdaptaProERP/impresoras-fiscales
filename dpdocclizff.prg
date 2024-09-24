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
  LOCAL aData:={},aLines:={},cMemo,nAt,cFile,cWhere,dFecha,dFechaD,cHora,cNumFav,i,cFavFin:=""
  LOCAL nMtoExe:=0,nBasIGTF:=0,nMtoIgtf:=0,nMtoNeto:=0,nLen,cLine,cBas,cMto,aVta:={},aCre:={},aVars:={},aFields,aValues
  LOCAL nBasGN :=0,nMtoGN:=0
  LOCAL nBasRD :=0,nMtoRD:=0
  LOCAL nBasS1 :=0,nMtoS1:=0
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

 // IF Empty(oDp:cZeta)
 //   RETURN .T.
 // ENDIF

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

  // ViewArray(aFiles)
  // ? dFecha,cFileOut
  // return 

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

// ? CLPCOPY(cMemo)

  aData:=STRTRAN(cMemo,CRLF,CHR(10))

  aData   :=_VECTOR(aData,CHR(10))
  
// ViewArray(aData)

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

  // Fecha
  nAt    :=ASCAN(aData,{|a,n| "RIF"$a} )
  dFechaD:=oDp:dFecha

  IF nAt>0
    dFechaD:=CTOD(LEFT(aData[nAt+1],10))
    // ? nAt,aData[nAt+1],dFecha,"aqui debe ser la fecga"
  ENDIF

  oZetaB:cFavFin :=GETULTIMOS("Última Factura")
  oZetaB:cCreFin :=GETULTIMOS("Nota Crédito")
  oZetaB:cZetaFin:=GETULTIMOS("Reporte Z")

  oZetaB:cFavCant:=GETCONTADORES("Facturas desde la Última Z") // Cantidad de Facturas, Obtenemos la Factura Inicial

  oZetaB:cFavIni :=STRZERO(VAL(oZetaB:cFavFin)-VAL(oZetaB:cFavCant),6) // factura Inicial

// ? oZetaB:cFavCant,"oZetaB:cFavCant"
// ? oZetaB:cFavFin,oZetaB:cCreFin,oZetaB:cZetaFin,"oZetaB:cZetaFin"

/*
  nAt:=ASCAN(aData,{|a,n| "Última Factura"$a})
  IF nAt>0
    cFavFin:=ALLTRIM(STRTRAN(aData[nAt],"Última Factura",""))
    cFavFin:=LEFT(cFavFin,6)
? "AQUI CORTA",nAt,cFavFin
  ENDIF
*/

  // ? nAt,"ultima factura",aData[nAt],cFavFin
  // Ventas
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

  // ViewArray(aVars)
  // 
  // RETURN .T.

  nMtoExe :=0 // BEMAGETVALUE("Exentos",aData,"N")
  dFecha  :=0 // BEMAGETVALUE("/"      ,aData,"D") // aqui toma la fecha
  cNumFav :=0 // BEMAGETVALUE("Contador de Factura:",aData,"C")
  nBasIGTF:=0 // BEMAGETVALUE("IGTF03,00% =",aData,"N")
  nBasGN  :=0 // BEMAGETVALUE("BI G16,00% =",aData,"N")
  nBasRD  :=0 // BEMAGETVALUE("BI R08,00% =",aData,"N")
  nBasS1  :=0 // BEMAGETVALUE("BI A31,00%",aData,"N")

  nMtoNeto:=0 // BEMAGETVALUE("VENTA NETA:" ,aData,"N")

// ViewArray(aData)

 
  // Exento
  aData:={}

  FOR I=1 TO LEN(aVars)

     IF (aVars[I,3]+aVars[I,5]>0) .AND. ISSQLFIND("DPIVATIP","TIP_CODIGO"+GetWhere("=",aVars[I,1]))

        AADD(aData,{oDp:cCtaIndef,aVars[I,2],aVars[I,3],aVars[I,1],aVars[I,6],aVars[I,3]+IF(aVars[I,1]="EX",0,aVars[I,5])})
        oZetaB:nNeto:=oZetaB:nNeto+aVars[I,3]+IF(aVars[I,1]="EX",0,aVars[I,5])

     ENDIF

  NEXT I

// ViewArray(aData)
//? oZetaB:nNeto,"oZetaB:nNeto"
// ? dFechaD,"dFechaD"

  aFields:={"DOC_GIRNUM","DOC_MTOEXE"        ,"DOC_NETO"  ,"DOC_FECHA","DOC_HORA","DOC_NUMFIS","DOC_SERFIS","DOC_OTROS","DOC_CODIGO","DOC_IMPOTR",;
            "DOC_NUMFIS","DOC_PLAEXP"}

  aValues:={oDp:cZeta   ,oZetaB:VTAB_Exentos,oZetaB:nNeto,dFechaD     ,cHora     ,cNumFav     ,cLetra      ,nMtoIgtf   ,cCodCli      ,oZetaB:VTAB_Percibidos,;
            oZetaB:cFavFin,oZetaB:cFavIni}

// ,cWhere)

  SQLUPDATE("DPDOCCLI",aFields,aValues,cWhere)

// {"DOC_GIRNUM","DOC_MTOEXE"        ,"DOC_NETO"  ,"DOC_FECHA","DOC_HORA","DOC_NUMFIS","DOC_SERFIS","DOC_OTROS","DOC_CODIGO","DOC_IMPOTR","DOC_NUMFIS
//               },;
//                       {oDp:cZeta   ,oZetaB:VTAB_Exentos,oZetaB:nNeto,dFechaD     ,cHora     ,cNumFav     ,cLetra      ,nMtoIgtf   ,cCodCli      ,oZetaB:VTAB_Percibidos},cWhere)


  // AADD(aData,{oDp:cCtaIndef,NIL,nMtoExe,"EX",0,nMtoExe})

  EJECUTAR("DPDOCCLICTAADD",cCodSuc,cTipDoc,cNumero,NIL,cLetra,aData)

  oDb:EXECUTE(" SET FOREIGN_KEY_CHECKS = 1")

RETURN .T.

/*
FUNCTION BEMAGETVALUE(cVar,aData,cType)
  LOCAL  nAt   :=ASCAN(aData,{|a,n| cVar$a})
  LOCAL  nValue:=0,cLine

  IF nAt>0 .AND. "IGTF03,00% ="$cVar

     cLine :=LEFT(aData[nAt],24)
     cLine :=STRTRAN(cLine,cVar,"")
     cLine :=STRTRAN(cLine,".","")
     cLine :=STRTRAN(cLine,",",".")
     nValue:=CTOO(cLine,"N")

     // Monto IGTF
     cLine:=RIGHT(aData[nAt],10)   // % IGTF
     cLine:=STRTRAN(cLine,".","" )
     cLine:=STRTRAN(cLine,",",".")

     nMtoIgtf:=VAL(cLine)

     RETURN nValue

  ENDIF

  IF nAt>0 .AND. "BI G16,00% ="$cVar

     cLine :=LEFT(aData[nAt],24)
     cLine :=STRTRAN(cLine,cVar,"")
     cLine :=STRTRAN(cLine,".","")
     cLine :=STRTRAN(cLine,",",".")
     nValue:=CTOO(cLine,"N")

     // Monto IGTF
     cLine:=RIGHT(aData[nAt],10)   // % IGTF
     cLine:=STRTRAN(cLine,".","" )
     cLine:=STRTRAN(cLine,",",".")

     nMtoGN:=VAL(cLine)

     RETURN nValue

  ENDIF


  IF nAt>0 .AND. "."$aData[nAt] .AND. cType="N"
    cLine :=ALLTRIM(STRTRAN(aData[nAt],cVar,""))
    cLine :=STRTRAN(cLine,"."    ,"")
    cLine :=STRTRAN(cLine,","    ,".")
    nValue:=CTOO(cLine,"N")
    nValue:=VAL(cLine)
    RETURN nValue
  ENDIF

  IF nAt>0 .AND. "/"$aData[nAt] .AND. cType="D"
    cLine :=CTOD(LEFT(aData[nAt],10))
    cHora :=SUBS(aData[nAt],12,8)
    RETURN cLine
  ENDIF

  IF nAt>0 .AND. cType="C"
    cLine :=ALLTRIM(STRTRAN(aData[nAt],cVar,""))
    RETURN cLine
  ENDIF

RETURN nValue
*/

FUNCTION ZFFSETVAR(aData,cVar)
   LOCAL I,cLine,cBas,cMto,aQuitar:={"%"," ","_00","."}
   LOCAL nValBas,nValMto,aBas,aMto,cIVA:="",aLine,nPor:=0

   // ADEPURA(aData,{|a,n| !"%"$a})

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
     //  AADD(aVars,{aBas[1],aBas[2],cIVA})

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

   // ? nAt,cName,cValue

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

// EOF
