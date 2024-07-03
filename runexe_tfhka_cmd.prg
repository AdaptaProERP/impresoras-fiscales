// Programa   : RUNEXE_TFHKA_CMD
// Fecha/Hora : 00/00/0000 00:00:00
// Propósito  : Ejecución de Comandos
// Creado Por : Juan Navas/ Kelvis Escalante	
// Llamado por: DPDOCCLI_PRINT      
// Aplicación : Forma Fiscal
// Tabla      : DPDOCCLI
// Fecha/Hora : 01/09/2022 00:00:00

#INCLUDE "DPXBASE.CH"

PROCE MAIN(cCmd,cOption,cSerie)
   LOCAL oSerFis,cRun,cMemoLog,lResp
   LOCAL cDir    :=CURDRIVE()+":"+"\"+"IntTFHKA"+"\",cCurDir:=CURDRIVE()+":\"+CURDIR()
   LOCAL cFileLog:=cDir+"STATUS_TFHK_"+LSTR(SECONDS())+".TXT"
   LOCAL nMemo   :=0,oTable,cTipo,nNumero
   LOCAL cFile

   DEFAULT cSerie :=SQLGET("DPSERIEFISCAL","SFI_LETRA","SFI_IMPFIS"+GetWhere("=","TFHKA")),;
           cOption:="REPORTEZ"

   IF Empty(oDp:cImpFisCom)
      oDp:cImpFisCom:=SQLGET("DPSERIEFISCAL","SFI_PUERTO","SFI_LETRA"+GetWhere("=",cSerie))
   ENDIF

   CursorWait()

   DPWRITE(cDir+"PUERTO.DAT",oDp:cImpFisCom)
   DPWRITE(cDir+"PUERTO.TXT",oDp:cImpFisCom)

   IF !Empty(cOption) .AND. Empty(cCmd)
      cCmd:=IF("Z"$UPPER(cOption),"UploadReportCmd(I0Z)",cCmd)
      cCmd:=IF("X"$UPPER(cOption),"SendCmd(I0X)"        ,cCmd)
   ENDIF

   /*
   // Concluir con pago
   */
// IF cOption="CERRARVTA"
//    cCmd:="3"
// ENDIF

   IF cCmd="STATUS"
      cCmd:="ReadFpStatus() "
   ENDIF

   cRun:="CD\INTTFHKA "+CRLF+;
         "IntTFHKA.EXE ReadFpStatus() > "+cFileLog

   FERASE(cFileLog)

   IF FILE(cFilelog)
      CLPCOPY(cRun)
      MsgMemo("Archivo "+cFileLog+" esta siendo Utilizado por Otro Proceso"+CRLF+cRun,"Comando ReadFpStatus() ")
      RETURN .F.
   ENDIF

   DPWRITE("RUN_TFHKA.BAT",cRun)
   CURSORWAIT()

   IF !oDp:lImpFisModVal
      WAITRUN("RUN_TFHKA.BAT",0)
   ENDIF

   IF !FILE(cFileLog) .AND. !oDp:lImpFisModVal
      MsgMemo("Impresora Apagada o no conectada "+CRLF+"No generó Archivo "+cFileLog,"Sin respuesta "+cCmd)
      RETURN .T.
   ENDIF

   cMemoLog:=MemoRead(cFileLog)

   oDp:cMemoLog:=cMemoLog

   IF (cCmd="ReadFpStatus()" .AND.  ("TRUE"$cMemoLog)) .OR. (cCmd="ReadFpStatus()" .AND. Empty(cMemoLog) .AND. FILE(cFileLog))
      RETURN .T.
   ENDIF

   IF "NO FUE"$UPPER(cMemoLog)
      MsgMemo(cMemoLog,"ReadFpStatus() "+oDp:cImpFiscal+" Puerto "+oDp:cImpFisCom)
      RETURN .F.
   ENDIF

   FERASE(cFileLog)

   cFileLog:=cDir+"STATUS_TFHK_"+LSTR(SECONDS())+".TXT"

   oDp:cFileLog:=cFileLog
 
   cRun:="CD\INTTFHKA "+CRLF+;
          "IntTFHKA.EXE "+cCmd+" > "+cFileLog

   FERASE(cFileLog)

   IF FILE(cFilelog)
      CLPCOPY(cRun)
      MsgMemo("Archivo "+cFileLog+" esta siendo Utilizado por Otro Proceso",cRun)
      RETURN .F.
   ENDIF

   DPWRITE("RUN_TFHKA.BAT",cRun)
   CURSORWAIT()

   IF !oDp:lImpFisModVal
      MsgRun("Imprimiendo "+cCmd,"Por Favor Espere "+cOption,{||WAITRUN("RUN_TFHKA.BAT",0)})
   ENDIF

   //  MsgRun("Imprimiendo "+cCmd,"Por Favor Espere "+cOption,{||WAITRUN(cRun,0)})
   cMemoLog:=MemoRead(cFileLog)

   cTipo   :="CMD"
   cTipo   :=IF("Z)"$cCmd,"REPZ",cTipo)
   cTipo   :=IF("X)"$cCmd,"REPX",cTipo)

   IF .T.

    IF oDp:lImpFisModVal
       cMemoLog:=cMemoLog
    ENDIF

    nNumero:=SQLINCREMENTAL("DPAUDITOR","AUD_NUMERO","AUD_SCLAVE"+GetWhere("=","TFHK_EXE"))
    oTable:=OpenTable("SELECT * FROM DPAUDITOR",.F.)
    oTable:Append()
    oTable:Replace("AUD_TIPO"  ,"TIME"       )
    oTable:Replace("AUD_FECHAS",oDp:dFecha   )
    oTable:Replace("AUD_FECHAO",DPFECHA()    )
    oTable:Replace("AUD_HORA  ",HORA_AP()    )
    oTable:Replace("AUD_TABLA ","DPSERFISCAL")
    oTable:Replace("AUD_CLAVE ",cCmd )
    oTable:Replace("AUD_USUARI",oDp:cUsuario )
    oTable:Replace("AUD_ESTACI",oDp:cPcName  )
    oTable:Replace("AUD_IP"    ,oDp:cIpLocal )
    oTable:Replace("AUD_TIPO"  ,cTipo        )
    oTable:Replace("AUD_MEMO"  ,cMemoLog+CRLF+cRun+CRLF+cCmd)
    oTable:Replace("AUD_SCLAVE","TFHK_EXE"   )
    oTable:Replace("AUD_NUMERO",nNumero      )

    oTable:Commit()
    oTable:End(.T.)

    IF oDp:lImpFisModVal
       cFile:="TEMP\FILE"+cOption+".TXT"
       DPWRITE(cFile,oTable:AUD_MEMO)
       VIEWRTF(cFile,"Comando "+cOption)
    ENDIF

  ENDIF

  IF !ISPCPRG()
    FERASE(cFileLog)
  ENDIF

RETURN lResp
// EOF
