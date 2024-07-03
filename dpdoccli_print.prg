// Programa   : DPDOCCLI_PRINT
// Fecha/Hora : 13/09/2022 03:39:45
// Propósito  : Imprimir Documento del Cliente
// Creado Por : Juan Navas
// Llamado por:
// Aplicación :
// Tabla      :

#INCLUDE "DPXBASE.CH"

PROCE MAIN(cCodSuc,cTipDoc,cNumero,cSerFis,cImpFis)
   LOCAL cWhere,bBlq,oRep

   DEFAULT oDp:cImpFiscal:=""

   DEFAULT cCodSuc:=oDp:cSucursal,;
           cTipDoc:="FAV",;
           cNumero:=SQLGETMAX("DPDOCCLI","DOC_NUMERO","DOC_CODSUC"+GetWhere("=",cCodSuc)+" AND DOC_TIPDOC"+GetWhere("=",cTipDoc)),;
           cImpFis:=oDp:cImpFiscal

// ? cCodSuc,cTipDoc,cNumero,cSerFis,"cCodSuc,cTipDoc,cNumero,cSerFis,DPDOCCLI_PRINT"
  
   IF Empty(cSerFis)

      cWhere:="DOC_CODSUC"+GetWhere("=",cCodSuc)+" AND "+;
              "DOC_TIPDOC"+GetWhere("=",cTipDoc)+" AND "+;
              "DOC_NUMERO"+GetWhere("=",cNumero)+" AND "+;
              "DOC_TIPTRA"+GetWhere("=","D"    )

	 cSerFis:=SQLGET("DPDOCCLI","DOC_SERFIS",cWhere)

   ENDIF

   DEFAULT oDp:cImpFiscal:="",;
           oDp:lImpFisModVal:=.F.

// ? cSerFis,cImpFis,"cSerFis,cImpFis"

   IF Empty(cImpFis)
      // oDp:cImpFiscal) 
      oDp:cImpFiscal   :=SQLGET("DPSERIEFISCAL","SFI_IMPFIS,SFI_PUERTO,SFI_MODVAL,SFI_PAGADO","SFI_LETRA"+GetWhere("=",cSerFis))
      oDp:cImpFisCom   :=DPSQLROW(2,"" )
      oDp:lImpFisModVal:=DPSQLROW(3,.F.)
      oDp:lImpFisPago  :=DPSQLROW(4,.F.) // Imprimir si esta pagado
   ENDIF

//   ? oDp:cImpFiscal,"oDp:cImpFiscal",cImpFis,"<-cImpFis"

   IF Empty(oDp:cImpFiscal) .OR. "NINGUNA"$UPPER(oDp:cImpFiscal)

      cWhere:="DOC_CODSUC"+GetWhere("=",cCodSuc)+" AND "+;
              "DOC_TIPDOC"+GetWhere("=",cTipDoc)+" AND "+;
              "DOC_NUMERO"+GetWhere("=",cNumero)+" AND "+;
              "DOC_TIPTRA"+GetWhere("=","D"    )

      IF !Empty(cNumero)

        oDp:cDocNumIni:=cNumero
        oDp:cDocNumFin:=cNumero

        oRep:=REPORTE("DOCCLI"+cTipDoc,cWhere)
        oRep:SetRango(1,cNumero,cNumero)

      ELSE

        oDp:cDocNumIni:=oDpCliMnu:cNumero
        oDp:cDocNumFin:=oDpCliMnu:cNumero
        REPORTE("DOCCLI"+cTipDoc,cWhere)

      ENDIF

      oDp:oGenRep:aCargo:=cTipDoc

      bBlq:=[SQLUPDATE("DPDOCCLI","DOC_IMPRES",.T.,"]+cWhere+[")]

      oDp:oGenRep:bPostRun:=BLOQUECOD(bBlq) 

      RETURN .F.

   ENDIF

   IF "EPSON"$UPPE(oDp:cImpFiscal) 
      EJECUTAR("DLL_EPSON",cTipDoc,cNumero)
      RETURN .T.
   ENDIF

   IF "BEMATECH"$UPPE(oDp:cImpFiscal) 
      EJECUTAR("DLL_BEMATECH",cCodSuc,cTipDoc,cNumero)
      RETURN .T.
   ENDIF

   IF "TFHK_EXE"$ALLTRIM(UPPE(oDp:cImpFiscal))
      EJECUTAR("RUNEXE_TFHKA",cCodSuc,cTipDoc,cNumero)
      RETURN .T.
   ENDIF

   IF "TFHK_DLL"=ALLTRIM(UPPE(oDp:cImpFiscal))
      EJECUTAR("DLL_TFH",cCodSuc,cTipDoc,cNumero)
      RETURN .T.
   ENDIF

RETURN .F.
// EOF
