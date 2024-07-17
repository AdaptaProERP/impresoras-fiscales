// Programa   : DLL_BEMATECH_CMD
// Fecha/Hora : 24/06/2024 12:54:03
// Propósito  : Devuelve Ultimo Número de Factura
// Creado Por : Juan Navas
// Llamado por:
// Aplicación :
// Tabla      :

#INCLUDE "DPXBASE.CH"

PROCE MAIN(cCmd,cOption,uValue,lShow,lMsgErr,lBrowse)
   LOCAL cResp:=NIL,oTable,nNumero,cMemoLog:="",cTipo:=""
   LOCAL lRunCmd:=.F.,oMemo

   DEFAULT cCmd   :="Z",;
           cOption:="Reporte Z",;
           lShow  :=.F.,;
           uValue :=NIL,;
           lMsgErr:=.T.,;
           lBrowse:=.F.


   cFileLog:="TEMP\bematech_"+cCmd+".LOG"

   IF cCmd=="Z"
      cTipo  :="REPZ"
      lRunCmd:=.T.
      cResp  :=EJECUTAR("DLL_BEMATECH_Z")
   ENDIF

   IF cCmd=="X"
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

     cMemoLog:=MEMOREAD(cFileLog)

     nNumero:=SQLINCREMENTAL("DPAUDITOR","AUD_NUMERO","AUD_SCLAVE"+GetWhere("=","DLL_BEMATECH"))
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
     oTable:Replace("AUD_SCLAVE","BEMATECH"   )
     oTable:Replace("AUD_NUMERO",nNumero      )
     oTable:Commit()
     oTable:End(.T.)

  ENDIF

RETURN cResp
// EOF


