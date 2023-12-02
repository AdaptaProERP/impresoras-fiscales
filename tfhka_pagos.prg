// Programa   : TFHKA_PAGOS             
// Fecha/Hora : 09/11/2022 22:37:59
// Propósito  : Obtiene los datos del Pago 
// Creado Por : Juan Navas, SAMSUNG_DLL
// Llamado por:
// Aplicación :
// Tabla      :

#INCLUDE "DPXBASE.CH"

PROCE MAIN(cCodSuc,cTipDoc,cNumero)
  LOCAL cWhere,cSql,cRecibo,aData:={},cMonto,nLen
  LOCAL oTable

  DEFAULT cCodSuc:=oDp:cSucursal,;
          cTipDoc:="TIK",;
          cNumero:=SQLGETMAX("DPDOCCLI","DOC_NUMERO","DOC_CODSUC"+GetWhere("=",cCodSuc)+" AND DOC_TIPDOC"+GetWhere("=",cTipDoc))

  nLen:=oDp:nImpFisEnt  // Definible Ancho Numérico
  nLen:=IF(nLen=0,13,nLen) 

  cWhere:="DOC_CODSUC"+GetWhere("=",cCodSuc)+" AND "+;
          "DOC_TIPDOC"+GetWhere("=",cTipDoc)+" AND "+;
          "DOC_NUMERO"+GetWhere("=",cNumero)+" AND "+;
          "DOC_TIPTRA"+GetWhere("=","P")

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

/*
  cSql :=" SELECT CAJ_TIPO,ICJ_CODMON,ICJ_TRAMAIF,"+;
         " SUM(IF(CAJ_MTODIV>0,CAJ_MONTO,0)) AS CAJ_MTODIV,"+;
         " SUM(CAJ_MTOITF) AS CAJ_MTOITF,"+;
         " SUM(IF(CAJ_MTODIV=0,CAJ_MONTO,0)) AS CAJ_MONTO "+;
         " FROM DPCAJAMOV "+;
         " LEFT JOIN DPCAJAINST ON ICJ_CODIGO=CAJ_TIPO "+;
         " WHERE "+cWhere+;
         " GROUP BY CAJ_TIPO,ICJ_CODMON,ICJ_TRAMAIF"

*/

 // 20/11/2022
 // PAGO DUAL BS Y USD
 cSql :=" SELECT ICJ_TRAMAIF,"+CRLF+;
        " SUM(IF(CAJ_MTODIV>0,CAJ_MONTO,0)) AS CAJ_MTODIV,"+CRLF+;
        " SUM(CAJ_MTOITF) AS CAJ_MTOITF,"+CRLF+;
        " SUM(IF(CAJ_MTODIV=0,CAJ_MONTO,0)) AS CAJ_MONTO "+CRLF+;
        " FROM DPCAJAMOV "+CRLF+;
        " LEFT JOIN DPCAJAINST ON ICJ_CODIGO=CAJ_TIPO "+CRLF+;
        " WHERE "+cWhere+CRLF+;
        " GROUP BY ICJ_TRAMAIF"

  oTable:=OpenTable(cSql,.T.)

  oDp:cImpFiscalSqlPagos:=oDp:cSql


  // Caso de contribuyente especial, aunque el cliente le pague en Divisa no puede cobrar el IGTF, la impresora le generará error

  // Rellenar las formas de pago, 01 es Bs y 20 es Dólares
  WHILE !oTable:EOF() 

      IF Empty(oTable:ICJ_TRAMAIF) .AND. oTable:CAJ_MTODIV=0 
         oTable:Replace("ICJ_TRAMAIF","01")
      ENDIF

      IF Empty(oTable:ICJ_TRAMAIF) .AND. oTable:CAJ_MTODIV>0 .AND. oTable:CAJ_MTOITF>0
         oTable:Replace("ICJ_TRAMAIF","20")
      ENDIF

      oTable:DbSkip()

  ENDDO

  oTable:GoTop()

//oTable:Browse()

  // Complemento de pago Parcial o Total
  IF oTable:RecCount()=1 
     oTable:Replace("ICJ_TRAMAIF","1"+oTable:ICJ_TRAMAIF)
  ENDIF

  // Todos son pagos parciales
  WHILE !oTable:EOF() .AND. oTable:RecCount()>1 
    oTable:Replace("ICJ_TRAMAIF","2"+oTable:ICJ_TRAMAIF)
    oTable:DbSkip()
  ENDDO

  oTable:GoTop()
  // Agregamos los Montos
  WHILE !oTable:EOF() .AND. oTable:RecCount()>1
    cMonto:=ALLTRIM(oTable:ICJ_TRAMAIF)+STRZERO(IF(oTable:CAJ_MTODIV=0,oTable:CAJ_MONTO,oTable:CAJ_MTODIV)*100,nLen,0)
    AADD(aData,cMonto)

    // Pago en Divisa una Parte, resto el Bs
    IF LEFT(cMonto,2)="22"
       AADD(aData,"101")
       EXIT
    ENDIF

    oTable:DbSkip()
  ENDDO

  oTable:Gotop()

  IF oTable:RecCount()=1 

     aData:={}
     // PAGO PARCIAL DUAL BS Y USD
     IF oTable:CAJ_MTODIV>0 .AND. oTable:CAJ_MONTO>0
        cMonto:="22"+STRZERO(oTable:CAJ_MTODIV*100,nLen,0)
        AADD(aData,cMonto)
        AADD(aData,"101")
     ENDIF

     // PAGO DIRECTO BS, SOLO CIERRA CON 101
     IF oTable:CAJ_MTODIV=0 .AND. oTable:CAJ_MONTO>0
        AADD(aData,"101")
     ENDI

     // PAGO DIRECTO DOLARES, CIERRA 120
     IF oTable:CAJ_MTODIV>0 .AND. oTable:CAJ_MONTO=0
        AADD(aData,"120")
     ENDIF
     
  ENDIF

  // en el caso de no tener forma de pago asume 101
  IF Empty(aData)
    AADD(aData,"101")
  ENDIF

  oTable:End()

  // ViewArray(aData)

RETURN aData
// EOF
