// Programa   : DLL_BEMATECH_PAGOS             
// Fecha/Hora : 09/11/2022 22:37:59
// Prop�sito  : Obtiene los datos del Pago 
// Creado Por : Juan Navas, SAMSUNG_DLL
// Llamado por:
// Aplicaci�n :
// Tabla      :

#INCLUDE "DPXBASE.CH"

PROCE MAIN(cCodSuc,cTipDoc,cNumero)
  LOCAL cWhere,cSql,cRecibo,aData:={},aBancos:={}

  DEFAULT cCodSuc:=oDp:cSucursal,;
          cTipDoc:="TIK",;
          cNumero:=SQLGETMAX("DPDOCCLI","DOC_NUMERO","DOC_CODSUC"+GetWhere("=",cCodSuc)+" AND DOC_TIPDOC"+GetWhere("=",cTipDoc))

  cWhere:="DOC_CODSUC"+GetWhere("=",cCodSuc)+" AND "+;
          "DOC_TIPDOC"+GetWhere("=",cTipDoc)+" AND "+;
          "DOC_NUMERO"+GetWhere("=",cNumero)+" AND "+;
          "DOC_TIPTRA"+GetWhere("=","P"    )

  cRecibo:=SQLGET("DPDOCCLI","DOC_RECNUM",cWhere)

  IF !Empty(cRecibo)

    cWhere:="CAJ_CODSUC"+GetWhere("=",cCodSuc)+" AND "+;
            "CAJ_ORIGEN"+GetWhere("=","REC"  )+" AND "+;
            "CAJ_DOCASO"+GetWhere("=",cRecibo)+" AND "+;
            "CAJ_ACT=1 "

  ELSE

    cWhere:="CAJ_CODSUC"+GetWhere("=",cCodSuc)+" AND "+;
            "CAJ_ORIGEN"+GetWhere("=",cTipDoc)+" AND "+;
            "CAJ_NUMERO"+GetWhere("=",cNumero)+" AND "+;
            "CAJ_ACT=1 "

  ENDIF

  cWhere:=cWhere+" AND CAJ_MTODIV=0"

  cSql :=" SELECT ICJ_NOMBRE,"+CRLF+;
         " SUM(CAJ_MONTO) AS CAJ_MONTO "+CRLF+;
         " FROM DPCAJAMOV "+CRLF+;
         " LEFT JOIN DPCAJAINST ON ICJ_CODIGO=CAJ_TIPO "+CRLF+;
         " WHERE "+cWhere+CRLF+;
         " GROUP BY ICJ_NOMBRE"

  aData:=ASQL(cSql)

  oDp:cImpFiscalSqlPagos:=oDp:cSql

  /*
  // pago con Bancos
  */

  cSql:=[ SELECT TDB_NOMBRE,SUM(MOB_MONTO) AS MOB_MONTO ]+;
        [ FROM dpctabancomov ]+;
        [ LEFT JOIN dpbancotip ON TDB_CODIGO=MOB_TIPO ]+;
        [ WHERE MOB_CODSUC]+GetWhere("=",cCodSuc)+;
        [   AND MOB_ORIGEN]+GetWhere("=","REC"  )+;
        [   AND MOB_DOCASO]+GetWhere("=",cRecibo)+;
        [   AND MOB_ACT=1 ]+;
        [ GROUP BY TDB_NOMBRE ]

  aBancos:=ASQL(cSql)

  AEVAL(aBancos,{|a,n| AADD(aData,a)})

  oDp:cImpFiscalSqlPagos:=oDp:cImpFiscalSqlPagos+CRLF+oDp:cSql

RETURN aData
// EOF

