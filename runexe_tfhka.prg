// Programa   : RUNEXE_TFHKA
// Fecha/Hora : 00/00/0000 00:00:00
// Prop�sito  : Emision Ticket de venta fiscal para impresora HKA-80, Mediante programa binario: IntTFHKA.EXE
// Creado Por : Juan Navas/ Kelvis Escalante	
// Llamado por: DPDOCCLI_PRINT      
// Aplicaci�n : FACTURACION CONVENCIONAL Y PUNTO DE VENTA
// Tabla      : DPDOCCLI
// Fecha/Hora : 01/09/2022 00:00:00

/*
Implementaci�n impresora HK80 mediante programa RUNEXE_TFHKA  generando archivo TXT contentivo 
de las instrucciones de impresi�n para utilizar el programa binario IntTFHKA.exe "suministrado por THE FACTORY"
Llamado desde el programa DPDOCCLI_PRINT y este llamado desde DPFACTURAV y DPPOSPRINT 
En la serie fiscal, Debe seleccionar impresora TFHKA
*/

#INCLUDE "DPXBASE.CH"
#INCLUDE "FILEIO.CH"

PROCE MAIN(cCodSuc,cTipDoc,cNumero,cOption)
   LOCAL oTable
   LOCAL cWhere:="",cFile,cSql,cText:="",cSerie:=""
   LOCAL cFileOut,cMemoLog:="",lResp:=.F.,cResp
   LOCAL cDir    :="C:\IntTFHKA\",cCurDir:=CURDRIVE()+":\"+CURDIR(),cBatCall,cRun:=""
   LOCAL cFileFav:=cDir+"FACTURA.TXT"
   LOCAL cFileLog:=cDir+"STATUS_ERROR_"+LSTR(SECONDS())+".TXT"
   LOCAL aPagos  :={},nLen,oTable,nNumero,lSave:=.T.,cTipo:=""
   LOCAL cFilePag // log de pagos

   DEFAULT cCodSuc:=oDp:cSucursal,;
           cTipDoc:="TIK",;
           cNumero:=SQLGETMAX("DPDOCCLI","DOC_NUMERO","DOC_TIPDOC"+GetWhere("=",cTipDoc)),;
           cOption:="3"

   oDp:cImpFiscalSqlPagos:=""

   cWhere:="DOC_CODSUC"+GetWhere("=",cCodSuc)+" AND "+;
           "DOC_TIPDOC"+GetWhere("=",cTipDoc)+" AND "+;
           "DOC_NUMERO"+GetWhere("=",cNumero)+" AND "+;
           "DOC_ACT"   +GetWhere("=",1      )+" AND "+;
           "DOC_TIPTRA"+GetWhere("=","D"    )

   IF Empty(cSerie)
      cSerie:=SQLGET("DPDOCCLI","DOC_SERFIS",cWhere)
   ENDIF

   IF Empty(oDp:cImpFisCom)
      oDp:cImpFisCom:=SQLGET("DPSERIEFISCAL","SFI_PUERTO","SFI_LETRA"+GetWhere("=",cSerie))
   ENDIF

   IF Empty(oDp:cImpFisCom)
      MsgMemo("No tiene Puerto Serial")
   ENDIF

   CursorWait()

   IF !EJECUTAR("RUNEXE_TFHKA_STATUS",cSerie,.F.) 
    // QUITAR 07/12/2023
    //  RETURN .F.
   ENDIF

   cFileOut:=cCurDir+"\TEMP\"+cTipDoc+cNumero+"_OUT.LOG"

   IF !FILE(cDir+"IntTFHKA.exe")
      MsgMemo("Requiere Programa "+cDir+"IntTFHKA.exe")
      RETURN .F.
   ENDIF

   cFileFav:=cCurDir+"\TEMP\"+cTipDoc+cNumero+".txt"
   cFilePag:=cCurDir+"\TEMP\"+cTipDoc+cNumero+".pag"
   cText   :=EJECUTAR("TFHKA_DATA",cCodSuc,cTipDoc,cNumero,cOption)

   IF Empty(cText) .OR. ValType(cText)<>"C"
     MsgMemo("Data Vacia","ValType "+ValType(cText))
     RETURN .F.
   ENDIF

   cFile   :=cDir+cTipDoc+cNumero+".txt"

   ferase(cFileFav)

   IF FILE(cFileFav)
      MsgMemo("Archivo est� Abierto ","No se puede Generar")
      RETURN .F.
   ENDIF

   FERASE("RUN_TFHKA.BAT")

   IF FILE("RUN_TFHKA.BAT")
      MsgMemo("Archivo RUN_TFHKA.BAT ","No se puede Generar")
      RETURN .F.
   ENDIF

   DPWRITE(cFile   ,cText)
   DPWRITE(cFileFav,cText)
   DPWRITE(cDir+"FACTURA.TXT",cText) 

   cRun:="CD\INTTFHKA "+CRLF+;
        "IntTFHKA.EXE SendFileCmd("+cFile+") > "+cFileLog

   DPWRITE("RUN_TFHKA.BAT",cRun)

   cRun:="CD\INTTFHKA "+CRLF+;
        "IntTFHKA.EXE SendFileCmd(factura.txt)"

   DPWRITE(cDir+"FACTURA.BAT",cRun)

   CURSORWAIT()

   ferase(cFileLog)

   IF !oDp:lImpFisModVal
     MsgRun("Imprimiendo Ticket No.:"+cNumero,"Por Favor Espere",{||WAITRUN("RUN_TFHKA.BAT",0)  })
   ENDIF

   SysRefresh(.T.)

   cMemoLog:=MEMOREAD(cFileLog)

   cMemoLog:=MemoRead(cFileLog)
   cMemoLog:=STRTRAN(cMemoLog,CHR(13),"")
   cMemoLog:=STRTRAN(cMemoLog,CHR(10),"")
   cMemoLog:=ALLTRIM(cMemoLog)
   cResp   :=ALLTRIM(SUBS(cMemoLog,LEN(cMemoLog)-1))

   /*
   // 18/11/2022  Si cMemoLog est� vacio no tiene incidencia.
   */

   IF ("0"$cResp .OR. Empty(cMemoLog)) .AND. !oDp:lImpFisModVal

      SQLUPDATE("DPDOCCLI","DOC_IMPRES",.T.,cWhere)

      lSave   :=oDp:lImpFisRegAud 
      cTipo   :="RAUD"

      // Anulaci�n de Tickets
      IF cOption="7"
         cMemoLog:="Anulaci�n Documento Impreso"
         cTipo   :="DANU"
         lSave   :=.T.
      ENDIF

   ELSE

      // en el caso de ser NO impreso, debe actualizarlo en la pista de auditoria
      cMemoLog:=MemoRead(cFileLog)
      cWhere  :="AUD_CLAVE "+GetWhere("=",cCodSuc+cTipDoc+cNumero)+" AND "+;
                "AUD_SCLAVE"+GetWhere("=","TFHK_EXE")

      SQLUPDATE("DPAUDITOR","AUD_TIPO","SIMP",cWhere)

      IF !oDp:lImpFisModVal
         MsgMemo(cMemoLog+CRLF+"Revisar si la Impresora Tiene Papel","Error de Impresi�n "+cTipDoc+"-"+cNumero)
      ENDIF

      lSave:=.T.
      cTipo:="NIMP" // no Impreso

   ENDIF

   // Guardar
   IF lSave

      IF !Empty(oDp:cImpFiscalSqlPagos)
        OpenTable(oDp:cImpFiscalSqlPagos):CTOTXT(cFilePag)
      ENDIF

      nNumero:=SQLINCREMENTAL("DPAUDITOR","AUD_NUMERO","AUD_SCLAVE"+GetWhere("=","TFHK_EXE"))
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
      oTable:Replace("AUD_MEMO"  ,cMemoLog+CRLF+cText+CRLF+"FILE"+cFileLog+CRLF+cRun+CRLF+"PAGOS:"+cFilePag+CRLF+MemoRead(cFilePag)+CRLF+oDp:cImpFiscalSqlPagos) // Traza
      oTable:Replace("AUD_SCLAVE","TFHK_EXE"   )
      oTable:Replace("AUD_NUMERO",nNumero      )
      oTable:Commit()
      oTable:End(.T.)

      IF oDp:lImpFisModVal
         DPWRITE(cFile,oTable:AUD_MEMO)
      ENDIF

   ENDIF


   IF oDp:lImpFisModVal
      VIEWRTF(cFile,"Documento "+cTipDoc+cNumero)
   ENDIF

RETURN  .T.
// EOF
