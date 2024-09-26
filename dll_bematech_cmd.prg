// Programa   : DLL_BEMATECH_CMD
// Fecha/Hora : 24/06/2024 12:54:03
// Propósito  : Devuelve Ultimo Número de Factura
// Creado Por : Juan Navas
// Llamado por:
// Aplicación :
// Tabla      :

#INCLUDE "DPXBASE.CH"

PROCE MAIN(cCmd,cOption,cLetra,lShow,lMsgErr,lBrowse)
   LOCAL cResp:=NIL,oTable,nNumero,cMemoLog:="",cTipo:=""
   LOCAL lRunCmd:=.F.,oMemo,cFileLog

   DEFAULT cCmd   :="Z",;
           cOption:="Reporte Z",;
           lShow  :=.F.,;
           cLetra :=oDp:cImpLetra,;
           lMsgErr:=.T.,;
           lBrowse:=.F.


   // ? cCmd,"<-cCmd",cOption,cLetra,lShow,lMsgErr,lBrowse,"cCmd,cOption,cLetra,lShow,lMsgErr,lBrowse"

   cFileLog:="TEMP\bematech_"+cCmd+".LOG"

   IF cCmd=="Z" .OR. "Z"$UPPER(cCmd) .OR. "Z"$UPPER(cOption)
      cTipo  :="REPZ"
      lRunCmd:=.T.
      cResp  :=EJECUTAR("DLL_BEMATECH_Z",cLetra)
   ENDIF

   IF (cCmd=="X" .OR. "X"$UPPER(cCmd) .OR. "X"$UPPER(cOption)) .AND. !lRunCmd
      cResp  :=EJECUTAR("DLL_BEMATECH_X")
      cTipo  :="REPX"
      lRunCmd:=.T.
   ENDIF

   /*
   // Ejecuta comando 
   */
   IF !lRunCmd
     cTipo  :="CMD"
     EJECUTAR("DLL_BEMATECH",NIL,NIL,NIL,lMsgErr,lShow,lBrowse,cCmd,oMemo)
   ENDIF

   IF lRunCmd

     //  cMemoLog:=MEMOREAD(cFileLog)
     SysRefresh(.T.)

     nNumero:=SQLINCREMENTAL("DPAUDITOR","AUD_NUMERO","AUD_SCLAVE"+GetWhere("=","DLL_BEMATECH"))
     oTable:=OpenTable("SELECT * FROM DPAUDITOR",.F.)  
     oTable:Append()
     oTable:lAuditar:=.F.
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
     oTable:Replace("AUD_SCLAVE","BEMATECH"   )
     oTable:Replace("AUD_NUMERO",nNumero      )
     oTable:Commit()
     oTable:End()

  ENDIF

RETURN cResp
// EOF


