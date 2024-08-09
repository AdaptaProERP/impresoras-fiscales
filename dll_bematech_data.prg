// Programa   : DLL_BEMATECH_DATA        
// Fecha/Hora : 26/06/2024 11:02:03
// Propósito  : Devuelve Objeto Data
// Creado Por : Juan Navas
// Llamado por:
// Aplicación :
// Tabla      :

#INCLUDE "DPXBASE.CH"

PROCE MAIN(cCodSuc,cTipDoc,cNumero)
    LOCAL cSql,oTable


    DEFAULT cCodSuc:=oDp:cSucursal,;
            cTipDoc:="FAV",;
            cNumero:=SQLGETMAX("DPDOCCLI","DOC_NUMERO","DOC_CODSUC"+GetWhere("=",cCodSuc)+" AND DOC_TIPDOC"+GetWhere("=",cTipDoc)+" AND DOC_TIPTRA"+GetWhere("=","D"))

    cWhere:="DOC_CODSUC"+GetWhere("=",cCodSuc)+" AND "+;
            "DOC_TIPDOC"+GetWhere("=",cTipDoc)+" AND "+;
            "DOC_NUMERO"+GetWhere("=",cNumero)+" AND "+;
            "DOC_TIPTRA"+GetWhere("=","D"    )

   
  cSql:=" SELECT  MOV_DOCUME,DOC_FACAFE,DOC_IMPRES,MOV_CODIGO,INV_DESCRI,MOV_TOTAL,DOC_OTROS,DOC_DCTO,DOC_TIPDOC,MOV_PRECIO,MOV_DESCUE,MOV_CANTID,MOV_IVA,MOV_CODALM,"+;
        " DOC_NUMERO,CLI_NOMBRE,CLI_RIF,CLI_DIR1,CLI_TEL1,"+;
        " IF(DOC_CODIGO"+GetWhere("=","0000000000")+",DPCLIENTESCERO.CCG_RIF   ,DPCLIENTES.CLI_RIF   ) AS  CLI_RIF    ,"+;
        " IF(DOC_CODIGO"+GetWhere("=","0000000000")+",DPCLIENTESCERO.CCG_NOMBRE,DPCLIENTES.CLI_NOMBRE) AS  CLI_NOMBRE ,"+;
        " IF(DOC_CODIGO"+GetWhere("=","0000000000")+",DPCLIENTESCERO.CCG_DIR1  ,DPCLIENTES.CLI_DIR1  ) AS  CLI_DIR1   ,"+;
        " IF(DOC_CODIGO"+GetWhere("=","0000000000")+",DPCLIENTESCERO.CCG_TEL1  ,DPCLIENTES.CLI_TEL1  ) AS  CLI_TEL1   ,"+;
        " SFI_SERIMP,SFI_MEMO,SFI_MODVAL"+;
        " FROM DPMOVINV "+;
        " INNER JOIN DPINV ON MOV_CODIGO=INV_CODIGO "+;
        " INNER JOIN DPDOCCLI       ON MOV_CODSUC=DOC_CODSUC AND MOV_TIPDOC=DOC_TIPDOC AND DOC_NUMERO=MOV_DOCUME AND DOC_TIPTRA='D'"+;
        " LEFT  JOIN DPSERIEFISCAL  ON DOC_SERFIS=SFI_LETRA  "+;
        " LEFT  JOIN DPCLIENTES     ON DOC_CODIGO=CLI_CODIGO "+;
        " LEFT  JOIN DPCLIENTESCERO ON CCG_CODSUC=DOC_CODSUC AND CCG_TIPDOC=DOC_TIPDOC AND CCG_NUMDOC=DOC_NUMERO "+;
        " LEFT  JOIN DPPRECIOTIP    ON MOV_LISTA=TPP_CODIGO "+;
        " WHERE MOV_CODSUC"+GetWhere("=",cCodSuc)+;
        " AND   MOV_TIPDOC"+GetWhere("=",cTipDoc)+;
        " AND   MOV_DOCUME"+GetWhere("=",cNumero)+;
        " AND   MOV_INVACT=1 "+;
        " GROUP BY MOV_ITEM "+;
        " ORDER BY MOV_ITEM " 

  oTable:=OpenTable(cSql,.T.)

  oDp:lImpFisModVal:=oTable:SFI_MODVAL // 05/08/2024

RETURN oTable
// EOF
