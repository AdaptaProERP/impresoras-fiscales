// Programa   : DLL_EPSON
// Fecha/Hora : 26/04/2022 14:46:55
// Propósito  : LLamadas Epson DLL
// Creado Por : Kelvis Escalante, Juan Navas
// Requiere   : Implementar Driver photon, puede descargarlo desde https://mega.nz/folder/tckzSCbB#ROs1j2cWRcicFoVmnj75OQ
//              Archivo pnpdll.dll desde https://desarrollospnp.com/archivos/pnpdll2022.zip  
// Llamado por:
// Aplicación :
// Tabla      :
#INCLUDE "DPXBASE.CH"

PROCE MAIN(cTipDoc,cNumero)
  LOCAL cFileLog:="",cSql,cWhere,cEstatus
  LOCAL cMaqui,cNombre,cRif   ,cDir1   ,cTel1,cNumFav
  LOCAL cCant ,cPrecio,cDescri,cAlicuota
  LOCAL cPuerto :=RIGHT(oDp:cImpFisCom,1) // si es COM9, será 9
  LOCAL nDivisa :=0,nIva
  LOCAL oEpson,oTable,cPicture:="999999999.99"
  LOCAL lSave:=.F.,cTipo,nNumero,cMemo,cNumFis:=""

  DEFAULT cTipDoc:="TIK",;
          cNumero:=SQLGETMAX("DPDOCCLI","DOC_NUMERO","DOC_TIPDOC"+GetWhere("=",cTipDoc))

  cWhere:="DOC_CODSUC"+GetWhere("=",oDp:cSucursal)+" AND "+;
          "DOC_TIPDOC"+GetWhere("=",cTipDoc      )+" AND "+;
          "DOC_NUMERO"+GetWhere("=",cNumero      )+" AND "+;
          "DOC_TIPTRA"+GetWhere("=","D"          )

  // Obtiene el Monto en Bs para que la impresora fiscal realice el Cálculo del IGTF.
  nDivisa  :=EJECUTAR("DPDOCCLIPAGDIV",oDp:cSucursal,cTipDoc,cNumero)

  IF oDp:nImpFisLen>0
    cPicture:=BuildPicture(oDp:nImpFisLen+1,oDp:nImpFisEnt,.F.)
  ENDIF

  IF !TYPE("oEpson")="O"
    TDpClass():New(NIL,"oEpson")
  ENDIF

  oEpson:hDll    :=NIL
  oEpson:cName   :="EPSON"
  oEpson:cFileDll:="pnpdll.dll"
  oEpson:cEstatus:=""
  oEpson:oFile   :=NIL
  oEpson:lError  :=.F.

  cFileLog:="TEMP\"+cTipDoc+cNumero+".LOG"

  FERASE(cFileLog)

  IF !FILE(oEpson:cFileDll)
    MsgMemo("No se Encuentra Archivo "+oEpson:cFileDll)
    RETURN NIL
  ENDIF
 
  oEpson:hDll    := LoadLibrary(oEpson:cFileDll)
  oEpson:cPort   :=cPuerto // Valor por Defecto

  IF !(Abs(oEpson:hDLL) > 32)
     MensajeErr("Error Leyendo Libreria "+oEpson:cFileDll)
     oEpson:IFCERRARDLL()
     RETURN NIL
  ENDIF

  oEpson:oFile:=TFile():New(cFileLog)

  oEpson:IFOPEN()

  WHILE .T.

    cEstatus:=oEpson:IFESTATUS()

    SQLUPDATE("DPDOCCLI",{"DOC_NUMPER","DOC_IMPRES"},{cEstatus,.F.},cWhere) // Estatus Impresora

    IF !oDp:lImpFisModVal .AND. !Empty(oEpson:cEstatus) .AND. MsgNoYes("Desea Intentar Nuevamente", "Estatus: "+oEpson:cEstatus)
       oEpson:lError:=.F.
       LOOP
    ENDIF

    EXIT

  ENDDO

  IF !Empty(oEpson:cEstatus) .AND. !oDp:lImpFisModVal
     oEpson:IFCLOSE()
     RETURN .F.
  ENDIF

  // ,CCG_NOMBRE,CCG_RIF,CCG_DIR1,CCG_TEL1,"+;

  cSql:=" SELECT MOV_ASOTIP,MOV_ASODOC,MOV_FCHVEN,MOV_DOCUME,MOV_CODIGO,INV_DESCRI,MOV_TOTAL,DOC_OTROS,DOC_DCTO,MOV_PRECIO,MOV_DESCUE,MOV_CANTID,MOV_IVA,"+;
        " DOC_IMPRES,SFI_SERIMP,MOV_LISTA,TPP_INCIVA,"+;
        " IF(DOC_CODIGO"+GetWhere("=","0000000000")+",DPCLIENTESCERO.CCG_RIF   ,DPCLIENTES.CLI_RIF   ) AS  CCG_RIF    ,"+;
        " IF(DOC_CODIGO"+GetWhere("=","0000000000")+",DPCLIENTESCERO.CCG_NOMBRE,DPCLIENTES.CLI_NOMBRE) AS  CCG_NOMBRE ,"+;
        " IF(DOC_CODIGO"+GetWhere("=","0000000000")+",DPCLIENTESCERO.CCG_DIR1  ,DPCLIENTES.CLI_DIR1  ) AS  CCG_DIR1   ,"+;
        " IF(DOC_CODIGO"+GetWhere("=","0000000000")+",DPCLIENTESCERO.CCG_TEL1  ,DPCLIENTES.CLI_TEL1  ) AS  CCG_TEL1    "+;
        " FROM DPMOVINV "+;
        " INNER JOIN DPINV ON MOV_CODIGO=INV_CODIGO "+;
        " INNER JOIN DPDOCCLI       ON MOV_CODSUC=DOC_CODSUC AND MOV_TIPDOC=DOC_TIPDOC AND DOC_NUMERO=MOV_DOCUME AND DOC_TIPTRA='D'"+;
        " LEFT  JOIN DPSERIEFISCAL  ON DOC_SERFIS=SFI_LETRA  "+;
        " LEFT  JOIN DPCLIENTES     ON DOC_CODIGO=CLI_CODIGO "+;
        " LEFT  JOIN DPCLIENTESCERO ON CCG_CODSUC=DOC_CODSUC AND CCG_TIPDOC=DOC_TIPDOC AND CCG_NUMDOC=DOC_NUMERO "+;
        " LEFT  JOIN DPPRECIOTIP    ON MOV_LISTA=TPP_CODIGO "+;
        " WHERE MOV_CODSUC"+GetWhere("=",oDp:cSucursal)+;
        " AND   MOV_TIPDOC"+GetWhere("=",cTipDoc      )+;
        " AND   MOV_DOCUME"+GetWhere("=",cNumero      )+;
        " AND   MOV_INVACT=1 " +;
        " GROUP BY MOV_ITEM "+;
        " ORDER BY MOV_ITEM "

   oTable:=OpenTable(cSql,.T.)

   SysRefresh(.T.)

   dpwrite("TEMP\"+cTipDoc+cNumero+".SQL",oDp:cSql)

   IF oTable:RecCount()=0
      MsgMemo("Documento sin Productos, ver Archivo: TEMP\"+cTipDoc+cNumero+CRLF+cSql)
      CLPCOPY(oDp:cSql)
      oTable:End()
      RETURN .F.
   ENDIF

   IF ValType(oTable:DOC_IMPRES)="L" .AND. oTable:DOC_IMPRES
      MsgMemo("Número Fiscal "+cNumero+" ya fué impreso")
      oTable:End()
      RETURN .F.
   ENDIF

   // Serie Fiscal esta almacenada en DPSERFISCAL
   cMaqui  := ALLTRIM(PADR(oTable:SFI_SERIMP   ,10))
   cNombre := ALLTRIM(PADR(oTable:CCG_NOMBRE,35))
   cRif    := ALLTRIM(PADR(oTable:CCG_RIF   ,12))
   cDir1   := ALLTRIM(PADR(oTable:CCG_DIR1  ,15))
   cTel1   := ALLTRIM(PADR(oTable:CCG_TEL1  ,12))
   cNumFav := ALLTRIM(PADR(oTable:MOV_DOCUME,10))

   oEpson:IFABREFISCAL()
   oTable:Gotop()

   WHILE !oTable:Eof()

     IF oTable:Eof()
        EXIT
     ENDIF

     cCant     :=ALLTRIM(TRANSFORM(oTable:MOV_CANTID,"999999.999"))
     cPrecio   :=ALLTRIM(TRANSFORM(oTable:MOV_PRECIO,cPicture))

     // Si el precio tiene IVA incluido, el precio será la Base Imponible JN 23/11/2022 
     IF oTable:TPP_INCIVA
       nIva   :=1+(oTable:MOV_IVA/100)
       cPrecio:=ALLTRIM(TRANSFORM((oTable:MOV_TOTAL/oTable:MOV_CANTID)/nIva,cPicture))
     ENDIF

     cDescri   :=ALLTRIM(PADR(oTable:INV_DESCRI,20))

     // Origen de Cuotas (Club,Colegios,Agremiados), la descripción incluye la fecha del Servicio
     IF oTable:MOV_ASOTIP="CUO" .AND. !Empty(oTable:MOV_FCHVEN)
        cDescri:=PADR(oTable:INV_DESCRI,20-6)+"-"+UPPER(LEFT(CMES(oTable:MOV_FCHVEN),3))+RIGHT(LSTR(YEAR(oTable:MOV_FCHVEN),4),2)
     ENDIF

     cAlicuota :=STRZERO(oTable:MOV_IVA*100,4)

     oEpson:IFRENGLON()

     oTable:DbSkip()

     SysRefresh(.T.)

  ENDDO

  oTable:End()

  oEpson:IFPRINT()

  // Luego de Imprimir Obtenemos el número para Almacenarlo en campo DOC_NUMFIS
  // JN 05/02/2023, Validar con impresora física para dejarlo en producción   
  cNumFis:=oEpson:IFPFULTIMO("10") 
  oEpson:IFCLOSE()

//  IF oEpson:lError
//    MsgMemo(MemoRead(cFileLog))
//  ENDIF

  IF oEpson:lError .OR. oDp:lImpFisRegAud
     lSave:=.T.
  ENDIF

  cTipo:=IF(oEpson:lError,"NIMP","RAUD")

  IF lSave

    cMemo:=MemoRead(cFileLog)+CRLF+cSql

    AUDITAR(cTipo , NIL ,"DPDOCCLI" , cTipDoc+cNumero )

    nNumero:=SQLINCREMENTAL("DPAUDITOR","AUD_NUMERO","AUD_SCLAVE"+GetWhere("=","DLL_EPSON"))
    oTable:=OpenTable("SELECT * FROM DPAUDITOR",.F.)
    oTable:Append()
    oTable:Replace("AUD_FECHAS",oDp:dFecha   )
    oTable:Replace("AUD_FECHAO",DPFECHA()    )
    oTable:Replace("AUD_HORA  ",HORA_AP()    )
    oTable:Replace("AUD_TABLA ","DPDOCCLI"   )
    oTable:Replace("AUD_CLAVE ",cCodSuc+cTipDoc+cNumero)
    oTable:Replace("AUD_USUARI",oDp:cUsuario )
    oTable:Replace("AUD_ESTACI",oDp:cPcName  )
    oTable:Replace("AUD_IP"    ,oDp:cIpLocal )
    oTable:Replace("AUD_TIPO"  ,cTipo        ) // No impreso/Anulado
    oTable:Replace("AUD_MEMO"  ,cMemo        )
    oTable:Replace("AUD_SCLAVE","DLL_EPSON"  )
    oTable:Replace("AUD_NUMERO",nNumero      )
    oTable:Commit()
    oTable:End(.T.)

  ENDIF

  IF oDp:lImpFisModVal .OR. oEpson:lError
    VIEWRTF(cFileLog,"Documento "+cTipDoc+cNumero)
  ELSE
    SQLUPDATE("DPDOCCLI",{"DOC_NUMPER","DOC_IMPRES","DOC_NUMFIS"},{oEpson:IFESTATUS(),.T.,cNumFis},cWhere) // Estatus Impresora
  ENDIF

  SysRefresh(.T.)

RETURN .T.

/*
// Apertura del Puerto
*/
FUNCTION IFOPEN(cPort)
  LOCAL cResp:=oEpson:PFRUNCMD("PFabrepuerto",cPuerto)
RETURN .T.

/*
// Mostrar el Estatu de la Impresora
*/
FUNCTION IFSHOWSTARTUS()
   MsgMemo(oEpson:cEstatus)
RETURN .T.

/*
// Apertura del Encabezado
*/
FUNCTION IFABREFISCAL()
  LOCAL cResp
  LOCAL cLinea1,cLinea2,cLinea3,cLinea4 

  IF cTipDoc = "TIK" .OR. cTipDoc="FAV"

    cResp:=oEpson:PFRUNCMD("PFabrefiscal",cNombre,cRif)
    cLinea1:="Nro. Documento:  "+cNumFav
    cLinea2:="DIRECCION:  "+cDIR1
    cLinea3:="TELEFONO:  "+cTel1
    cLinea4:=REPLI("-",80) // ---------------------------------------"
    cResp:=oEpson:PFRUNCMD("PFTfiscal",cLinea1) 
    cResp:=oEpson:PFRUNCMD("PFTfiscal",cLinea2) 
    cResp:=oEpson:PFRUNCMD("PFTfiscal",cLinea3) 
    cResp:=oEpson:PFRUNCMD("PFTfiscal",cLinea4)

 ENDIF

 IF cTipDoc = "DEV" .OR. cTipDoc = "CRE"

    cResp:=oEpson:PFRUNCMD("PFDevolucion",cNombre,cRIF,cNumFav,cMaqui,DTOC(DATE()),TIME())
    cLinea1:="Nro. Documento:  "+cNumFav
    cLinea2:="DIRECCION:  "+cDIR1
    cLinea3:="TELEFONO:  "+cTel1
    cLinea4:=REPLI("-",80) // "----------------------------------------"
    cResp:=oEpson:PFRUNCMD("PFTfiscal",cLinea1) 
    cResp:=oEpson:PFRUNCMD("PFTfiscal",cLinea2) 
    cResp:=oEpson:PFRUNCMD("PFTfiscal",cLinea3) 
    cResp:=oEpson:PFRUNCMD("PFTfiscal",cLinea4)

 ENDIF
 
RETURN .T.

FUNCTION IFTEXTOFISCAL()   
RETURN oEpson:PFRUNCMD("PFTfiscal","") 

/*
// Imprime el cuerpo de la factura
*/

FUNCTION IFRENGLON()   
  LOCAL cResp  
  cResp:=oEpson:PFRUNCMD("PFrenglon",cDescri,cCant,cPrecio,cAlicuota) 
RETURN cResp

/*
// Cancela Documento Fiscal
*/
FUNCTION IFCANCELADOC()
  cResp:=oEpson:PFRUNCMD("PFCancelaDoc","C","0")
RETURN cResp

/*
// Obtiene el Estatus de la Impresora
*/
FUNCTION IFESTATUS()
  LOCAL cResp

  cResp:=oEpson:PFRUNCMD("PFestatus","")

  oEpson:cEstatus:=""

  IF cResp = "TO"
     oEpson:cEstatus:="Se excedió el tiempo de espera,"
     oEpson:lError:=.T.
  ENDIF

  IF cResp = "NP"
     oEpson:cEstatus:="Puerto no Abierto"
     oEpson:lError:=.T.
  ENDIF

  IF cResp = "ER"
     oEpson:cEstatus:="Existe un Error de Impresora"
     oEpson:lError:=.T.
  ENDIF

RETURN cResp

/*
// Cortar el Papel
*/
FUNCTION IFCUTPAPER()
  LOCAL cResp 
  cResp:=oEpson:PFRUNCMD("PFCortar","")
RETURN 

/*
// Totalizador
*/
FUNCTION IFPRINT()
  LOCAL cResp,cMonto:=""

  IF nDivisa>0 
    cMonto:="E|U|"+LSTR(nDivisa*100,10,0)
    cResp :=oEpson:PFRUNCMD("PFComando",cMonto)
  ELSE
    cMonto:="E|U|000"
    cResp :=oEpson:PFRUNCMD("PFComando",cMonto)
  ENDIF

RETURN .T.

/*
// Ejecuta llamadas de las Funciones de la Impresora Epson
*/
FUNCTION PFRUNCMD(cFunc,cPar1,cPar2,cPar3,cPar4,cPar5,cPar6,cPar7,cPar8,cPar9)   
  LOCAL uResult:="", cFarProc, hDLL:=oEpson:hDll      

  IF !oDp:lImpFisModVal
    cFarProc:= GetProcAddress(hDLL,cFunc,.T.,8,8,8,8,8,8,8,8,8,8 )     
    uResult := CallDLL(cFarProc,cPar1,cPar2,cPar3,cPar4,cPar5,cPar6,cPar7,cPar8,cPar9)  
  ENDIF

  IF ValType(uResult)="C" .AND. uResult="ER"
    oEpson:lError:=.T.
  ENDIF

  DEFAULT cPar1:="",cPar2:="",cPar3:="",cPar4:="",cPar5:="",cPar6:="",cPar7:="",cPar8:="",cPar9:=""

  oEpson:oFile:AppStr(cFunc+",1->"+cPar1+",2->"+cPar2+",3->"+cPar3+",->"+cPar4+;
                            ",5->"+cPar5+",6->"+cPar6+",7->"+cPar7+",->"+cPar8+;
                            ",9->"+cPar9+",Result->"+CTOO(uResult,"C")+CRLF)

  SysRefresh(.T.)

RETURN uResult

/*
// Cierra la Conexión con la Impresora
*/
FUNCTION IFCLOSE()

   oEpson:PFRUNCMD("PFcierrapuerto","")

   oEpson:IFCERRARDLL()
   IF !oEpson:oFile=NIL
     oEpson:oFile:Close()
   ENDIF

RETURN 

/*
// Obtiene ultimos Valores de la Impresora
PFultimo: 0000,0000,44,00,45,200312,143427,0035,0000,00053574,00000662,0815
Campo 1 Estado Impresora <0000>
Campo 2 Estado Fiscal <0000>
Campo 3 Ultimo valor de Secuencia
Campo 4 Código del Estado actual de la impresora
Campo 5 Código último comando ejecutado
Campo 6 Fecha en la Impresora Fiscal “AAMMDD”
Campo 7 Hora en la Impresora Fiscal “HHMMSS”
Campo 8 Número Factura fiscal del periodo fiscal
Campo 9 Número Documento no Fiscal del periodo fiscal
Campo 10 Número Factura fiscal acumulado
Campo 11 Número Documento no Fiscal acumulado
Campo 12 Número último reporte Z
*/
FUNCTION IFPFULTIMO(cPar1)
  LOCAL cResp

  cResp:=oEpson:PFRUNCMD("PFultimo",cPar1)

RETURN cResp


/*
// Cerrar el Archivo pnpdll.dll
*/
FUNCTION IFCERRARDLL()

  FreeLibrary(oEpson:hDLL ) 
  oEpson:hDLL:=NIL

RETURN .T.
// EOF
