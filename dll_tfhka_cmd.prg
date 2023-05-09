// Programa   : DLL_TFHKA_CMD
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
   LOCAL cFileLog:=cDir+"STATUS_ERROR_"+LSTR(SECONDS())+".TXT"
   LOCAL nMemo   :=0,oTable,cTipo,nNumero

   DEFAULT cSerie :=SQLGET("DPSERIEFISCAL","SFI_LETRA","SFI_IMPFIS"+GetWhere("=","TFHKA")),;
           cOption:="RESET"

   IF Empty(oDp:cImpFisCom)
      oDp:cImpFisCom:=SQLGET("DPSERIEFISCAL","SFI_PUERTO","SFI_LETRA"+GetWhere("=",cSerie))
   ENDIF

   CursorWait()

   IF !Empty(cOption) .AND. Empty(cCmd)
      cCmd:=IF("Z"$UPPER(cOption),"Z",cCmd)
      cCmd:=IF("X"$UPPER(cOption),"X",cCmd)
      cCmd:=IF("RES"$UPPER(cOption),"7",cCmd)
   ENDIF

   cTipo   :="CMD"
   cTipo   :=IF("Z)"$cCmd,"REPZ",cTipo)
   cTipo   :=IF("X)"$cCmd,"REPX",cTipo)
   cTipo   :=IF("7)"$cCmd,"RESE",cTipo)

   EJECUTAR("DLL_TFH","","","","",cCmd)

   IF .T.

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
    oTable:Replace("AUD_MEMO"  ,cMemoLog     )
    oTable:Replace("AUD_SCLAVE","TFHK"      )
    oTable:Replace("AUD_NUMERO",nNumero      )

    oTable:Commit()
    oTable:End(.T.)

  ENDIF

  IF !ISPCPRG()
    FERASE(cFileLog)
  ENDIF

RETURN lResp
// EOF

