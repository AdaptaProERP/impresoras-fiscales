// Programa   : DPDOCCLI_ANULAR
// Fecha/Hora : 16/11/2022 03:14:58
// Propósito  : Anular Factura Fiscal
// Creado Por : Juan Navas
// Llamado por:
// Aplicación :
// Tabla      :

#INCLUDE "DPXBASE.CH"

PROCE MAIN(cCodSuc,cTipDoc,cNumero,cSerFis)
   LOCAL lResp:=.F.
   LOCAL cWhere

   DEFAULT cCodSuc:=oDp:cSucursal,;
           cTipDoc:="FAV",;
           cNumero:=SQLGETMAX("DPDOCCLI","DOC_NUMERO","DOC_CODSUC"+GetWhere("=",cCodSuc)+" AND DOC_TIPDOC"+GetWhere("=",cTipDoc))

   IF Empty(cSerFis)

      cWhere:="DOC_CODSUC"+GetWhere("=",cCodSuc)+" AND "+;
              "DOC_TIPDOC"+GetWhere("=",cTipDoc)+" AND "+;
              "DOC_NUMERO"+GetWhere("=",cNumero)+" AND "+;
              "DOC_TIPTRA"+GetWhere("=","D"    )

	 cSerFis:=SQLGET("DPDOCCLI","DOC_SERFIS",cWhere)

   ENDIF

   DEFAULT oDp:cImpFiscal:=""

   CursorWait()

   IF Empty(oDp:cImpFiscal) 
      EJECUTAR("DPPOSLOAD")
      oDp:cImpFiscal:=SQLGET("DPSERIEFISCAL","SFI_IMPFIS,SFI_PUERTO","SFI_LETRA"+GetWhere("=",cSerFis))
      oDp:cImpFisCom:=DPSQLROW(2,"")
   ENDIF

   oDp:cImpFiscal:=UPPE(ALLTRIM(oDp:cImpFiscal))

   // ? cCodSuc,cTipDoc,cNumero,"oDp:cImpFiscal-",oDp:cImpFiscal
   // Anular TICKET

   IF "TFHK_EXE"$UPPE(oDp:cImpFiscal)
      lResp:=EJECUTAR("RUNEXE_TFHKA",cCodSuc,cTipDoc,cNumero,"7")
      RETURN 
   ENDIF

   // Anular TICKET
   IF "TFHK_DLL"==oDp:cImpFiscal
      lResp:=EJECUTAR("DLL_TFH",cCodSuc,cTipDoc,cNumero,"7")
   ENDIF

RETURN lResp
// EOF
