// Programa   : DPPOS04
// Fecha/Hora : importtik01/09/2005
// Prop¾sito  : Operaciones de Venta
// Creado Por : Juan Navas
// Modificado : Marlon Ramos 28-05-2008 (Cuando se pagaba con Tarj. Cred. RepetÝa el pago en los siguientes tickets)
//                           02-06-2008 (Se redondea el iva para Evitar descuadres y se toma el descuento en el total)
//                           12-06-2008 (Reflejar el descuento total en pantalla)
//                           13-06-2008 (Evitar descuentos dobles)
//                           13-06-2008 (Evitar que coloquen % de descuentos de mas de tres dÝgitos)
//                           26-06-2008 (No permitir cambiar el cliente de una devoluci¾n)
//                           16-07-2008 (Cßlculo especial para BMC y Bematech, Ej: Al generar el sgte ticket: 
//                                       5 x Bs 10.50 % IVA 9 y 5 x Bs 50 % IVA 8 BMC genera el total del ticket por
//                                       Bs 327.25 y la impresora Bematech por Bs 327.23)
//                           21-07-2008 (Evitar generar tickets sin cliente)
//                           29-07-2008 (Corrección de función de cambio de precio)
//                           04-08-2008 (Permitir seleccionar el vendedor)
//                           11-08-2008 (Creación de Variables para ser utilizadas por DPPOSDEVOL y TICKETEPSON)
//                           25-08-2008 (Cuando tiene mßs de un precio permite seleccionar entre los Definidos para el producto)
//                           25-08-2008 (Mostrar Existencias en el grid de consulta de productos)
//                           18-09-2008 (Activación de las teclas de Función para los botones)
// 31-07-2009 : se habilito VALID CERO(cNumero) para que incluya los ceros al importar un pedido
// o devolucion
// Llamado por: DPMENU
// Aplicación : Ventas y Cuentas por Pagar
// Tabla      : DPDOCCLI

#INCLUDE "DPXBASE.CH"

PROCE MAIN(lConfig,cTipDocPar,lCxC)
  LOCAL oBtn,oFontB,oTable,oBrw,oCol,oFontBrw,aItems:={},aBtn:={}
  LOCAL nPorVar,I,nTotal:=0,oBrush,U,nLin,nCol,oBtn,oFontBtn
  LOCAL nBntAlto:=32,nBtnAncho:=32,aPagina:={},aGrupo:={},aLine:={},aBtnFile:={}
  LOCAL nPageIni:=1,cTipDoc:="TIK",lMesas:=.F.,cPrecio:="A",cCodCli:=STRZERO(0,10),cCodVen:=STRZERO(1,6)
  LOCAL oChk,oBrush,nCols:=5+0,nRows:=4+0,cCodMon:=oDp:cMonedaExt,cCenCos:=STRZERO(1,8)
  LOCAL nCajaFondo:=0.00,cTipPrecio:="A",cTipDev:="DEV"
  LOCAL lCierre   :=.F.,lAbierto:=.F.,lImpFis:=.F.,cCodTra:="S000",cCodAlm:="",cCodCaja:=oDp:cCaja,lLibVta:=.T.
  LOCAL lVendedor :=.F.,cCxC
  LOCAL cLetraSf  :="",oSerFis // Letra de la Serie Fiscal 07/07/2022
  LOCAL cNombreSF :=""
  LOCAL cSerie    :=""
  LOCAL cTitle    :=""

//LOCAL aUnd      :={oDp:cUndMed}

   DEFAULT lConfig:=.F.

  // oDp:lTracer:=.T.

   DEFAULT oDp:cImpFiscal:=NIL,;
           oDp:cDisp_lDisplay:=NIL

   IF ValType(cTipDocPar)="C" .AND. !"DEV"$cTipDocPar

     cSerie :=SQLGET("DPTIPDOCCLI","TDC_SERIEF,TDC_LIBVTA,TDC_CXC","TDC_TIPO"+GetWhere("=",cTipDocPar))
     lLibVta:=DPSQLROW(2)
     cCxC   :=DPSQLROW(3,"")

     DEFAULT lCxC   :=!("N"$cCxC)

     IF "NING"$UPPER(cSerie) .AND. lLibVta 
       MsgMemo("Seleccione la Serie Fiscal para el Tipo de Documento ["+cTipDocPar+"]")
       oDp:oFrm:=EJECUTAR("DPTIPDOCCLI",3,cTipDocPar)
       DPFOCUS(oDp:oFrm:oTDC_SERIEF)
       oDp:oFrm:oTDC_SERIEF:Open()
       CursorArrow()
       RETURN .F.
     ENDIF

     oSerFis:=OpenTable("SELECT * FROM DPSERIEFISCAL WHERE SFI_MODELO"+GetWhere("=",cSerie))
     oDp:cImpFiscal:=oSerFis:SFI_IMPFIS

   ELSE

     SQLUPDATE("DPTIPDOCCLI","TDC_ACTIVO",.T.,"TDC_TIPO"+GetWhere("=",oDp:cTipDocVta))

     lLibVta:=SQLGET("DPTIPDOCCLI","TDC_LIBVTA,TDC_CXC","TDC_TIPO"+GetWhere("=",oDp:cTipDocVta))
     cCxC   :=DPSQLROW(2,"")
     lCxC   :=!("N"$cCxC)

     IF lLibVta .AND. ISSQLFIND("DPSERIEFISCAL","SFI_PCNAME"+GetWhere("=",oDp:cPcName)+"  AND SFI_AUTDET=1 AND NOT SFI_IMPFIS"+GetWhere(" LIKE ","%Ningun%"))
        // Debe Actualizar el Puerto del AutoDetec
        EJECUTAR("DPSERFISCALAUTODETEC")
     ENDIF

     oSerFis     :=OpenTable("SELECT * FROM DPSERIEFISCAL WHERE SFI_PCNAME"+GetWhere("=",oDp:cPcName)+" AND SFI_ACTIVO=1")

   ENDIF

   // PED-> CXC
   DEFAULT lCxC   :=.F.

//  ? oSerFis:cSql
//   oSerFis:Browse()

/*
   IF oSerFis:RecCount()=0
      MsgMemo("Este PC "+oDp:cPcName+" no Tiene Serie Fiscal Asignada","Asignar Serie Fiscal para este PC")
      RETURN 
   ENDIF
*/
   cNombreSF:=ALLTRIM(oSerFis:SFI_MODELO)+" "
   oSerFis:End()
   
   IF oSerFis:RecCount()=0 .AND. lLibVta .AND. (cTipDocPar="FAV" .OR. cTipDocPar="TIK" .OR. cTipDocPar="DEV")
      MsgMemo("Este PC "+oDp:cPcName+" no Tiene Serie Fiscal Asignada","Asignar Serie Fiscal para este PC")
      DPLBX("DPSERIEFISCAL.LBX")
      RETURN .F.
   ENDIF

// oSerFis:browse()
// ? oSerFis:SFI_PUERTO,oSerFis:SFI_IMPFIS

   IF lLibVta .AND. Empty(oSerFis:SFI_PUERTO) .AND. !("Ningu"$oSerFis:SFI_IMPFIS)
      MsgMemo("Puerto Serial no detectado para la Impresora Fiscal "+oSerFis:SFI_IMPFIS,"Seleccione el Puerto de la Impresora Fiscal")
      EJECUTAR("DPSERIEFISCAL",3,oSerFis:SFI_LETRA)
      RETURN .F.
   ENDIF

   IF Type("oPos")="O" .AND. oPos:oWnd:hWnd>0
      EJECUTAR("BRRUNNEW",oPos,GetScript())
      RETURN .T.
   ENDIF

   IF (oDp:cImpFiscal=NIL .OR. ValType(oDp:cDisp_lDisplay)="U") .OR. .T.
     EJECUTAR("DPPOSLOAD")
   ENDIF

   // 07/07/2022
   EJECUTAR("DPSERIEFISCALLOAD")

   IF oDp:cImpFiscal=NIL .OR. ValType(oDp:cDisp_lDisplay)="U"
     EJECUTAR("DPPOSDEF",NIL,"DPPOS04")
     RETURN NIL
   ENDIF

   EJECUTAR("KPIDIVISAGET")

   IF Empty(oDp:dKpiFecha)
     MsgMemo("Requiere Registro de Divisa "+oDp:cMonedaExt)
     EJECUTAR("DPHISMON",1,oDp:cMonedaExt,oDp:dFecha)
     RETURN .T.
   ENDIF

   MsgRun("Cargando Parámetros del POS ","Espere....",{||;
           EJECUTAR("DISPRUN","AdaptaPro","Punto de Venta"),;
           aPagina:=EJECUTAR("DPPOSLEEINI","DP\DPPOS04.INI",nRows,nCols)})

   DEFAULT oDp:aCoors:=GetCoors( GetDesktopWindow() )

   // Factura de contingencia, debe asumir impresora fiscal NINGUNA
   IF ValType(cTipDocPar)="C"
     oDp:cImpFiscal:=oSerFis:SFI_IMPFIS
     oDp:cTkSerie  :=oSerFis:SFI_LETRA
     oDp:cImpFisCom:=""
    ENDIF

   IF EMPTY(aPagina)
     RETURN .T.
   ENDIF

    // Descripción,Total,cantidad,precio,Unidad de Medida,codigo,IVA,cTipIva 
   // AADD(aItems,{SPACE(50),0,0,0,SPACE(6),SPACE(20),0,"",0})
   aItems:=POSREINI(.F.)

   DEFINE FONT oFontBrw NAME "Tahoma" SIZE 0, -12 
   DEFINE FONT oFontB   NAME "Tahoma" SIZE 0, -12 BOLD
   DEFINE FONT oFontBtn NAME "Tahoma" SIZE 0, -06 ITALIC

   // 20-08-2008 Marlon Ramos (Se agrega el nombre de la impresora; ·til cuando una marca tiene mßs de un m¾delo Ej.: Epson 220AF, PF-200,etc)
   //DPEDIT():New("Punto de Venta","DPFRMPOS01.EDT","oPos",.F.)

   cTitle:="Punto de Venta  .:"+IF("Nin"$ALLTRIM(oDp:cImpFiscal),cNombreSF,ALLTRIM(oDp:cImpFiscal)+",")+"Serie Fiscal:"+oDp:cTkSerie+IF(Empty(oDp:cImpFisCom),"",",Puerto:"+oDp:cImpFisCom)

   IF oDp:lImpFisModVal   
      cTitle:=cTitle+" <Modo Validación> "
   ENDIF

   cTitle:=cTitle+":."

   DPEDIT():New(cTitle,"DPFRMPOS04.EDT","oPos",.F.)

   oPos:cFileChm   :="CAPITULO3.CHM"
   oPos:lConfig    :=lConfig
   oPos:aPagina    :=ACLONE(aPagina)
   oPos:cTopic     :="00M10"
   oPos:aItems     :=ACLONE(aItems)
   oPos:cPicture   :="99,999,999,999.99"
   oPos:cPicItem   :="9,999,999,999.99"
   oPos:cCodInv    :=SPACE(20)
   oPos:nCantid    :=1.00
   oPos:nBruto     :=0.00
   oPos:nPrecio    :=0.00
   oPos:nIva       :=0.00
   oPos:nNeto      :=0.00
   oPos:cMsg1      :=SPACE(40)
   oPos:cMsg2      :=SPACE(40)
   oPos:aBtnBmp    :={}
   oPos:lCantid    :=.F.     // Requiere Cantidad
   oPos:lTikWait   :=.F.
   oPos:lMesas     :=lMesas  // Requiere Cantidad
// oPos:cTipDoc    :=cTipDoc 	
   oPos:cPrecio    :=oDp:cPrecioPos
   oPos:cTipDev    :=oDp:cTipDocDev
   oPos:cTipFav    :=oDp:cTipDocVta
   oPos:cTipDoc    :=oDp:cTipDocVta
   oPos:cFileBmp   :="" // DPPOSDP.BMP"
   oPos:nMtoDev    :=0  // Devolución
   oPos:cTicketDev :="" // Ticket Devolución
   oPos:nMtoVta    :=0
   oPos:nPeso      :=0  // Productos que se Cuantifican por Peso
   oPos:nMtoDev    :=0
   oPos:dFchVen    :=CTOD("")
   oPos:nCapa      :=0
   oPos:cLote      :=""
   oPos:cZonaNL    :=SQLGET("DPCLIENTES","CLI_ZONANL","CLI_CODIGO"+GetWhere("=",STRZERO(0,10)))
   oPos:cMsgCod    :=""
   oPos:lDpPosCli  :=.F.
   oPos:cColor     :=""
   oPos:oGrid      :=NIL
   oPos:aTallas    :={}
   oPos:lResItem   :=.T. // Resumen por Item JN 02/06/2013
   oPos:nValCam    :=oDp:nMonedaExt // Valor Cambiario
   oPos:lValRif    :=.F. // Validación del RIF Activado
   oPos:aUndMed    :={oDp:cUndMedPos}
   oPos:lUndMed    :=.T. // Unidades de Medida
   oPos:cInvLbxWhere:=NIL
   oPos:lPeso       :=.F.
   oPos:lPagos      :=.T. // Acepta Pagos
   oPos:lPrecio     :=.T.
   oPos:lValCodInv  :=oPos:lPrecio
   oPos:nBruto      :=0
   oPos:nDocDesc    :=0
   oPos:cMonedaPago :=oDp:cMoneda
   oPos:nVueltoD    :=0 // Vuelto en Dolares
   oPos:nVueltoBs   :=0 // Vuelto en Bs.
   oPos:nIGTF       :=0 // IGTF
   oPos:oIGTF       :=NIL // IGTF
   oPos:nEfePorIGtf :=SQLGET("DPCAJAINST","ICJ_PORITF","ICJ_CODIGO"+GetWhere("=","DOL")+" AND ICJ_CALITF=1")
   oPos:nPagado     :=0
   oPos:lCxC        :=lCxC // Cuenta Por Cobrar
   oPos:cCxC        :=cCxC
   oPos:aDocSave    :={} // utilizado para conocer los documentos creados en DPPOSSAVE 18/11/2022

   IF ValType(cTipDocPar)="C"
      oPos:cTipFav    :=cTipDocPar
      oPos:cTipDoc    :=cTipDocPar
   ENDIF

   oDp:cPictPeso    :="999,999.99"
   oDp:cPictPrecio  :="999,999,999,999.99"


  // Decreto 22/12/2016
  oPos:lLimite     :=.F.  // Documento con Limites
  oPos:lPagEle     :=.F.  // Pago en formas electrónica
  oPos:nLimite     :=0    // Limite del Monto
  oPos:cTipPer     :="N"  // Personas Naturales
  oPos:nIvaGN      :=0    // Iva Aplicado
  oPos:cTitleCli   :=nil  // Titulo Ventana de Clientes
  oPos:lParAutoImp :=.F.  // oPos:lPar_AutoImp // AutoImpresión de Factura
  oPos:dDesdeLim   :=CTOD("")
  oPos:dHastaLim   :=CTOD("")
  oPos:cTipIvaLim  :=""  
  oPos:cNomCli     :=SPACE(200) 
  oPos:lLibVta     :=lLibVta
  oPos:lCalIva     :=.T.


  // oPos:cZonaNL :="L"
  // ? oPos:cZonaNL
  // 16-12-2008 Marlon Ramos (Ejecutar Programas para Impresoras Fiscales DpPos01)
    oDp:lDpPos02:=.F.  
  // Fin 16-12-2008 
  // 01-09-2008 Marlon Ramos
  IF Empty(oDp:cImpFiscal) .OR. "NINGUNA"$UPPE(oDp:cImpFiscal) 

// JN 21/01/2021 Utilizara Crystal Report
//        MensajeErr("No hay Impresora Configurada para el Punto de Venta"+CRLF+"Configure una desde Definiciones del Sistema.")
//        Return .F.

   ENDIF
  // Fin 01-09-2008 Marlon Ramos

  IF "BEMA"$UPPE(oDp:cImpFiscal) 
//    oPos:cFileBmp   :="DPPOSBEMA.BMP"
  ENDIF

  IF "BMC"$UPPE(oDp:cImpFiscal) 
//    oPos:cFileBmp   :="DPPOSBMC.BMP"
  ENDIF

  IF "EPSON"$UPPE(oDp:cImpFiscal) 
//    oPos:cFileBmp   :="DPPOSEPSON.BMP"
  ENDIF

  // 19-09-2008 Marlon Ramos (Inclusión de las Impresoras Samsung)
     IF "SAMSUNG"$UPPE(oDp:cImpFiscal) 
//        oPos:cFileBmp   :="DPPOSSAMSUNG.BMP"
     ENDIF
  // Fin 19-09-2008 Marlon Ramos

  // 27-10-2009 Marlon Ramos (Inclusión de las Impresoras Aclas)
     IF "ACLAS"$UPPE(oDp:cImpFiscal) 
//        oPos:cFileBmp   :="DPPOSACLAS.BMP"
     ENDIF
  // Fin 27-10-2009 Marlon Ramos

  // 29-10-2009 Marlon Ramos (Inclusión de las Impresoras Okidata)
     IF "OKIDATA"$UPPE(oDp:cImpFiscal) 
//        oPos:cFileBmp   :="DPPOSOKIDATA.BMP"
     ENDIF
  // Fin 29-10-2009 Marlon Ramos

  // 24-11-2009 DataPro (Inclusion de las Impresoras STAR HSP-7000)
     IF "STAR"$UPPE(oDp:cImpFiscal) 
//        oPos:cFileBmp   :="DPPOSSAMSUNG.BMP"
     ENDIF
  // Fin 24-11-2009 DataPro

  // 18-09-2008 Marlon Ramos
     //SET KEY VK_F3 TO oPos:FUNF3()
     SET KEY VK_F4 TO oPos:FUNF4()
     //SET KEY VK_F6 TO oPos:FUNF6()
  // Fin 18-09-2008 Marlon Ramos

  oPos:aDataWait  :={}
  oPos:cMsgInv    :="Introduzca el Código del Producto"
  oPos:cMsgErr    :=SPACE(40)
  oPos:cIva       :=""     // IVA del Producto
  oPos:nIva       :=0.00
  oPos:nDocOtros  :=0.00
  oPos:nDocDesc   :=0.00
  oPos:nBemaDesc  :=0.00
  oPos:nRows      :=nRows
  oPos:nCols      :=nCols
  oPos:nIvaItem   :=0.00 // Iva por Item
  oPos:dFecha     :=oDp:dFecha
  oPos:cCodSuc    :=oDp:cSucursal
  oPos:cCodCli    :=cCodCli
  oPos:cCodVen    :=cCodVen
  oPos:lCodVen    :=lVendedor
  oPos:cCodVenIni :=cCodVen
  oPos:cCodMon    :=cCodMon
  oPos:cCenCos    :=cCenCos
  oPos:cCodTra    :=cCodTra // Código de Transacción
  oPos:lImpFis    :=lImpFis // Indica si Existe Impresora Fiscal
  oPos:cCodAlm    :=IIF(Empty(cCodAlm),oDp:cAlmacen,cCodAlm) // Almacen de Trabajo
  oPos:cUndMed    :=oDp:cUndMed     // Unidad de Medida en la Venta
  oPos:nCxUnd     :=0
  oPos:nEfectivo  :=0 
  oPos:nEfectivoUs:=0 // Monto en Divisa
  oPos:nDebito    :=0  
  oPos:cBcoDeb    :="" 
  oPos:cMarcaTD   :=""
  oPos:cPosTC     :=""

  oPos:cBcoTCT    :=""
  oPos:cTarCT     :=""
  oPos:nTarCT     :=0
  oPos:cMarcaCT   :=""
  oPos:cPosCT     :=""

  oPos:nCredito   :=0  
  oPos:cCredito   :=""
  oPos:cBcoCre    :=""
  oPos:cMarcaTC   :=""
  oPos:cPosTC     :=""
    
  oPos:nRecibe    :=0      
  oPos:nResiduo   :=0
  oPos:nCesta     :=0 // Pago con Cesta
  oPos:nZelle     :=0 // Pago con Zelle
  oPos:nPagoMovil :=0 // Pago Móvil
  oPos:nVuelto    :=0      
  oPos:nCanTot    :=0 // Cantidad Total de Productos
  oPos:aDataBal   :={} // Data de la Balanza
  oPos:cCodCaja   :=cCodCaja
  oPos:cTipPrecio :=cTipPrecio
  oPos:lPrecioIva :=SQLGET("DPPRECIOTIP","TPP_INCIVA","TPP_CODIGO"+GetWhere("=",cTipPrecio))  
  oPos:nPag       :=nPageIni
  oPos:nCheque    :=0
  oPos:nRecibe    :=0
  oPos:cBanco     :=""
  oPos:cCheque    :=""
  oPos:cCupon     :="" // Cupon de la Impresora Fiscal
  oPos:nDescxI    :=0  // Descuento por Item
  oPos:dFechAsoc  :={} // 11-08-2008 Marlon Ramos (Utilizada por DPPOSDEVOL / TICKETEPSON / DPPOSPRINT)
  oPos:dHoraAsoc  :="" // 11-08-2008 Marlon Ramos (Utilizada por DPPOSDEVOL / TICKETEPSON / DPPOSPRINT)
  oPos:cTickAsoc  :="" // 12-09-2008 Marlon Ramos (Utilizada por DPPOSDEVOL / DPPOSPRINT)

  oTable:=OpenTable("DPCLIENTESCERO",.F.)
  oPos:SetTable(oTable)
  oTable:End()

  oTable:=OpenTable("DPDOCCLI",.F.)
  AEVAL(oTable:aFields , { |a,n| __objAddData( oPos , a[1] ) })
  oTable:End()

  oPos:lMsgBar  :=.F.

  oPos:CreateWindow()

  SetWndDefault(oPos:oDlg)

//  WndSetDefault(oPos:oDlg)
//  oPos:oDlg:oFont:=oFontBtn
//  @ 2,1 GROUP oPos:oGrupo TO 4, 21.5 PROMPT "Datos del Producto"    

  oBrw:=TXBrowse():New(oPos:oDlg )
  oBrw:SetArray( oPos:aItems ,.F.)
  oBrw:lHScroll := .F.
  oBrw:lVScroll := .T.
  oBrw:nFreeze  := 1
  oBrw:oFont    :=oFontBrw
  oBrw:nHeaderLines:= 2
  oBrw:nDataLines  := 2
  oBrw:lFooter     :=.T.
  oBrw:lHeader     :=.T.
//  oBrw:SETBRUSH(oBrush)

  oCol:=oBrw:aCols[1]
  oCol:cHeader:="Descripción"
  oCol:nWidth :=250
  oCol:oHeaderFont:=oFontB

  oCol:=oBrw:aCols[2]
  oCol:cHeader      :="Total"+CRLF+"en "+oDp:cMoneda
  oCol:nWidth       := 110+15
  oCol:oHeaderFont  := oFontB
  oCol:cEditPicture := oPos:cPicture
  oCol:bStrData     := {|oBrw|oBrw:=oPos:oBrwItem,FDP(oBrw:aArrayData[oBrw:nArrayAt,2],oPos:cPicItem)}
  oCol:bClrStd      := {|oBrw|oBrw:=oPos:oBrwItem,{IIF(oBrw:aArrayData[oBrw:nArrayAt,2]<0,CLR_HRED,CLR_HBLUE), iif( oBrw:nArrayAt%2=0,oDp:nClrPane1,oDp:nClrPane2 ) } }
  oCol:nHeadStrAlign:= AL_RIGHT
  oCol:nFootStrAlign:= AL_RIGHT
  oCol:nDataStrAlign:= AL_RIGHT
  oCol:cFooter      :="0.00"
  oCol:cEditPicture :="999,999,999,999.99"

  oCol:=oBrw:aCols[3]
  oCol:cHeader      :="Total"+CRLF+"en "+oDp:cMonedaExt
  oCol:nWidth       := 90
  oCol:oHeaderFont  := oFontB
  oCol:cEditPicture := oPos:cPicture
  oCol:bStrData     := {|oBrw|oBrw:=oPos:oBrwItem,FDP(oBrw:aArrayData[oBrw:nArrayAt,2]/oPos:nValCam,oPos:cPicItem)}
  oCol:bClrStd      := {|oBrw|oBrw:=oPos:oBrwItem,{IIF(oBrw:aArrayData[oBrw:nArrayAt,2]<0,CLR_HRED,CLR_HBLUE), iif( oBrw:nArrayAt%2=0,oDp:nClrPane1,oDp:nClrPane2 ) } }
  oCol:nHeadStrAlign:= AL_RIGHT
  oCol:nFootStrAlign:= AL_RIGHT
  oCol:nDataStrAlign:= AL_RIGHT
  oCol:cFooter      :="0.00"
  oCol:cEditPicture :="999,999,999,999.99"

  oBrw:bClrStd      := {|oBrw|oBrw:=oPos:oBrwItem,{CLR_BLUE, iif( oBrw:nArrayAt%2=0,oDp:nClrPane1,oDp:nClrPane2 ) } }
//oBrw:bClrHeader   := {|oBrw|oBrw:=oPos:oBrwItem,{CLR_BLUE,12582911}}
  oBrw:bClrHeader   := {|| { CLR_WHITE,16744448}}

  oBrw:bClrHeader := {|| {0,oDp:nGrid_ClrPaneH}}
  oBrw:bClrFooter := {|| { oDp:nLbxClrHeaderText, oDp:nLbxClrHeaderPane}}

  oBrw:CreateFromCode()
  oPos:oBrwItem:=oBrw

/*
  @ 1.0+20,29.0 BMPGET oPos:oCodInv  VAR oPos:cCodInv ;
             VALID oPos:ValCodigo();
             NAME "BITMAPS\FIND.BMP"; 
             ACTION (oDpLbx:=DpLbx("DPINVPOS",NIL,[LEFT(INV_ESTADO,1)="A"],NIL,NIL,NIL,NIL,NIL,NIL,oPRECIOTIP:oTPP_CODMON,NIL) ,oDpLbx:GoTop(), oDpLbx:GetValue("INV_CODIGO",oPos:oCodInv)); 
             WHEN 1=1;
             SIZE 80,10

     oPos:oCodInv:bKeyDown:={|nKey|oPos:PosKeyDown(nKey)}

//  n{|nKey|IIF(!oPos:lCantid .AND. (nKey=13 .OR. nKey=9), oPos:SaveVenta(!oPos:lCodVen),NIL )}
*/

//  @ 10+20,38 GET oPos:oCantid VAR oPos:nCantid PICTURE oDp:cPictCanUnd RIGHT;
//          VALID  oPos:ValCantid() .AND. oPos:SaveVenta(!oPos:lCodVen);
//          WHEN oPos:lCantid

/*
  @ 1.0+20,29.0 BMPGET oPos:oCodVen  VAR oPos:cCodVen ;
             VALID oPos:ValCodVen();
             NAME "BITMAPS\FIND.BMP"; 
             ACTION (oDpLbx:=DpLbx("DPVENDEDOR") , oDpLbx:GetValue("VEN_CODIGO",oPos:oCodVen)); 
             WHEN .T. ;
             SIZE 80,10
*/
//             WHEN oPos:lCodVen 

  nBntAlto :=30
  nBtnAncho:=30
  aGrupo   :=aPagina[nPageIni]
  oFontBtn:=NIL

//VIEWARRAY(aGrupo)
//? oPos:nCols,oPos:nRows

  DEFINE FONT oFontBtn NAME "Tahoma" SIZE 0, -06 BOLD

  FOR I=1 TO oPos:nRows

    nLin :=20 + (nBntAlto*(I-1))
    aBtn :={}
    aLine:=aGrupo[i]

    FOR U=1 TO oPos:nCols

      nCol:=210+ (nBtnAncho*(U-1))
      aBtnFile:=aLine[U,2]

      @ nLin, nCol SBUTTON oBtn PIXEL;
                   SIZE nBntAlto-2,nBtnAncho-2 FONT oFontBtn;
                   FILE "BITMAPS\"+aBtnFile[1],"BITMAPS\"+aBtnFile[2],"BITMAPS\"+aBtnFile[3] BORDER;
                   TOP PROMPT aLine[U,1];
                   COLORS CLR_BLACK, { CLR_WHITE, oDp:nGris2, 1 };
                   ACTION 1=1

      oBtn:cToolTip:=aLine[U,6]
      oBtn:cMsg:=aLine[U,6]

      AADD(aBtn,oBtn)

      // 17-08-2008 Marlon Ramos (Mostrar tecla de función asociada al bot¾n)
         //oBtn:SetText( aLine[U,1], 42, 2, nil, nil , nil )
         oBtn:SetText( IIF(LEFT(aLine[U,1],1)="F" .AND. VAL(SUBSTR(aLine[U,1],2,1))>0,LEFT(aLine[U,1],3),"")+CRLF+CRLF+CRLF+RIGHT(aLine[U,1],LEN(aLine[U,1])-IIF(LEFT(aLine[U,1],1)="F" .AND. VAL(SUBSTR(aLine[U,1],2,1))>0,3,0)), 5, 2, nil, nil , nil )
      // Fin 17-08-2008 Marlon Ramos 

      oBtn:SetFont(oFontBtn)
  //    oBtn:SetText( aBtn[U,2], 40, 5, nil, nil,nil )

      oBtn:bWhen  :=aLine[U,3]
      IF oPos:lConfig
        oBtn:bAction:=BloqueCod([oPos:SETBONTON(]+["]+aLine[U,7]+[")])
      ELSE
        oBtn:bAction:=aLine[U,4]
      ENDIF
   
    NEXT U
   
    AADD(oPos:aBtnBmp,aBtn)

  NEXT I

//? oFontBtn:ClassName(),aBtnFile[1]


  @ 3.0, 210 SBUTTON oBtn PIXEL;
             SIZE 30,18 FONT oFontB;
             FILE "BITMAPS\XTOP.BMP";
             COLORS CLR_BLACK, { CLR_WHITE, oDp:nGris2, 1 };
             ACTION oPos:PAGSKIP(-1)

  @ 3.0, nCol SBUTTON oBtn PIXEL;
              SIZE 30,18 FONT oFontB;
              FILE "BITMAPS\xFIN.BMP";
              COLORS CLR_BLACK, { CLR_WHITE, oDp:nGris2, 1 };
              ACTION oPos:PAGSKIP(1)

  @ 3.0, 210 SBUTTON oPos:oBtnPagUp PIXEL;
             SIZE 20,28 FONT oFontB;
             FILE "BITMAPS\BOTONUP.BMP";
             COLORS CLR_BLACK, { CLR_WHITE, oDp:nGris, 1 };
             ACTION oPos:oBrwItem:GoUp()

  oPos:oBtnPagUp:cToolTip:="Página Siguiente"

  @ 3.0, 210 SBUTTON oPos:oBtnPagDown PIXEL;
             SIZE 20,28 FONT oFontB;
             FILE "BITMAPS\BOTONDOWN.BMP";
             COLORS CLR_BLACK, { CLR_WHITE, oDp:nGris, 1 };
             ACTION oPos:oBrwItem:GoDown()

  oPos:oBtnPagDown:cToolTip:="Página Anterior"

  oPos:Activate({||oPos:PAGBARRA()})

  IF !oDp:lTracer 

    oDp:nDif:=(oDp:aCoors[3]-oPos:oBar:nHeight()-oPos:oWnd:nHeight())+10
    oPos:oWnd:SetSize(NIL,oDp:aCoors[3]-180,.T.)

    oPos:oBrwItem:SetSize(NIL,oPos:oBrwItem:nHeight()+oDp:nDif,.T.)

    DPFOCUS(oPos:oCodInv)
 
  ENDIF

  oDp:oPos:=oPos

RETURN NIL

FUNCTION INICIO()
   LOCAL oCursor,oBar,oBtn,oFont,oCol
   LOCAL oDlg   :=oPos:oDlg
   LOCAL nLin   :=0

   IF oDp:lTracer 
      RETURN 
   ENDIF

   DEFINE CURSOR oCursor HAND
   DEFINE BUTTONBAR oBar SIZE 100,140+19 OF oDlg 3D CURSOR oCursor
   DEFINE FONT oFont  NAME "Tahoma"   SIZE 0, -14 BOLD

   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\XSAVE.BMP",NIL,"BITMAPS\XSAVEG.BMP";
          WHEN oPos:nNeto<>0;
          ACTION oPos:POSGRABAR()

   oBtn:cToolTip:="Guardar"

   oPos:oBtnSave:=oBtn
/*
   DEFINE BUTTON oPos:oBtnExit;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\SENIAT.BMP";
          ACTION (oPos:lValRif:=oPos:lValRif,;
                  oPos:VALRIFSENIAT());
          CANCEL

   oPos:oBtnExit:cToolTip:="Activar/Inactivar Validación del RIF en el Seniat"
*/

   DEFINE BUTTON oPos:oBtnPed;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\POS.BMP";
          ACTION oPos:SetTipDoc("PRO") 
// oPos:cTipFav)

   oPos:oBtnPed:cToolTip:="Pro-Forma" 
// Tipo de Documento "+oPos:cTipFav


   DEFINE BUTTON oPos:oBtnNen;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\notaentrega.BMP";
          ACTION oPos:SetTipDoc("NEN")

   oPos:oBtnNen:cToolTip:="Asignar Nota de Entrega"

   DEFINE BUTTON oPos:oBtnPed;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\pedidoventa.BMP";
          ACTION oPos:SetTipDoc("PED")

   oPos:oBtnPed:cToolTip:="Pedido"

   DEFINE BUTTON oPos:oBtnPed;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\COTIZA.BMP";
          ACTION oPos:SetTipDoc("CTZ")

   oPos:oBtnPed:cToolTip:="Cotiza"

   DEFINE BUTTON oPos:oBtnPla;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\PLANTILLAS.BMP";
          ACTION oPos:SelPlantilla()

   oPos:oBtnPla:cToolTip:="Seleccionar Plantillas"


   DEFINE BUTTON oPos:oBtnPla;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\SENIAT.BMP";
          ACTION oPos:VALRIFSENIAT()

   oPos:oBtnPla:cToolTip:="Obtener Datos desde el SENIAT"


   DEFINE BUTTON oPos:oBtnPla;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\XBROWSE.BMP";
          ACTION EJECUTAR("BRTICKETPOS")

   oPos:oBtnPla:cToolTip:="Visualizar Tickets"




   IF !Empty(oDp:cGruLibros) .AND. .F.

     DEFINE BUTTON oPos:oBtnLibros;
            OF oBar;
            NOBORDER;
            FONT oFont;
            FILENAME "BITMAPS\LIBROS.BMP";
            ACTION oPos:SELLIBROS()

      oPos:oBtnLibros:cToolTip:="Seleccionar Plantillas"

   ENDIF

   DEFINE BUTTON oPos:oBtnExit;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\XSALIR.BMP";
          ACTION (oPos:POSCERRAR()) CANCEL

   oPos:oBtnExit:cToolTip:="Salir"

   oBar:SetColor(CLR_BLACK,oDp:nGris)

   AEVAL(oBar:aControls,{|o,n| o:SetColor(CLR_BLACK,oDp:nGris) })

   oPos:oBrwItem:SetColor(0,oDp:nClrPane1)

   oPos:oBar:=oBar

   oPos:SETBTNBAR(40,40,oBar)

   oPos:POSSETGET()
 
RETURN .T.


FUNCTION PrecioItem(nAt,nPrecio,oDlg)
  LOCAL oBrw:=oPos:oBrwItem
 
  oBrw:aArrayData[nAt-IIF(EMPTY(oBrw:aArrayData[nAt,1]),1,0),04]:=nPrecio*oPos:nValCam
  oBrw:aArrayData[nAt-IIF(EMPTY(oBrw:aArrayData[nAt,1]),1,0),02]:=ROUND(nPrecio*oBrw:aArrayData[nAt-IIF(EMPTY(oBrw:aArrayData[nAt,1]),1,0),03],2)

  oBrw:DrawLine(.T.)
  oPos:Calcular()

  oBrw:Refresh(.T.)
  oBrw:GoBottom(.T.)

//  oDlg:End()

RETURN

FUNCTION ImportTik()
  LOCAL cNumero:=SPACE(10),oDlg,oRadio,nRadio,cTipDoc:=IIF(nRadio=1,"PED","TIK")
  LOCAL cMap:=MYSQLGET("DPUSUARIOS","OPE_MAPMNU","OPE_NUMERO"+GetWhere("=",oDp:cUsuario))

//  IF cMap="ADM"

    DEFINE DIALOG oDlg TITLE "Importar Documento" FROM 0,0 TO 8,33

    @ 0.5,1 SAY "Numero del Documento :" 
    @ 1.5,1 GET cNumero SIZE 50,10 VALID CERO(cNumero)

    @ 2.5,12 BUTTON "Aplicar" SIZE 22,12 ACTION oPos:IMPORTDOC(cNumero,nRadio)

    @ 2.5,17 BUTTON "Cerrar"  SIZE 22,12 ACTION oDlg:End()

    @ 0.5,10.5 RADIO oRadio VAR nRadio;
               ITEMS "Pedido","Devolucion";
               SIZE 60,12;
               COLOR NIL,oDp:nGris 

    ACTIVATE DIALOG oDlg CENTERED

//  EJECUTAR("DPPOSUSUARIO",oPos)
//  ELSE
//  MsgInfo("Acceso Restringido","Advertencia")
//  ENDIF

RETURN

FUNCTION IMPORTDOC(cNumero,nRadio)
  LOCAL cTipDoc:=IIF(nRadio=1,"PED","TIK")

  oPos:ImportTicket(cNumero,cTipDoc)
  oDlg:End()

RETURN 

FUNCTION ImportTicket(cNumero,cTipDoc)
  LOCAL aData,oTable,cMsgInv:="",I:=0,aImport:={}
  LOCAL oBrw :=oPos:oBrwItem
  LOCAL nAt 

  aData:=ASQL("SELECT MOV_TOTAL,MOV_CANTID,MOV_PRECIO,MOV_CODIGO,MOV_IVA,MOV_TIPIVA,0 AS INV_DESCRI,"+;
              " MOV_UNDMED,MOV_CANTID,DOC_CODVEN,MOV_DESCUE "+;
              " FROM DPMOVINV INNER JOIN DPDOCCLI ON MOV_DOCUME=DOC_NUMERO "+;
              " WHERE DOC_NUMERO"+GetWhere("=",cNumero)+;
              "       AND DOC_TIPDOC"+GetWhere("=",cTipDoc)+;
              "       AND MOV_TIPDOC"+GetWhere("=",cTipDoc))
	
  nAt  :=LEN(aData)	

  FOR I=1 TO nAt

    cMsgInv:=MYSQLGET("DPINV","INV_DESCRI","INV_CODIGO"+GetWhere("=",aData[I,4]))

    AADD(aImport,{aData[I,4]+" "+ALLTRIM(FDP(aData[I,2],"999,999,999.999",.F.))+" X "+;
                                 ALLTRIM(FDP(aData[I,3],"999,999,999.99"))+CRLF+cMsgInv,aData[I,1],IF(cTipDoc="TIK",aData[I,2]*(-1),aData[I,2]),+;
    aData[I,3]," ",aData[I,4],aData[I,5],aData[I,6],aData[I,7],aData[I,8],aData[I,9],aData[I,10],aData[I,11]})

    cMsgInv:=""

  NEXT I

  oPos:aImport:=ACLONE(aImport)
  oPos:TicketRestore(.T.)

//  oTable:Browse()
//  ViewArray(aImport)
RETURN



FUNCTION CAMB_PRECIO(lPrec)
  LOCAL nMonto:=0.00,oDlg,oRadio,nRadio
  LOCAL cMap:=MYSQLGET("DPUSUARIOS","OPE_MAPMNU","OPE_NUMERO"+GetWhere("=",oDp:cUsuario))

  IF oPos:nNeto<0
    oPos:SetMsgErr("Debe Concluir la Devolución")
    RETURN .F.
  ENDIF

  IF cMap="ADM"

    DEFINE DIALOG oDlg TITLE "Cambia Precio x Renglon" FROM 0,0 TO 8,33

    @ 0.5,1 SAY "Monto :" 
    @ 1.5,1 GET nMonto SIZE 50,10 RIGHT PICTURE "999,999,999.99"

    @ 2.5,12 BUTTON "Aplicar" SIZE 22,12 ACTION (oPos:PrecioItem(oPos:oBrwItem:nArrayAt,nMonto),oDlg:End())
    @ 2.5,17 BUTTON "Cerrar"  SIZE 22,12 ACTION oDlg:End()

    ACTIVATE DIALOG oDlg CENTERED

  ELSE
    MsgInfo("Acceso Restringido, Requiere Mapa de Menú [ADM]","Advertencia")
  ENDIF

RETURN

FUNCTION DescItem(nAt,nDesc)
  LOCAL oBrw:=oPos:oBrwItem
  LOCAL aData:=oPos:oBrwItem:aArrayData

  nAt:=nAt-IIF(EMPTY(oBrw:aArrayData[nAt,1]),1,0)  // 21-07-2008 Marlon Ramos
  // 21-07-2008 oBrw:aArrayData[nAt,02]:=(oBrw:aArrayData[nAt,04]*oBrw:aArrayData[nAt,03])-PORCEN(oBrw:aArrayData[nAt,04]*oBrw:aArrayData[nAt,03],nDesc) 
  oBrw:aArrayData[nAt,02]:=(oBrw:aArrayData[nAt,04]*oBrw:aArrayData[nAt,03])-ROUND(PORCEN(oBrw:aArrayData[nAt,04]*oBrw:aArrayData[nAt,03],nDesc),2) 
  oBrw:aArrayData[nAt,05]:=IIF(nDesc<>0,ALLTRIM(FDP(nDesc,"99"))+" % Desc","0 %")
  oBrw:aArrayData[nAt,13]:=nDesc
  //viewarray(oPos:oBrwItem:aArrayData)
  oBrw:aArrayData:Refresh(.T.)
  CursorWait()

  oBrw:DrawLine(.T.)
  oPos:Calcular()

  oBrw:Refresh(.T.)
  oBrw:GoBottom(.T.)
RETURN

FUNCTION DESC_TOTAL(lDesc)
  LOCAL nMonto:=0,oDlg,oRadio,nRadio
  LOCAL cMap:=MYSQLGET("DPUSUARIOS","OPE_MAPMNU","OPE_NUMERO"+GetWhere("=",oDp:cUsuario))

  IF oPos:nNeto<0
    oPos:SetMsgErr("Debe Concluir la Devolución")
    RETURN .F.
  ENDIF

  IF cMap="ADM"
    // 13-06-2008 Marlon Ramos (Evitar descuentos dobles)
       IF oPos:nDocDesc > 0
          MensajeErr("Ya hay un Descuento Activo de: "+TRANSFORM(oPos:nDocDesc,"999%"))
          Return
       ENDIF
    // Fin 13-06-2008 Marlon Ramos
 
    DEFINE DIALOG oDlg TITLE "Asignar Descuento a la Factura" FROM 0,0 TO 8,33

    @ 0.5,1 SAY "Descuento :" 


    /* 13-06-2008 Marlon Ramos (Evitar que coloquen descuentos de mas de tres dÝgitos)
      @ 1.5,1 GET nMonto SIZE 30,10
      */
      @ 1.5,1 GET nMonto PICTURE "999" SIZE 20,10 
    // Fin 13-06-2008 Marlon Ramos


    @ 2.5,12 BUTTON "Aplicar" SIZE 22,12 ACTION APLI_DESC(nMonto,nRadio)
    @ 2.5,17 BUTTON "Cerrar"  SIZE 22,12 ACTION oDlg:End()
/* ORIGINAL
    @ 0.5,10.5 RADIO oRadio VAR nRadio;
               ITEMS "Absoluto (Monto)","Relativo (%)","X Item";
               SIZE 60,12;
               COLOR NIL,oDp:nGris 
*/
    @ 0.5,10.5 RADIO oRadio VAR nRadio;
               ITEMS "Del total (%)","De Item (%)";
               SIZE 60,12;
               COLOR NIL,oDp:nGris 
    ACTIVATE DIALOG oDlg CENTERED

//    EJECUTAR("DPPOSUSUARIO",oPos)
  ELSE
    MsgInfo("Acceso Restringido","Advertencia")
  ENDIF
RETURN


FUNCTION APLI_DESC(nMonto,nRadio)
 
  // 13-06-2008 Marlon Ramos (Evitar descuentos de mßs del 100%)
  IF nMonto > 100 .Or. nMonto < 1 
     MensajeErr("El Descuento debe estar en el rango de 1% a 100%")
     Return .F.
  ENDIF
  // Fin 13-06-2008 Marlon Ramos 
  
  IF nRadio=1
    oPos:nDocDesc:=nMonto
    oPos:nBemaDesc:=oPos:nDocDesc
  ENDIF

  IF nRadio=2
    oPos:DescItem(oPos:oBrwItem:nArrayAt,nMonto)
    oDlg:End()
  ENDIF

  //?"oPos:nDocDesc",oPos:nDocDesc,"oPos:nDocOtros",oPos:nDocOtros
  //?"oPos:nBruto:",oPos:nBruto
  //?"oPos:nIvA:", oPos:nIva
  IF oPos:nDocDesc<>0 .OR. oPos:nDocOtros<>0
    DO CASE
	 CASE nRadio=1
  	   oPos:nBruto:=oPos:nBruto-ROUND(PORCEN(oPos:nBruto,oPos:nDocDesc),2)
        //oPos:nBruto:=REDONDEA(oPos:nBruto-(oPos:nBruto/100*oPos:nDocDesc),2)

  	   oPos:nIvA  :=oPos:nIva-ROUND(PORCEN(oPos:nIva,oPos:nDocDesc),2)
        //oPos:nIvA  :=ROUND(oPos:nIva-(oPos:nIva/100*oPos:nDocDesc),2)
  	   //?"1",oPos:nIvA ,"oPos:nBruto:",oPos:nBruto
  	   //oPos:nIvA  :=oPos:nIva-REDONDEA(oPos:nIva/100*oPos:nDocDesc)
  	   //?"2",oPos:nIvA 
    ENDCASE

  /* 02-06-2008 Marlon Ramos (Se redondea para Evitar descuadres)
    oPos:nNeto    :=oPos:nBruto+oPos:nIva
  */
  oPos:nNeto :=STR(oPos:nBruto+ROUND(oPos:nIva,2),12,5)
  oPos:nNeto :=VAL(LEFT( oPos:nNeto,IIF( AT(".",oPos:nNeto)>0,AT(".",oPos:nNeto)-1,LEN(oPos:nNeto) ) )+IIF( AT(".",oPos:nNeto)>0, SUBSTR( oPos:nNeto,AT(".",oPos:nNeto),3 ),"" ))

  // FIN 02-06-2008 Marlon Ramos 

    oPos:oBruto:Refresh(.t.)
    oPos:oIva:Refresh(.t.)
    oPos:oNeto:Refresh(.t.)
    oPos:oDocDesc:Refresh(.t.)   //12-06-2008 Marlon Ramos (Reflejar el descuento en pantalla)
   //?"oPos:nBruto:",oPos:nBruto
   //?"oPos:nIvA:", oPos:nIva
   //?"oPos:nNeto:",oPos:nNeto
  ENDIF

  oDlg:End()

RETURN


FUNCTION PAGBARRA()
  // LOCAL oCursor,oBar,oBtn,oFont,oFontBrw,oFontT
  LOCAL nClrBlink := CLR_YELLOW   // blinking color
  LOCAL nInterval := 500-100      // blinking interval in milliseconds
  LOCAL nStop     := 0            // blinking limit to stop in milliseconds
  LOCAL oFontB,oFontT,oCol
  LOCAL nAddCol   :=20+46-2
  LOCAL nAddLin   :=.5

  oPos:INICIO()

  DEFINE FONT oFontB NAME "Tahoma"   SIZE 0, -14 BOLD
  DEFINE FONT oFontT NAME "Tahoma"   SIZE 0, -22 BOLD

  // Controles para Mensajes
  @26.8+3+5+4, 71+13 STSAY oPos:oMsgInv PROMPT oPos:cMsgInv;
            SIZE 300, 20  FONT oFontB;
            COLORS CLR_HRED

  @28.7+3,71+13 STSAY oPos:oMsgErr PROMPT oPos:cMsgErr OF oPos:oDlg;
            COLORS CLR_HRED SIZE 300, 19 FONT oFontB ;
            SHADED;
            BLINK nClrBlink, nInterval, nStop  

  @ 1.1-1.1, 51+nAddCol-10 SAY oPos:oBruto PROMPT FDP(oPos:nBruto,"99,999,999,999,999.99");
            RIGHT;
            SIZE 214, 24  FONT oFontT;
            COLOR CLR_HGREEN,CLR_BLACK OF oPos:oBar

 @ 1.22+nAddLin,48.9+nAddCol SAY oPos:oDocDesc PROMPT FDP((oPos:nBruto/100)*oPos:nDocDesc,"99,999,999,999.99");
             RIGHT;
             SIZE 214-46, 24  FONT oFontT;
             COLOR CLR_HGREEN,CLR_BLACK OF oPos:oBar


  @ 2.3+.5+nAddLin, 51+nAddCol-10 SAY oPos:oIva PROMPT "IVA "+ALLTRIM(FDP(oPos:nIva,"99,999,999,999.99"));
            RIGHT;
            SIZE 215, 24  FONT oFontT;
            COLOR CLR_HGREEN,CLR_BLACK OF oPos:oBar

  @ 3.6+.85+nAddLin, 51+nAddCol-10 SAY oPos:oNeto PROMPT oDp:cMoneda+" "+ALLTRIM(FDP(oPos:nNeto+oPos:nIGTF,"99,999,999,999,999.99"));
            RIGHT;
            SIZE 215, 24  FONT oFontT;
            COLOR CLR_HGREEN,CLR_BLACK OF oPos:oBar

  @ 6.6+1.2+nAddLin, 51+nAddCol-10 SAY oPos:oNetoUsd PROMPT oDp:cMonedaExt+" "+ALLTRIM(FDP(ROUND((oPos:nNeto+oPos:nIGTF)/oPos:nValCam,2),"99,999,999,999,999.99"));
            RIGHT;
            SIZE 215, 24  FONT oFontT;
            COLOR CLR_HGREEN,CLR_BLACK OF oPos:oBar

   @ 1.22+nAddLin, 37+nAddCol+4 SAY "-" ;
          SIZE 5, 24  FONT oFontT;
          COLOR CLR_HGREEN,CLR_BLACK OF oPos:oBar

  @ 4.9+1.2+nAddLin, 51+nAddCol-10 SAY oPos:oIGTF PROMPT "IGTF "+ALLTRIM(FDP(oPos:nIGTF,"99,999,999,999.99"));
            RIGHT;
            SIZE 215, 24  FONT oFontT;
            COLOR CLR_HGREEN,CLR_BLACK OF oPos:oBar

  oPos:SetTipDoc(oPos:cTipDoc)
  
RETURN .T.

// Seleccionar Forma de Pago
FUNCTION SELFORMAPAG()
  LOCAL oBrw:=oPos:oBrwItem
RETURN .T.

FUNCTION Recibido()
RETURN .T.

/*
// Inicia la Venta
*/
FUNCTION NEWITEM()

 IF oPos:VALCODIGO(.F.)

 ENDIF


RETURN .T.


// Se encarga de Grabar la Venta
FUNCTION SAVEVENTA(lSave)
  LOCAL oBrw :=oPos:oBrwItem,lFound:=.F.
  LOCAL nAt  :=LEN(oBrw:aArrayData)
  LOCAL aLine:=oBrw:aArrayData[nAt]
  LOCAL cLine,cTotal,nLen,nPrecio:=0

  IF EMPTY(oPos:cCodInv) 
    RETURN .F.
  ENDIF

  // JN 02/06/2013
  IF oPos:lResItem .AND. ASCAN(oBrw:aArrayData,{|a,n| a[06]=oPos:cCodInv})>0

    nAt   :=ASCAN(oBrw:aArrayData,{|a,n| a[06]=oPos:cCodInv})
    IF nAt>0
      oPos:nCantid:=oBrw:aArrayData[nAt,03]+oPos:nCantid 
      lFound      :=.T.
      nPrecio:=oPos:GETPRECIOTAB()

      IF nPrecio>=0
        oPos:nPrecio:=nPrecio
      ENDIF
 
//      ? nPrecio,"nPrecio"
    ELSE
      nAt:=1
    ENDIF

  ENDIF

  oPos:dFchVen:=CTOD("")
  oPos:cMsgCod:="  no Existe "

  IF !oPos:VALCODIGO(.T.)

    IF Empty(oPos:aDataBal)
      oPos:SetMsgErr("Producto ["+ALLTRIM(oPos:cCodInv)+"],"+oPos:cMsgCod)
      oPos:SetMsgInv("")
    ENDIF

    DpFocus(oPos:oCodInv)

    oPos:oCodInv:Refresh() 

    RETURN .F.

  ENDIF

//  ? "AQUI DEBE VALIDAR EL PRECIO"

  IF !Empty(oPos:dFchVen) .AND. oPos:dFchVen<=oDp:dFecha 

     oPos:SetMsgErr("Producto ["+ALLTRIM(oPos:cCodInv)+"], Vencido ["+DTOC(oPos:dFchVen)+"]")
     oPos:SetMsgInv("")
     DpFocus(oPos:oCodInv)
     oPos:oCodInv:Refresh() 

    RETURN .F.

  ENDIF

  oPos:SetMsgErr("") // Borra el Mensaje de Error

  IF !lSave
    RETURN .T.
  ENDIF

//? "DEBE VALIDAR LOS DEMAS GETS",oPos:oCodInv:nId,oPos:oPrecio:nId

RETURN .T.

/*
// Ubica si el Item es el Ultimo 
*/

FUNCTION ISFINITEM(oControl)
  LOCAL I,nAt,oGet

  nAt:=ASCAN(oPos:aControls,{|o,n| oControl:nId=o:nId})

  // Busca el Siguiente
  nAt:=nAt+1

// ? nAt,"nAt"

  FOR I=nAt TO LEN(oPos:aControls)

//   ? oPos:aControls[I]:nId,I,nAt,EVAL(oPos:aControls[I]:bWhen),oPos:aControls[I]:ClassName()

    IF oGet=NIL .AND. EVAL(oPos:aControls[I]:bWhen)
       oGet:=oPos:aControls[I]
       RETURN .F.
    ENDIF

  NEXT I

  
  IF oGet=NIL
    oPos:SAVEITEM()
  ELSE
    DPFOCUS(oGet)
  ENDIF

RETURN .T.

FUNCTION SAVEITEM()
  LOCAL oBrw :=oPos:oBrwItem,lFound:=.F.
  LOCAL nAt  :=LEN(oBrw:aArrayData)
  LOCAL aLine:=oBrw:aArrayData[nAt]
  LOCAL cLine,cTotal,nLen,nPrecio:=0

  AEVAL(aLine,{|a,n|aLine[n]:=CTOEMPTY(a)})
  oPos:nBruto:=0  // Monto Bruto

  // 21/06/2024
  IF oPos:cTipDoc="DEV"
     oPos:nCantid:=oPos:nCantid*-1
     oPos:nPeso  :=oPos:nPeso  *-1
  ENDIF

  //29-08-2008 Colocar unidad de Medida oBrw:aArrayData[nAt,01]:=oPos:cCodInv+" "+ALLTRIM(FDP(oPos:nCantid,"999,999,999.999",.F.))+" X "+;
                           ALLTRIM(FDP(oPos:nPrecio,"999,999,999.99"))+CRLF+oPos:cMsgInv

  IF !oPos:lPeso

    oBrw:aArrayData[nAt,01]:=ALLTRIM(oPos:cCodInv)+" "+ALLTRIM(FDP(oPos:nCantid,"999,999,999.999",.F.))+" "+ALLTRIM(oPos:cUndMed)+" X "+;
                             ALLTRIM(FDP(oPos:nPrecio,"99,999,999,999.99"))+CRLF+oPos:cMsgInv
  ELSE

    oBrw:aArrayData[nAt,01]:=ALLTRIM(oPos:cCodInv)+" "+ALLTRIM(FDP(oPos:nPeso,"999,999,999.999",.F.))+" "+ALLTRIM(oPos:cUndMed)+" X "+;
                             ALLTRIM(FDP(oPos:nPrecio,"99,999,999,999.99"))+CRLF+ALLTRIM(oPos:cMsgInv)+" "+ALLTRIM(FDP(oPos:nCantid,"999,999,999.999",.F.))


  ENDIF

  //12-06-2008 Marlon Ramos oBrw:aArrayData[nAt,02]:=(oPos:nPrecio*oPos:nCantid)-PORCEN(oPos:nPrecio*oPos:nCantid,oPos:nDescxI)
  //16-07-2008 Marlon Ramos oBrw:aArrayData[nAt,02]:=ROUND((oPos:nPrecio*oPos:nCantid)-PORCEN(oPos:nPrecio*oPos:nCantid,oPos:nDescxI),2)

  IF Empty(oPos:nDescxI)
     oPos:nDescxI:=0
  ENDIF

  IF "BMC"$UPPE(oDp:cImpFiscal) .OR. "TFHK"$UPPER(oDp:cImpFiscal) // Cßlculo especial para BMC
     oBrw:aArrayData[nAt,02]:=ROUND(((oPos:nPrecio)-PORCEN(oPos:nPrecio,oPos:nDescxI))*(oPos:nIvaItem/100+1),2)*oPos:nCantid - ROUND((oPos:nPrecio-PORCEN(oPos:nPrecio,oPos:nDescxI))*oPos:nCantid/100*oPos:nIvaItem,2)
  ELSE
     oBrw:aArrayData[nAt,02]:=ROUND((oPos:nPrecio*oPos:nCantid)-PORCEN(oPos:nPrecio*oPos:nCantid,oPos:nDescxI),2)
  ENDIF

  // Clientes en Zona Libre no Pagan IVA
  // La tasa debe ser EXCENTA
  IF oPos:cZonaNL="L"
     oPos:nIvaItem:=0
     oPos:cIva    :="EX"
  ENDIF

  oBrw:aArrayData[nAt,03]:=oPos:nCantid 
  oBrw:aArrayData[nAt,04]:=oPos:nPrecio 
  oBrw:aArrayData[nAt,06]:=oPos:cCodInv
  oBrw:aArrayData[nAt,07]:=oPos:nIvaItem
  oBrw:aArrayData[nAt,08]:=oPos:cIva
  oBrw:aArrayData[nAt,09]:=oPos:cMsgInv
  oBrw:aArrayData[nAt,10]:=oPos:cUndMed
  oBrw:aArrayData[nAt,11]:=oPos:nCxUnd
  oBrw:aArrayData[nAt,12]:=oPos:cCodVen
  oBrw:aArrayData[nAt,13]:=oPos:nDescxI
  oBrw:aArrayData[nAt,14]:=oPos:nCapa
  oBrw:aArrayData[nAt,15]:=oPos:cLote
  oBrw:aArrayData[nAt,16]:=ACLONE(oPos:aTallas)

  oBrw:DrawLine(.T.)
  oPos:Calcular()

  IF !lFound
    AADD(oBrw:aArrayData,aLine)
  ENDIF

  oBrw:Refresh(.T.)
  oBrw:GoBottom(.T.)

  oPos:DISPITEM()

  oPos:oCodInv:VarPut(SPACE(20),.T.)
  oPos:oCantid:VarPut(1,.T.) // Resetea la Cantidad

  DpFocus(oPos:oCodInv)

// ViewArray(oBrw:aArrayData)

RETURN .T.

FUNCTION VALCODIGO(lPidPrec)
  LOCAL cCodEqui,lFound:=.F.,aData:={},I,aLine:={},cCodBar:={}
  LOCAL oBrw :=oPos:oBrwItem,nAt,nPrecio:=0,dFecha:=CTOD(""),nCol
  LOCAL nAt  :=LEN(oBrw:aArrayData)
  LOCAL cCod :="",cBar:="" // Codigo para Validar
  LOCAL aLine:=oBrw:aArrayData[nAt]
  LOCAL cWhere,cDescri
  LOCAL cWhereP

  DEFAULT lPidPrec:=.F.

  oPos:cCodEqu :=""
  oPos:cDescri :=""
  oPos:nIvaItem:=0
  oPos:ncXUnd  :=0
  oPos:aDataBal:={}
  oPos:lValCodInv:=oPos:lPrecio

  IF EMPTY(oPos:cCodInv)
    RETURN .F.
  ENDIF

  IF oPos:nNeto<0
    oPos:SetMsgErr("Debe Concluir la Devolución")
    RETURN .F.
  ENDIF

  IF oPos:lCodVen 

    SQLGET("DPVENDEDOR","VEN_CODIGO,VEN_NOMBRE","VEN_CODIGO"+GetWhere("=",oPos:cCodVen))

    IF !Empty(oDp:aRow)
      oPos:SetMsgInv("Vendedor "+oDp:aRow[2])
    ENDIF

  ENDIF

  /*
  // Validar no Utilizar el codigo de Barra del Producto
  */

  cCod   :=SQLGET("DPEQUIV"         ,"EQUI_CODIG","EQUI_BARRA"+GetWhere("=",oPos:cCodInv))
  cBar   :=SQLGET("DPINVCAPAPRECIOS","CAP_CODBAR","CAP_CODIGO"+GetWhere("=",cCod))

  IF !Empty(cCod) .AND. !Empty(cBar)
    oPos:cMsgCod:="Utilice Código Barra Alterno ["+ALLTRIM(cCod)+"]"
//    oPos:SetMsgErr("Utilice Código Barra Alterno ["+ALLTRIM(cCod)+"]")
    RETURN .F.
  ENDIF

  /*
  // Validar no Utilizar el codigo del Producto en Productos con Codigo de Barra Alternativo
  */

  cCod   :=SQLGET("DPINV"           ,"INV_CODIGO","INV_CODIGO"+GetWhere("=",oPos:cCodInv))
  cBar   :=SQLGET("DPINVCAPAPRECIOS","CAP_CODBAR","CAP_CODIGO"+GetWhere("=",oPos:cCodInv))

  IF !Empty(cCod) .AND. !Empty(cBar)

    oPos:cMsgCod:="Utilice Código Barra Alterno ["+ALLTRIM(cCod)+"]"

    // 21/09/2023

    RETURN .F.
  ENDIF

  IF Empty(cCod)
    EJECUTAR("FINDCODENAME","DPINV","INV_CODIGO","INV_DESCRI",oPos:oCodInv)
  ENDIF


  // JN, Lectura de codigo de barra, farmacia
  nPrecio:=SQLGET("DPINVCAPAPRECIOS","CAP_PRECIO,CAP_FCHVEN,CAP_CODIGO,CAP_CAPA,CAP_LOTE","CAP_CODBAR"+GetWhere("=",oPos:cCodInv))

  oPos:dFchVen:=CTOD("")
  oPos:nCapa  :=0
  oPos:cLote  :=""

  IF !Empty(nPrecio)
    oPos:cCodEqu:=oPos:cCodInv
    oPos:cCodInv:=DPSQLROW(3) // oDp:aRow[3]
    oPos:dFchVen:=DPSQLROW(2) // oDp:aRow[2]
    oPos:nCapa  :=DPSQLROW(4) // oDp:aRow[4]
    oPos:cLote  :=DPSQLROW(5) // oDp:aRow[5]
  ENDIF

  // oPos:lLbxIniGet:=.T. // buscador Inicial
  oDp:lLbxIniFind  :=.F.

  oDp:cLbxWhereAuto:=NIL
  oPos:cInvLbxWhere:=NIL

  IF SQLGET("DPINV","INV_CODIGO,INV_DESCRI,INV_IVA","INV_CODIGO"+GetWhere("=",oPos:cCodInv))!=oPos:cCodInv

    cCodEqui:=MYSQLGET("DPEQUIV","EQUI_CODIG","EQUI_BARRA"+GetWhere("=",oPos:cCodInv))


    IF Empty(cCodEqui) .AND. !Empty(oDp:cFileBal)
      EJECUTAR("DPPOSLEEBAL")  // Lectura de Balanza Bizerba

      //  Busca el Producto por el Nombre
      cWhere:="INV_CODIGO LIKE "+GetWhere("","%"+ALLTRIM(oPos:cCodInv)+"%")+" OR "+;
              "INV_DESCRI LIKE "+GetWhere("","%"+ALLTRIM(oPos:cCodInv)+"%")

      IF COUNT("DPINV",cWhere)=0
         RETURN .F.
      ENDIF

      // oPos:cInvLbxWhere:=cWhere
      oDp:lLbxIniFind  :=.T.
      oDp:cLbxWhereAuto:=cWhere

      EVAL(oPos:oCodInv:bAction)

      oDp:lLbxIniFind:=.F.

      RETURN .F.

    ENDIF

    oPos:cCodEqu:=cCodEqui
    oPos:cCodInv:=cCodEqui

    SQLGET("DPINV","INV_CODIGO,INV_DESCRI,INV_IVA","INV_CODIGO"+GetWhere("=",oPos:cCodInv))!=oPos:cCodInv

    oPos:lValCodInv:=.T.

  ENDIF

  oPos:oPrecio:Refresh(.T.)

  oPos:cMsgInv :=DPSQLROW(2) // oDp:aRow[2]
  oPos:cIva    :=DPSQLROW(3) // oDp:aRow[3]

  IF oPos:cZonaNL="N" .OR. Empty(oPos:cZonaNL)
     nCol:=2
  ELSE 
     nCol:=IIF(!oPos:cZonaNL="N",5,2)
  ENDIF

  oPos:nIvaItem:=EJECUTAR("IVACAL",oPos:cIva,nCol,oPos:dFecha) // IVA (Nacional o Zona Libre

  /*
  // Aplicación 10% Pago Electrónico
  */

  IF oPos:lPagEle
    oPos:cIva    :="PE"
    oPos:nIvaItem:=10
  ENDIF

// ? oDp:cMonedaExt,ROUND(nPrecio/oPos:nValCam,2)
//  oPos:SetMsgErr(" "+oDp:cMonedaExt+"="+FDP(ROUND(nPrecio/oPos:nValCam,2),"999,999,999.99"))

  oPos:SetMsgInv(oPos:cMsgInv)

//  +" "+oDp:cMonedaExt+"="+FDP(ROUND(nPrecio/oPos:nValCam,2),"999,999,999.99"))

// 25-08-2008 Marlon Ramos (Pedir Precios de Venta)

   // 16/10/2023 Según la Unidad de medida
   cWhereP:="PRE_CODMON"+GetWhere("=",oDp:cMonedaExt)+" AND "+;
            "PRE_LISTA" +GetWhere("=",oDp:cPrecioPos)+" AND "+;
            "PRE_UNDMED"+GetWhere("=",oDp:cUndMedPos)

   oPos:aPrecios:=ASQL("SELECT PRE_PRECIO*"+LSTR(oPos:nValCam)+",PRE_UNDMED,UND_CANUND,PRE_DESCUE FROM DPPRECIOS "+;
                      " INNER JOIN DPUNDMED ON PRE_UNDMED=UND_CODIGO "+;
                      " WHERE "+;
                      " PRE_CODIGO"+GetWhere("=",oPos:cCodInv)+" AND "+cWhereP+;
                      " ORDER BY PRE_PRECIO")

   // 16/10/2023   
   IF Empty(oPos:aPrecios)

      cWhereP:="PRE_CODMON"+GetWhere("=",oDp:cMonedaExt)+" AND "+;
               "PRE_LISTA" +GetWhere("=",oDp:cPrecioPos)
           

      oPos:aPrecios:=ASQL("SELECT PRE_PRECIO*"+LSTR(oPos:nValCam)+",PRE_UNDMED,UND_CANUND,PRE_DESCUE FROM DPPRECIOS "+;
                          " INNER JOIN DPUNDMED ON PRE_UNDMED=UND_CODIGO "+;
                          " WHERE "+;
                          " PRE_CODIGO"+GetWhere("=",oPos:cCodInv)+" AND "+cWhereP+;
                          " ORDER BY PRE_PRECIO")


   ENDIF

   // ? CLPCOPY(oDp:cSql)

//                      " AND PRE_LISTA"+GetWhere("=",oPos:cPrecio)+" ORDER BY PRE_PRECIO")

   // Asume la Unidad de Medida
  // ViewArray(oPos:aPrecios)

   IF LEN(oPos:aPrecios)=1

   ENDIF


   IF nPrecio=0 .AND. !oPos:PIDE_PRECIO(lPidPrec)
      oPos:cMsgCod:="No tiene Precio"
      RETURN .F.
   ENDIF

  // Buscamos el Precio
  // Código Restaurado por JN 13/01/2010

  IF LEN(oPos:aPrecios)>1
      oPos:nPrecio:=oPos:aPrecios[1,1] // Toma el Precio más Bajo
      oPos:cUndMed:=oPos:aPrecios[1,2] // Unidad de Medida
      oPos:ncXUnd :=oPos:aPrecios[1,3] // Cantidad por Grupo
      oPos:nDescxI:=oPos:aPrecios[1,4] // Descuento por Item
   ENDIF

   IF LEN(oPos:aPrecios)=1
      oPos:nPrecio:=oPos:aPrecios[1,1]
      oPos:cUndMed:=oPos:aPrecios[1,2]
      oPos:ncXUnd :=oPos:aPrecios[1,3] // Cantidad por Grupo
   ENDIF

   oPos:oPrecio:VarPut(oPos:nPrecio,.T.)

   nPrecio:=oPos:nPrecio // 20/11/2022

//   IF EVAL(oPos:oPrecio:bWhen)
//      DPFOCUS(oPos:oPrecio)
//   ENDIF

   // Fin de Restauración
   // Fin 25-08-2008 Marlon Ramos 
   // JN 8/6/2011 Farmacias

   IF nPrecio>0
      oPos:nPrecio:=nPrecio
   ENDIF

   IF !Empty(SQLGET("DPINV","INV_TALLAS","INV_CODIGO"+GetWhere("=",oPos:cCodInv)))

      EJECUTAR("OITEMTALLA",oPos:cCodInv,oPos:cColor,oPos:cTipDoc,oPos:oGrid,oPos)

   ELSE

      oPos:oGrid  :=NIL
      oPos:aTallas:={}

   ENDIF
  
   oPos:PRECIOIVA() // Genera Precios con IVA Incluido

   IF nPrecio=0 .AND. Empty(oPos:aPrecios)
     oPos:cMsgCod:="Producto no Tiene Precio"
     RETURN .F.
   ENDIF
 
   IF EMPTY(oPos:cCodInv)
     RETURN .F.
   ENDIF

   cDescri   :=SQLGET("DPINV","INV_DESCRI,INV_REQPES","INV_CODIGO"+GetWhere("=",oPos:cCodInv))
   oPos:lPeso:=("S"=DPSQLROW(2,""))

   oPos:SetMsgInv(cDescri)
   oPos:oBrwItem:aArrayData[oPos:oBrwItem:nArrayAt,1]:=cDescri
   oPos:oBrwItem:aArrayData[oPos:oBrwItem:nArrayAt,2]:=nPrecio 

   oPos:oBrwItem:DrawLine(.T.)
   oPos:ISFINITEM(oPos:oCodInv)

RETURN .T.

// Cambiar el BMP del Boton
FUNCTION POSSETBMP()
  LOCAL oBtn,aFile:=ARRAY(5),aRes:=ARRAY(5)

  oBtn:=oPos:aBtnBmp[1,1]

  aFile[1]:="bitmaps\xsalir.bmp"

  oBtn:LoadBitmaps( aRes, aFile )

RETURN .T.

FUNCTION BtnRefresh(nPag)
  LOCAL nLin:=0,aPage,aGrupo,U,I,aBtn,aSize
  LOCAL oBtn,aFile:=ARRAY(oPos:nCols),aRes:=ARRAY(oPos:nCols)

  oBtn :=oPos:aBtnBmp[1,1]
  aSize:={oBtn:nWidth,oBtn:nHeight}

  DEFAULT nPag:=1

  aGrupo:=oPos:aPagina[nPag]

  oPos:nPag:=nPag

  FOR I=1 TO LEN(aGrupo)
    FOR U=1 TO LEN(aGrupo[I])

      aBtn:=aGrupo[I,U]

      IF aBtn[1]!="Nada"
        oBtn:=oPos:aBtnBmp[I,U]

      // 17-08-2008 Marlon Ramos (Mostrar tecla de función asociada al bot¾n)
      //oBtn:SetText( aBtn[1], 40, 5, nil, nil,nil )
         oBtn:SetText( IIF(LEFT(aBtn[1],1)="F" .AND. VAL(SUBSTR(aBtn[1],2,1))>0,LEFT(aBtn[1],3),"")+CRLF+CRLF+CRLF+RIGHT(aBtn[1],LEN(aBtn[1])-IIF(LEFT(aBtn[1],1)="F" .AND. VAL(SUBSTR(aBtn[1],2,1))>0,3,0)), 5, 2, nil, nil , nil )
      // Fin 17-08-2008 Marlon Ramos 

        aFile[1]:="bitmaps\"+aBtn[2,1]
        aFile[2]:="bitmaps\"+aBtn[2,2]
        oBtn:LoadBitmaps( aRes, aFile )
        oBtn:SetSize(aSize[1],aSize[2])
        oBtn:bWhen  :=aBtn[3]
        oBtn:bAction:=aBtn[4]
      ENDIF
    NEXT U
  NEXT I
RETURN .T.

FUNCTION POSCERRAR()
  oPos:Close()
RETURN .T.

FUNCTION POSCLIENTE()
  LOCAL cRif
  // 26-06-2008 Marlon Ramos (No permitir cambiar el cliente de una devolución)
 
  IF oPos:nNeto<0
    oPos:SetMsgErr("No puede Cambiar Cliente")
    RETURN .F.
  ENDIF
  // Fin 26-06-2008 Marlon Ramos 

  EJECUTAR('DPCLIENTESCERO',oPos,NIL)

  cRif:=LEFT(oPos:CCG_RIF,1)

  IF oPos:lPagEle .AND. !(ISALLDIGIT(cRif) .OR. (cRif="V" .OR. cRif="E"))
    oPos:SetMsgErr("No Puede Facturar Persona Jurídica ["+ALLTRIM(oPos:CCG_RIF)+"] para Pago Electrónico")
    RETURN .F.
  ENDIF

  IF !oPos:PAGELE_LIMITE()
     RETURN .F.
  ENDIF

RETURN .T.

// Indica el Mensaje de Error, Cuando el Producto No Existe
FUNCTION SetMsgErr(cText)

   IF !EMPTY(oPos:cMsgErr) .AND. Empty(cText) // Vacia el Mensaje
     oPos:cMsgErr:=SPACE(40)
     oPos:oMsgErr:Hide()
     oPos:oMsgErr:Show()
     RETURN .T.
   ENDIF

   IF Empty(cText) .OR. (oPos:cMsgErr=cText)
      RETURN .T.
   ENDIF

//   SndPlaySound( "SOUNDS\_LASER.WAV", 1 )
   oPos:oMsgErr:Hide()
   oPos:cMsgErr:=cText
   oPos:oMsgErr:Show()
RETURN .T.

FUNCTION SetMsgInv(cText)
  IF cText=oPos:cMsgInv
//      RETURN .T.
  ENDIF

  oPos:cMsgInv:=cText
  oPos:oMsgInv:Hide()
  oPos:oMsgInv:Show()

RETURN .T.

FUNCTION Efectivo()

    IF oPos:nNeto<=0
      oPos:SetMsgErr("No hay Venta")
      RETURN .F.
    ENDIF

   IF oPos:lPagEle
      oPos:SetMsgErr("Requiere sólo pago Electrónico")
      RETURN .F.
   ENDIF

   IF !oPos:PAGELE_LIMITE()
     RETURN .F.
   ENDIF

   oPos:DISPTOTAL()

   IF oPos:nNeto<0

     IF !oDp:TIKLDEVEFECT
       oPos:SetMsgErr("No Puede Devolver Dinero")
       RETURN .F.
     ENDIF

     RETURN MsgNoYes("Desea Realizar Devolución en Efectivo","Devolver Dinero")

  ENDIF

RETURN EJECUTAR("DPPOSEFECTIVO",oPos)

FUNCTION EFECTIVOYCESTA()

  IF oPos:nNeto<=0
    oPos:SetMsgErr("No hay Venta")
    RETURN .F.
  ENDIF

  IF oPos:lPagEle
    oPos:SetMsgErr("Requiere Pago Electrónico")
    RETURN .F.
  ENDIF

  oPos:DISPTOTAL()

RETURN EJECUTAR("DPPOSEFEYCESTA",oPos)

FUNCTION TarjetaCre(cTipo)

  IF oPos:nNeto<=0
    oPos:SetMsgErr("No hay Venta")
    RETURN .F.
  ENDIF

  oPos:DISPTOTAL()        //28-05-2008 Marlon Ramos

  EJECUTAR("DPPOSTARJETACRE",oPos)

RETURN .T.
// Pago con Cheque
FUNCTION Cheque()

  IF oPos:nNeto<=0
    oPos:SetMsgErr("No hay Venta")
    RETURN .F.
  ENDIF

  IF oPos:lPagEle
     oPos:SetMsgErr("Requiere sólo pago Electrónico")
     RETURN .F.
  ENDIF

  oPos:DISPTOTAL()

RETURN EJECUTAR("DPPOSCHEQUE",oPos)

// Pago con Cesta Ticket
FUNCTION CESTATICKET()

  IF oPos:nNeto<=0
    oPos:SetMsgErr("No hay Venta")
    RETURN .F.
  ENDIF

  IF oPos:lPagEle
     oPos:SetMsgErr("Requiere sólo pago Electrónico")
     RETURN .F.
  ENDIF

  oPos:DISPTOTAL()

RETURN EJECUTAR("DPPOSCESTA",oPos)

FUNCTION TARDEBITO()

  IF oPos:nNeto<=0
    oPos:SetMsgErr("No hay Venta")
    RETURN .F.
  ENDIF

  IF !oPos:PAGELE_LIMITE()
     RETURN .F.
  ENDIF

  oPos:DISPTOTAL()

RETURN EJECUTAR("DPPOSDEBITO",oPos)

FUNCTION TicketWait()
  LOCAL lNew:=.T.

  ADEL(oPos:aDataWait)
  AEVAL(oPos:oBrwItem:aArrayData,{|a,n| IIF(a[2]>0, AADD(oPos:aDataWait,a) , NIL)  })

  oPos:lTikWait:=!oPos:lTikWait
  oPos:POSREINI(lNew)
RETURN 

FUNCTION TicketRestore(lImport)
  LOCAL aData :=oPos:aDataWait 
  LOCAL oBrw  :=oPos:oBrwItem 
  LOCAL nAt   :=LEN(oPos:oBrwItem)
  LOCAL nAt1  :=LEN(aData),aItems:={}

  IF lImport
    ASIZE(oPos:oBrwItem:aArrayData,LEN(oPos:oBrwItem:aArrayData)-1)
    AEVAL(oPos:aImport,{|a,n| IIF(a[2]>0, AADD(oBrw:aArrayData,a) , NIL)  })
    AADD(oBrw:aArrayData,{SPACE(50),0,0,0,SPACE(6),"6CODIGO",7,"8CIVA","9DESCRI","10UND","11cXUnd","12CODVEN",0})

    oPos:POSREINI(.F.)
    oPos:oBrwItem:Refresh(.T.)
    oPos:Calcular()
    oPos:aImport:=ACLONE(aItems)
  ENDIF

  IF !oPos:lTikWait .AND. !lImport

    MensajeErr("No hay Ticket en Espera")

  ELSE

    ASIZE(oPos:oBrwItem:aArrayData,LEN(oPos:oBrwItem:aArrayData)-1)
    AEVAL(aData,{|a,n| IIF(a[2]>0, AADD(oBrw:aArrayData,a) , NIL)  })
    AADD(oBrw:aArrayData,{SPACE(50),0,0,0,SPACE(6),"6CODIGO",7,"8CIVA","9DESCRI","10UND","11cXUnd","12CODVEN",0})

    oPos:POSREINI(.F.)
    oPos:oBrwItem:Refresh(.T.)
    oPos:Calcular()
    oPos:aDataWait:=ACLONE(aItems)
    oPos:lTikWait:=!oPos:lTikWait
  ENDIF

RETURN 

FUNCTION ANULA()
  IF MsgYesNo("Esta seguro de borrar la transacción ?","Advertencia")	
    oPos:POSREINI(.T.)
  ENDIF
RETURN

FUNCTION SAVETICKET(lPrint)
RETURN EJECUTAR("DPPOSSAVE",lPrint,oPos)

FUNCTION POSREINI(lNew)
  LOCAL aItems:={}

  // 12-06-2008 Marlon Ramos AADD(aItems,{SPACE(50),0,0,0,SPACE(6),"6CODIGO",7,"8CIVA","9DESCRI","10UND","11cXUnd","12CODVEN",0})
  // JN 21/01/2021 incluye columna 17 es valor del dolar 
  AADD(aItems,{SPACE(50),0.00,0.00,0.00,SPACE(6),"6CODIGO",7,"8CIVA","9DESCRI","10UND","11cXUnd","12CODVEN",0,"14NCAPA","15nLOTE",{}})

  IF lNew

    oPos:DISPFINAL()

    oPos:oBrwItem:aArrayData:=ACLONE(aItems)
    oPos:oBrwItem:nArrayAt:=1
    oPos:oBrwItem:nRowSel :=1
    oPos:oBrwItem:Refresh(.T.)

    oPos:nNeto :=0
    oPos:nBruto:=0
    oPos:nIva  :=0
    oPos:nDocDesc:=0            // 12-06-2008 Marlon Ramos

    oPos:nEfectivo  :=0     
    oPos:nRecibe    :=0      
    oPos:nVuelto    :=0      
    oPos:nCheque    :=0
    oPos:nCesta     :=0 
    oPos:nIGTF      :=0

    oPos:cCodVen    :=oPos:cCodVenIni
    oPos:SetMsgInv("Introduzca Código del Producto")

    oPos:oBruto:Refresh(.t.)
    oPos:oIva:Refresh(.t.)
    oPos:oNeto:Refresh(.t.)
    oPos:oIGTF:Refresh(.T.)
    oPos:oNetoUsd:Refresh(.T.)


//  oPos:oDocDesc:Refresh(.t.)   //12-06-2008 Marlon Ramos (Reflejar el descuento en pantalla)

    oPos:cTicketDev :="" // Ticket Devolución
/*
    IF oPos:cCodCli=REPLI("0",10) .AND. Empty(oPos:cNomCli) 
       oPos:SetMsgErr("Introduzca Nombre del Cliente")
       DPFOCUS(oPos:oCodCli)
       RETURN .F.
    ENDIF  
*/
   oPos:cNomCli:=SQLGET("DPCLIENTES","CLI_NOMBRE","CLI_CODIGO"+GetWhere("=",oPos:cCodCli))
   oPos:oNomCli:VarPut(oPos:cNomCli,.T.)

//  EJECUTAR("DISPRUN",oDp:cEmpresa,"Punto de Venta")
  ENDIF

RETURN aItems
// Usuario Cerrado
FUNCTION CierreUs()
  IF !Empty(oPos:nNeto)
    oPos:SetMsgErr("Debe Concluir la Venta")
    RETURN .F.
  ENDIF

  REPORTE("CIERREDIA")
RETURN .T.

// Impresion BemaTech
FUNCTION IMPRIMIR(lVenta)
  RETURN EJECUTAR("DPPOSPRINT",lVenta)
RETURN .T.

// Quita la Ultima Venta
FUNCTION DESHACER()
  LOCAL oBrw:=oPos:oBrwItem
  LOCAL nAt :=LEN(oPos:oBrwItem:aArrayData)-1

  IF Empty(nAt)
     RETURN .F.
  ENDIF

  IF !Empty(oPos:cCodInv)
    nAt:=ASCAN(oPos:oBrwItem:aArrayData,{|a,n|a[6]=oPos:cCodInv})
    IF nAt=0
      SetMsgInv("")
      SetMsgErr("C¾digo : "+ALLTRIM(oPos:cCodInv)+" no estß en Ticket")
      RETURN .F.
    ENDIF
  ENDIF

  IF oPos:oBrwItem:aArrayData[oPos:oBrwItem:nArrayAt,04]=0
    ADEL(oPos:oBrwItem:aArrayData,nAt)
    ASIZE(oPos:oBrwItem:aArrayData,nAt)
    oPos:oBrwItem:Refresh(.F.)
    oPos:oBrwItem:GoBottom(.T.)
  ELSE
    ADEL(oPos:oBrwItem:aArrayData,oPos:oBrwItem:nArrayAt)
    ASIZE(oPos:oBrwItem:aArrayData,nAt)
    oPos:oBrwItem:Refresh(.F.)
    oPos:oBrwItem:GoBottom(.T.)
  ENDIF

  oPos:CALCULAR()

  DPFOCUS(oPos:oCodInv)
RETURN .T.
FUNCTION CALCULAR(aData)
  LOCAL aTotal

  DEFAULT aData:=oPos:oBrwItem:aArrayData

  aTotal:=ATOTALES(aData)

  oPos:nNeto  :=0
  oPos:nIva   :=0
  oPos:nBruto :=0
  oPos:nCanTot:=0


  // JN 01/03/2011, Si el Cliente es Zona Libre el IVA sera Cero
  IF oPos:cZonaNL="L"
    AEVAL(aData,{|a,n| aData[n,7]:= 0 , aData[n,8]:="EX" })
  ENDIF

  /* 02-06-2008 Marlon Ramos (Se redondea el iva para Evitar descuadres y se toma el descuento)
   AEVAL(aData,{|a,n,nIva|oPos:nBruto :=oPos:nBruto +a[2],;
                         oPos:nCanTot:=oPos:nCanTot+a[3],;
                         nIva        :=PORCEN(a[2],a[7]),;
                         oPos:nIva   :=oPos:nIva+nIva})
   oPos:nNeto :=oPos:nBruto+oPos:nIva
  */

  //viewarray(aData)
/*  AEVAL(aData,{|a,n,nIva|oPos:nBruto :=oPos:nBruto +a[2],;
                         oPos:nCanTot:=oPos:nCanTot+a[3],;
                         nIva        :=oPos:REDONDEA(a[2]/100*a[7]),;
                         oPos:nIva   :=oPos:nIva+nIva})
*/
  // 16-07-2008 Marlon Ramos (Cßlculo especial para BMC)
  IF "BMC"$UPPE(oDp:cImpFiscal) 

	  AEVAL(aData,{|a,n,nIva,nBruto|nBruto:=ROUND(a[2]/100*a[7],2),;
                         oPos:nBruto :=oPos:nBruto +a[2],;
                         oPos:nCanTot:=oPos:nCanTot+a[3],;
                         nIva        :=ROUND(a[2]/100*a[7],2),;
                         oPos:nIva   :=oPos:nIva+nIva})

  ELSE

	  AEVAL(aData,{|a,n,nIva|oPos:nBruto :=oPos:nBruto +a[2],;
                         oPos:nCanTot:=oPos:nCanTot+a[3],;
                         nIva        :=a[2]/100*a[7],;
                         oPos:nIva   :=oPos:nIva+nIva})
  ENDIF

  // Fin 16-07-2008 Marlon Ramos nIva        :=ROUND(a[2]/100*a[7],2),;

  //?"oPos:nDocDesc!=0", oPos:nDocDesc != 0   

  oPos:nNeto:=oPos:nBruto   

  IF oPos:nDocDesc != 0       //Si hay descuento total
  	//?"oPos:nBruto antes Calcular",oPos:nBruto
     //oPos:nBruto:=REDONDEA(oPos:nBruto-(oPos:nBruto/100*oPos:nDocDesc),2)

     oPos:nNeto:=oPos:nBruto-ROUND(oPos:nBruto/100*oPos:nDocDesc,2)

  	//?"oPos:nBruto desp Calcular",oPos:nBruto
     //oPos:nIvA  :=oPos:nIva-ROUND(PORCEN(oPos:nIva,oPos:nDocDesc),2)
     //?"oPos:nIvA  antes ",oPos:nIva
     //oPos:nIvA  :=ROUND(oPos:nIva-(oPos:nIva/100*oPos:nDocDesc),2)
     oPos:nIvA  :=oPos:nIva-ROUND(oPos:nIva/100*oPos:nDocDesc,2)
     //?"oPos:nIvA  desp ",oPos:nIva

  ENDIF

  // 11/07/2022
  // Devolución con Items Agregados se convierte en Factura/Tickets
  IF (oPos:cTipDoc="DEV" .OR. oPos:cTipDoc="CRE") .AND. oPos:nNeto>0
     oPos:SetTipDoc(oPos:cTipFav,.F.)
  ENDIF

  oPos:nIva  :=IF(oPos:lCalIva,oPos:nIva,0)
  oPos:nNeto :=STR(oPos:nNeto+ROUND(oPos:nIva,2),19,5)
  oPos:nNeto :=VAL(oPos:nNeto) 

  // IGTF Debe ser negativo
  IF oPos:nNeto<0
    oPos:nIGTF:=ABS(oPos:nIGTF)*-1
  ELSE
    oPos:nIGTF:=ABS(oPos:nIGTF)
  ENDIF

  oPos:oIGTF:Refresh(.T.)

  // ? oPos:nNeto
  //  oPos:nNeto :=VAL(LEFT( oPos:nNeto,IIF( AT(".",oPos:nNeto)>0,AT(".",oPos:nNeto)-1,LEN(oPos:nNeto) ) )+IIF( AT(".",oPos:nNeto)>0, SUBSTR( oPos:nNeto,AT(".",oPos:nNeto),3 ),"" ))
  // FIN 02-06-2008 Marlon Ramos
  //viewarray(aData)
  //?"Ojo (Calcular)",oPos:nNeto

  oPos:oBruto:Refresh(.t.)
  oPos:oIva:Refresh(.t.)
  oPos:oNeto:Refresh(.t.)
  oPos:oDocDesc:Refresh(.t.)   //12-06-2008 Marlon Ramos (Reflejar el descuento en pantalla)
  oPos:oNetoUsd:Refresh(.T.)

//EJECUTAR("BRWCALTOTALES",oPos:oBrwItem)
    
  oPos:oBrwItem:aCols[2]:cFooter:=TRAN(aTotal[2],"999,999,999,999.99")
  oPos:oBrwItem:aCols[3]:cFooter:=TRAN(aTotal[2]/oPos:nValCam,"999,999,999,999.99")
  oPos:oBrwItem:RefreshFooters()


  oPos:oBtnSave:ForWhen(.T.)

  IF !oPos:PAGELE_LIMITE()
     RETURN .F.
  ENDIF

RETURN .T.

/* Redondea a dos decimales (se reemplaza por la función ROUND() porque en algunos casos 
 el redondeo no cuadra con el aplicado por la impresora fiscal en el ticket el cual siempre 
 toma en cuenta hasta el tercer decimal.
 Ej: 47.25/100*9 --> RESULTADO 4.2525  Aplicando ROUND()   --> Resultado 4.26
 Sin embargo el ticket se imprime por 4.25
 Ej: 47.25/100*9 --> RESULTADO 4.2525  Aplicando REDONDEA()--> Resultado 4.25
*/
FUNCTION REDONDEA(nTotal,nCantDecim)
  LOCAL nEntero:=0,nDecimal:=0, nContador, cNvoValor:=""
  LOCAL cEntero:="",cDecimal:="", lSw_Mayor:=.F.
  DEFAULT nTotal:=0, nCantDecim:=2

  nTotal  := STR(nTotal,16,5)
  cEntero :=LEFT ( nTotal, IIF( AT(".",nTotal)>0,AT(".",nTotal)-1,LEN(nTotal) ) )
  cDecimal:=RIGHT( nTotal, IIF( AT(".",nTotal)>0,LEN(nTotal)-AT(".",nTotal), 0 ) )

//  ?"Entero",cEntero 
//  ?"Decimal",cDecimal
  
  IF LEN(cDecimal)>0
     IF nCantDecim < LEN(cDecimal)
        nDecimal:=VAL(SUBSTR(cDecimal, nCantDecim+1,1))  //Buscar el dÝgito siguiente al que se quiere redondear
        IF nDecimal >= 5
           lSw_Mayor:=.T.
           FOR nContador=nCantDecim TO 1 STEP -1
               nTotal:=VAL(SUBSTR(cDecimal, nContador,1))
               //?"nContador",nContador,"Val de nTotal",ntotal,"substr",SUBSTR(cDecimal, nContador,1)
               IF lSw_Mayor
                  nTotal:=nTotal+1
                  //?"nTotal+1",nTotal
               ENDIF
               //?"RIGHT totl",RIGHT(ALLTRIM(STR(nTotal)),1)
               cNvoValor:=RIGHT(ALLTRIM(STR(nTotal)),1)+cNvoValor
               //?"cNvoValor",cNvoValor
               lSw_Mayor:=nTotal>9
           NEXT
        ENDIF
     ELSE
        cNvoValor:=cDecimal
     ENDIF
  ENDIF
  IF lSw_Mayor
     cEntero := STR(VAL(cEntero)+1)
  ENDIF
  
cEntero:= cEntero + "." +cNvoValor
?cEntero,VAL(cEntero)
//?VAL(cEntero + "." +cNvoValor)
//RETURN VAL(cEntero + "." +cNvoValor)
RETURN VAL(cEntero)
//*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*  

// Calcula el Precio Sin IVA
FUNCTION PRECIOIVA(nTotal)
  LOCAL nIva:=0,nPrecio:=0,nRata

  DEFAULT nTotal:=0

  IF !oPos:lPrecioIva
    RETURN nTotal
  ENDIF

  nRata       :=DIV(oPos:nIvaItem,100)+1
  oPos:nPrecio:=DIV(oPos:nPrecio,nRata)
  oPos:oPrecio:Refresh(.T.)

//  nTotal :=DIV(nTotal ,nRata)

RETURN DIV(nTotal,nRata)


FUNCTION DISPITEM()
  LOCAL cLine,nLen,cTotal

//LSTR(oPos:nPrecio,10,IIF(oPos:nPrecio=INT(oPos:nPrecio),0,2))+"X"+;
//         LSTR(oPos:nCantid,10,IIF(oPos:nCantid=INT(oPos:nCantid),0,2))

  cLine:=ALLTRIM(FDP(oPos:nPrecio,"9,999,999"+FDEC(oPos:nPrecio),.F.))+"X"+;
         ALLTRIM(FDP(oPos:nCantid,"9999999"  +FDEC(oPos:nCantid),.F.))

  cTotal:="="+ALLTRIM(FDP(oPos:nNeto,"999,999,999.99",.F.))

  IF LEN(cTotal+cLine)>20
    cLine:=ALLTRIM(FDP(oPos:nPrecio,"9999999"+FDEC(oPos:nPrecio),.F.))+"X"+;
           ALLTRIM(FDP(oPos:nCantid,"9999999"+FDEC(oPos:nCantid),.F.))
  ENDIF

  IF LEN(cTotal+cLine)>20
    cTotal:="="+ALLTRIM(FDP(oPos:nNeto,"999999999.99",.F.)+" ")
  ENDIF

  IF "LPT"$oDp:cDisp_Com
    nLen  :=19-LEN(cLine)
  ELSE
    nLen  :=20-LEN(cLine)
  ENDIF

  cLine :=ALLTRIM(cLine)+PADL(cTotal,nLen)

  EJECUTAR("DISPRUN",oPos:cMsgInv,cLine)
RETURN .T. 

FUNCTION DISPTOTAL()
  LOCAL cLine1,cLine2,nLen,cTotal

//cLine1:="TOTAL "+oDp:cMoneda+" "+FDP(nMonto,"999,999,999.99",NIL,.T.)

  cLine1:="TOTAL "+oDp:cMoneda
  cTotal:=FDP(oPos:nNeto,"999,999,999.99",NIL,.T.)
  nLen  :=20-LEN(cLine1)
  cLine1:=cLine1+PADL(cTotal,nLen)

  cLine2:="IVA"
  cTotal:=FDP(oPos:nIva,"999,999,999.99",NIL,.T.)

  IF "LPT"$oDp:cDisp_Com
    nLen  :=19-LEN(cLine2)
  ELSE
    nLen  :=20-LEN(cLine2)
  ENDIF

  cLine2:=cLine2+PADL(cTotal,nLen)

//cLine2:="IVA:"  +FDP(oPos:nIva   ,"999,999,999.99",NIL,.T.)

  EJECUTAR("DISPRUN",cLine1,cLine2)
RETURN .T.


FUNCTION DISPFINAL()
  LOCAL cLine1,cLine2,nLen,cTotal

  cLine1:="Muchas Gracias"

  IF !Empty(oPos:nVuelto)
    cLine1:="VUELTO" // +FDP(oPos:nVuelto,"999,999,999.99",NIL,.T.)
    cTotal:=FDP(oPos:nVuelto,"999,999,999.99",NIL,.T.)
    nLen  :=20-LEN(cLine1)
    cLine1:=cLine1+PADL(cTotal,nLen)
  ENDIF
    
  cLine2:="Cant. Productos:"+FDP(oPos:nCanTot,"999,999,999.999",.F.,.T.)

  IF LEN(cLine2)>20
    cLine2:="Productos:"+FDP(oPos:nCanTot,"999,999,999.999",.F.,.T.)
  ENDIF

  EJECUTAR("DISPRUN",cLine1,cLine2)
RETURN .T.

FUNCTION BRWGRUPOS()
  LOCAL cCodigo:=""
  cCodigo:=EJECUTAR("DPPOSSELGRU",oPos)
RETURN .T.

FUNCTION BRWMARCAS()
  LOCAL cCodigo:=""
  cCodigo:=EJECUTAR("DPPOSSELMARCAS",oPos)
RETURN .T.

// Avance de Pßginas
FUNCTION PAGSKIP(nSkip,nPage)
  LOCAL nOld:=oPos:nPag

  oPos:nPag:=oPos:nPag+nSkip
  IF nPage<>NIL
    oPos:nPag:=nPage
  ENDIF
  oPos:nPag:=MIN(oPos:nPag,LEN(oPos:aPagina))
  oPos:nPag:=MAX(oPos:nPag,1                )

  IF oPos:nPag<>nOld
    oPos:BtnRefresh(oPos:nPag)
  ENDIF
RETURN .T.

FUNCTION PUTTECLA(cKey,oGet)
  LOCAL cText

  DEFAULT oGet:=oPos:oCodInv

  cText:=EVAL(oGet:bSetGet)
  cText:=PADR(ALLTRIM(ctext)+cKey,LEN(cText))

  oGet:VarPut(cText,.T.)
  DpFocus(oGet)
  oGet:KeyBoard(35) // VK_END              35        //  0x23
 
RETURN .T.

FUNCTION SETCODIGO(cCodigo)
  IF !EMPTY(cCodigo)
    oPos:oCodInv:VarPut(cCodigo)
    oPos:oCodInv:KeyBoard(13)
  ENDIF
RETURN .T.

FUNCTION VALCODVEN()

  IF !SQLGET("DPVENDEDOR","VEN_CODIGO,VEN_NOMBRE","VEN_CODIGO"+GetWhere("=",oPos:cCodVen))==oPos:cCodVen
    oPos:SetMsgErr("Vendedor "+oPos:cCodVen+" no Existe")
    RETURN .F.
  ENDIF

  SetMsgInv("Vendedor "+oDp:aRow[2])

  oPos:oNomVen:Refresh(.T.)
  oPos:SaveVenta(.T.)

RETURN .T.

FUNCTION PosKeyDown(nKey)
  LOCAL aGrupo,I,U,aBtn

// n{|nKey|IIF(!oPos:lCantid .AND. (nKey=13 .OR. nKey=9), oPos:SaveVenta(!oPos:lCodVen),NIL )}
//  ? nKey

  IF !oPos:lCantid .AND. (nKey=13 .OR. nKey=9 .OR. nKey=33 .OR. nKey=34)
    IF(nKey=33,oPos:oBrwItem:GoUp())
    IF(nKey=34,oPos:oBrwItem:GoDown())
    oPos:SaveVenta(!oPos:lCodVen)
  ENDIF

  aGrupo:=oPos:aPagina[oPos:nPag]

  IF nKey=67
     RETURN .T.
  ENDIF
 

//  oDp:oFrameDp:SetText(LSTR(nKey))

  FOR I=1 TO LEN(aGrupo)
    FOR U=1 TO LEN(aGrupo[I])
      aBtn:=aGrupo[I,U]
      IF aBtn[5]=nKey
        // ?aBtn[1]
        EVAL(aBtn[4])
      ENDIF
    NEXT U
  NEXT I
RETURN .T.

FUNCTION BemaErr(cError)
  IF !Empty(cError)
    oPos:lImpErr:=.T.

    SQLUPDATE("DPDOCCLI","DOC_IMPRES",0,"DOC_CODSUC"+GetWhere("=",oPos:cCodSuc)+" AND "+;
                                        "DOC_TIPDOC"+GetWhere("=",oPos:cTipDoc)+" AND "+;
                                        "DOC_NUMERO"+GetWhere("=",oPos:DOC_NUMERO))

    MensajeErr("Error en Impresión, Es necesario Reimprimir el Ticket",cError)
  ENDIF
RETURN .T.

FUNCTION VALCANTID()

  IF !oDp:TIKLDEVUELVE .AND. oPos:nCantid<0
    oPos:SetMsgErr("Devolución no Autorizada")
    oPos:SetMsgInv("")
    RETURN .F.
  ENDIF 

  oPos:ISFINITEM(oPos:oCantid)

RETURN .T.


////////////////////////////////////////////////////////////////////////////////////////////////////////
// 25-08-2008 Marlon Ramos (Permite seleccionar entre los precios de Venta Definidos para el producto)
////////////////////////////////////////////////////////////////////////////////////////////////////////
FUNCTION PIDE_PRECIO(lPrec)
  LOCAL cTipoPrec,cTipoUnid,lEsDev,nPosic,cAuxPrec,nPrecio:=0
  LOCAL cMap:=MYSQLGET("DPUSUARIOS","OPE_MAPMNU","OPE_NUMERO"+GetWhere("=",oDp:cUsuario))

  IF !lPrec
    RETURN .T.
  ENDIF
  IF oPos:nNeto<0
    oPos:SetMsgErr("No se Permite Cambiar precios a una Devolución")
    RETURN .F.
  ENDIF 

  IF LEN(oPos:aPrecios)=0
     SetMsgErr("No se Encontrá ningún Precio para el  Producto: "+ALLTRIM(oPos:cCodInv))
     RETURN .F.
  ENDIF

  //IF cMap="ADM"
    /* EXISTENCIA oPos:aPrecios:=ASQL("SELECT MOV_CODIGO,SUM(IF(MOV_FECHA"+GetWhere("<=",oDp:dFecha)+" OR (MOV_FECHA"+GetWhere("=",oDp:dFecha)+" AND MOV_HORA"+GetWhere("<",TIME())+"),DPMOVINV.MOV_CANTID*MOV_FISICO*MOV_CXUND ,0)) AS MOV_CANTID ;
      FROM DPMOVINV WHERE MOV_CODIGO"+GetWhere("=",oPos:cCodInv)+" AND MOV_CODALM"+GetWhere("=",oDp:cAlmacen)+" AND MOV_CODSUC"+GetWhere("=",oDp:cSucursal)+" AND MOV_INVACT=1 AND MOV_FISICO<>0  ;
      GROUP BY MOV_CODIGO") 
      ViewArray(oPos:aPrecios)
 */

     // JN 02/06/2013. (Precios por Tabulador)

     nPrecio:=0

     IF LEN(oPos:aPrecios)>1

        nPrecio:=oPos:GETPRECIOTAB() // Obtiene el Precio Tabulado

        IF nPrecio>0
           oPos:aPrecios[1,1]:=nPrecio   
        ENDIF 

     ENDIF

     IF LEN(oPos:aPrecios)>1 .AND. nPrecio=0
/*
        aUndMed:=ASQL("SELECT PRE_UNDMED FROM DPPRECIOS "+;
                      " PRE_CODIGO"+GetWhere("=",oPos:cCodInv)+" AND PRE_LISTA"+GetWhere("=",

*/


/*
        cAuxPrec:=EJECUTAR("REPBDLIST","DPPRECIOS",{"PRE_LISTA","PRE_UNDMED","UND_CANUND","PRE_PRECIO","PRE_DESCUE","PRE_REQUIE"},NIL,;
                     " INNER JOIN DPUNDMED ON PRE_UNDMED=UND_CODIGO "+;
                     " WHERE "+;
                      " PRE_CODIGO"+GetWhere("=",oPos:cCodInv),;
                     "Seleccionar Precios de Venta",;
                     {"Tipo","Und Med","CanxUnd","Precio","Dscto"},NIL,NIL,.T.)

        IF Valtype(cAuxPrec)!="C" .AND. !Empty(cAuxPrec)
           cTipoPrec:=oPos:cPrecio
        ENDIF

        nPosic:=AT("|||",cAuxPrec)
        cTipoPrec:=LEFT(cAuxPrec,nPosic-1)
        cTipoUnid:=RIGHT(cAuxPrec,LEN(cAuxPrec)-nPosic-2)
        oPos:aPrecios:=ASQL("SELECT PRE_PRECIO,PRE_UNDMED,UND_CANUND,PRE_DESCUE FROM DPPRECIOS "+;
                      " INNER JOIN DPUNDMED ON PRE_UNDMED=UND_CODIGO "+;
                      " WHERE "+;
                      " PRE_CODIGO"+GetWhere("=",oPos:cCodInv)+;
                      " AND PRE_LISTA"+GetWhere("=",cTipoPrec)+" AND PRE_UNDMED"+GetWhere("=",cTipoUnid)+;
                      " ORDER BY PRE_PRECIO")

        IF Empty(oPos:aPrecios)
           SetMsgErr("Producto no Tiene Precio")
           RETURN .F.
        ENDIF
*/
    ENDIF

    oPos:nPrecio:=oPos:aPrecios[1,1] // Precio Escogido
    oPos:cUndMed:=oPos:aPrecios[1,2] // Unidad de Medida
    oPos:ncXUnd :=oPos:aPrecios[1,3] // Cantidad por Grupo

  //ELSE
  //SetMsgErr("No estß Autorizado...")
  //RETURN .F.
  //ENDIF
RETURN .T.

FUNCTION FUNF3()
   oPos:lCantid:=!oPos:lCantid
   oPos:oCantid:Refresh()
   DPFOCUS(oPos:oCantid)
   oPos:oCantid:Refresh()
RETURN .T.

FUNCTION FUNF4()
   IIF(oPos:EFECTIVOYCESTA(),oPos:SAVETICKET(.t.),NIL)
RETURN .T.

FUNCTION FUNF6()
   IIF(oPos:Cheque(),oPos:SAVETICKET(.t.),NIL)
RETURN .T.

FUNCTION GETPRECIOTAB()
   LOCAL nPrecio:=0

   nPrecio:=SQLGET("DPPRECIOS","PRE_PRECIO","PRE_CODIGO"+GetWhere("=", oPos:cCodInv)+" AND "+;
                                            "PRE_REQUIE"+GetWhere(">=",oPos:nCantid)+" AND "+;
                                            "PRE_REQUIE"+GetWhere(">",0)+;
                                            " ORDER BY PRE_REQUIE "+;
                                            " LIMIT 1 ")

   IF nPrecio=0

      nPrecio:=SQLGET("DPPRECIOS","PRE_PRECIO","PRE_CODIGO"+GetWhere("=", oPos:cCodInv)+" AND "+;
                                               "PRE_REQUIE"+GetWhere(">",0)+;
                                               " ORDER BY PRE_REQUIE DESC "+;
                                               " LIMIT 1 ")

   ENDIF

RETURN nPrecio

FUNCTION SETBONTON(cCual)
? cCual
RETURN NIL

/*
// PAGELE_LIMITE()
*/
FUNCTION PAGELE_LIMITE()

  IF oPos:lPagEle .AND. oPos:nBruto>oPos:nLimite
    oPos:SetMsgErr("Venta Supera Límite "+LSTR(oPos:nLimite))
    RETURN .F.
  ENDIF

RETURN .T.

/*
// Asignar IVA 10% Beneficio Tributario
*/
FUNCTION SETIVA10()

   IF oPos:nBruto>0
      MensajeErr("Factura ya fué Iniciada, no puede Cambiar la Condición Fiscal")
      RETURN .F.
   ENDIF

   EJECUTAR("DPPOS_10IVA",oPos,!oPos:lLimite)
/*
   // Revisa la Validación
   IF !Empty(oPos:DOC_CODIGO) .AND. !EVAL(oPos:oDOC_CODIGO:bValid)
      // Revierte la Condición
      EJECUTAR("DPPOS_10IVA",oPos,!oPos:lLimite)
   ENDIF
*/

RETURN .T.
/*
// Aqui van los Controles
*/
FUNCTION POSSETGET()
   LOCAL oFontB,oFontT,oSay,aControls:={}

   DEFINE FONT oFontB NAME "Tahoma"   SIZE 0, -11 BOLD
   DEFINE FONT oFontT NAME "Tahoma"   SIZE 0, -18 BOLD

   @ 1.4+1.6,2  SAY "Tipo/Doc. "  RIGHT OF oBar BORDER SIZE 80,22 COLOR 0,oDp:nClrYellow FONT oFontB
   @ 3.0+1.55,2 SAY "RIF/CI "     RIGHT OF oBar BORDER SIZE 80,20 COLOR 0,oDp:nClrYellow FONT oFontB
   @ 4.4+1.55,2 SAY "Vendedor "   RIGHT OF oBar BORDER SIZE 80,20 COLOR 0,oDp:nClrYellow FONT oFontB

   @ 1.4+1.6,15.5 SAY oPos:oTipDoc PROMPT " "+SQLGET("DPTIPDOCCLI","TDC_DESCRI","TDC_TIPO"+GetWhere("=",oPos:cTipDoc)) ;
               SIZE 280+50,22 OF oPos:oBar BORDER COLOR CLR_WHITE,16022016 FONT oFontT

// FONT oFontB BORDER

   @ 2.1,79.5 GET oPos:nDocDesc PICTURE "99.99" OF oBar;
              VALID oPos:CALCULAR();
              SIZE 40,24 RIGHT FONT oFontB

   @ 3.7+1.7,11.7 BMPGET oPos:oCodCli VAR oPos:cCodCli;
              VALID oPos:ValCodCli();
              NAME "BITMAPS\FIND.BMP";
              ACTION (oDpLbx:=DpLbx("DPCLIENTES") , oDpLbx:GetValue("CLI_CODIGO",oPos:oCodCli)); 
              SIZE 100,20 OF oPos:oBar FONT oFontB

   @ oPos:oCodCli:nTop(),oPos:oCodCli:nRight()+20 GET oPos:oNomCli VAR oPos:cNomCli OF oBar;
                                                  SIZE 150+150,20 PIXEL FONT oFontB;
                                                  WHEN !("0000000000"$oPos:cCodCli)

   oPos:oCodCli:bkeyDown:={|nkey| IIF(nKey=13, oPos:ValCodCli(),NIL) }


   @ 5.3+1.7,11.7 BMPGET oPos:oCodVen VAR oPos:cCodVen;
                  VALID oPos:ValCodVen();
                  NAME "BITMAPS\FIND.BMP";
                  ACTION (oDpLbx:=DpLbx("DPVENDEDOR.LBX",NIL,NIL) , oDpLbx:GetValue("VEN_CODIGO",oPos:oCodVen)); 
                  SIZE 80,20 OF oPos:oBar FONT oFontB

   @ oPos:oCodVen:nTop(),oPos:oCodVen:nRight()+20 SAY oPos:oNomVen PROMPT SQLGET("DPVENDEDOR","VEN_NOMBRE","VEN_CODIGO"+GetWhere("=",oPos:cCodVen)) OF oBar;
                                                                  SIZE 150+150,20 PIXEL FONT oFontB COLOR 0,oDp:nGris2 BORDER

   @ 8.6+1.8,1.5  BMPGET oPos:oCodInv  VAR oPos:cCodInv ;
              VALID oPos:ValCodigo();
              NAME "BITMAPS\FIND.BMP"; 
              ACTION oPos:INVLBX();
              WHEN 1=1;
              SIZE 150,21 OF oPos:oBar FONT oFontB

  oPos:oCodInv:bKeyDown:={|nKey|oPos:PosKeyDown(nKey)}

  @ oPos:oCodInv:nTop(),oPos:oCodInv:nRight()+20-1 COMBOBOX oPos:oUndMed; 
             VAR oPos:cUndMed ITEMS oPos:aUndMed;
             WHEN oPos:lUndMed .AND. LEN(oPos:oUndMed:aItems)>1 OF oBar PIXEL SIZE 90,21 FONT oFontB;
             ON CHANGE oPos:VALUNDMED() 

  COMBOINI(oPos:oUndMed)

  @ oPos:oUndMed:nTop(),oPos:oUndMed:nRight()+2 GET oPos:oCantid;
             VAR oPos:nCantid PICTURE oDp:cPictCanUnd RIGHT;
             VALID  oPos:ValCantid();
             WHEN oPos:lCantid OF oBar PIXEL SIZE 90,21 FONT oFontB

  @ oPos:oCantid:nTop(),oPos:oCantid:nRight()+2 GET oPos:oPeso;
             VAR oPos:nPeso PICTURE oDp:cPictPeso RIGHT;
             VALID  oPos:ValPeso();
             WHEN oPos:lPeso OF oBar PIXEL SIZE 90,21 FONT oFontB

  @ oPos:oPeso:nTop(),oPos:oPeso:nRight()+2 GET oPos:oPrecio;
             VAR oPos:nPrecio PICTURE oDp:cPictPrecio RIGHT;
             VALID  oPos:ValPrecio();
             WHEN oPos:lPrecio .AND. oPos:lValCodInv;
             OF oBar PIXEL SIZE 110,21 FONT oFontB

   oPos:aControls:={}
   AADD(oPos:aControls,oPos:oCodInv)
   AADD(oPos:aControls,oPos:oUndMed)
   AADD(oPos:aControls,oPos:oCantid)
   AADD(oPos:aControls,oPos:oPrecio)

//   @ 1.5,1 GET nMonto SIZE 50,10 RIGHT PICTURE "999,999,999.99"
//   @ 2.5,12 BUTTON "Aplicar" SIZE 22,12 ACTION (oPos:PrecioItem(oPos:oBrwItem:nArrayAt,nMonto),oDlg:End())

   @ 5.9+1.6,2 SAY oSay                    PROMPT " Producto " OF oBar BORDER SIZE oPos:oCodInv:nWidth()+17,20 COLOR 0,oDp:nGrid_ClrPaneH  FONT oFontB
   @ oSay:nTop(),oSay:nRight()+2 SAY oSay  PROMPT " Unidad "   OF oBar BORDER SIZE oPos:oUndMed:nWidth(),20 COLOR 0,oDp:nGrid_ClrPaneH PIXEL FONT oFontB
   @ oSay:nTop(),oSay:nRight()+2 SAY oSay  PROMPT " Cantidad " OF oBar BORDER SIZE oPos:oCantid:nWidth(),20 COLOR 0,oDp:nGrid_ClrPaneH RIGHT PIXEL FONT oFontB
   @ oSay:nTop(),oSay:nRight()+2 SAY oSay  PROMPT " Peso "     OF oBar BORDER SIZE oPos:oPeso:nWidth()  ,20 COLOR 0,oDp:nGrid_ClrPaneH RIGHT PIXEL FONT oFontB
   @ oSay:nTop(),oSay:nRight()+2 SAY oSay  PROMPT " Precio "+oDp:cMoneda   OF oBar BORDER SIZE oPos:oPrecio:nWidth(),20 COLOR 0,oDp:nGrid_ClrPaneH RIGHT PIXEL FONT oFontB

   BMPGETBTN(oPos:oCodInv)
   BMPGETBTN(oPos:oCodVen)
   BMPGETBTN(oPos:oCodCli)

   @ 5.9-5.9,100-35 SAY oSay                     PROMPT  " "+oDp:cMonedaExt+" "+DTOC(oDp:dKpiFecha) OF oBar BORDER SIZE 105,20 COLOR 0,oDp:nClrYellow FONT oFontB 
   @ oSay:nTop(),oSay:nRight()+2 SAY oSay PROMPT " "+TRAN(oDp:nMonedaExt,"9,999,999.99")+" "        OF oBar BORDER SIZE 121,20 COLOR 0,oDp:nGris2     RIGHT PIXEL FONT oFontB

   @ 7.3-5.9,100-35 SAY oSay PROMPT " Lista "                           OF oBar BORDER SIZE 40,20 COLOR 0,oDp:nClrYellow FONT oFontB
   @ oSay:nTop(),oSay:nRight()+2 SAY oSay PROMPT " "+oDp:cPrecioPos+" "+SQLGET("DPPRECIOTIP","TPP_DESCRI","TPP_CODIGO"+GetWhere("=",oDp:cPrecioPos))  OF oBar BORDER SIZE 186,20 COLOR 0,oDp:nGris2 PIXEL FONT oFontB

   oPos:aControls:={}
   AADD(oPos:aControls,oPos:oCodInv)
   AADD(oPos:aControls,oPos:oUndMed)
   AADD(oPos:aControls,oPos:oCantid)
   AADD(oPos:aControls,oPos:oPeso  )
   AADD(oPos:aControls,oPos:oPrecio)

   AEVAL(oPos:aControls,{|o,n| o:ForWhen(.T.),o:nId:=n,AADD(aControls,o:nId)})

//   ViewArray(aControls)

   oPos:NEWITEM()

RETURN .T.

FUNCTION VALCODCLI()
  LOCAL lOk
  LOCAL cRif:=oPos:cCodCli,cNombre:=""

//  IF ISDIGIT(LEFT(cRif,1))
//? "NUMERICO"
//  ENDIF
// ? cRif

  cNombre:=SQLGET("DPCLIENTES","CLI_NOMBRE","CLI_CODIGO"+GetWhere("=",cRif)+" OR CLI_RIF"+GetWhere("=",cRif))

  IF !Empty(cNombre)
     oPos:oNomCli:VarPut(cNombre,.T.)
     RETURN .T.
  ENDIF

  cNombre:=SQLGET("DPCLIENTESCERO","CCG_NOMBRE","CCG_RIF"+GetWhere("=",cRif)+" LIMIT 1")

  IF !Empty(cNombre)
     oPos:oNomCli:VarPut(cNombre,.T.)
     RETURN .T.
  ENDIF

  IF Empty(cNombre)
    EJECUTAR("FINDCODENAME","DPCLIENTESCERO","CCG_RIF","CCG_NOMBRE",oPos:oCodCli)
  ENDIF


  IF !oPos:lValRif
     RETURN .T.
  ENDIF

  MsgRun("Verificando RIF "+cRif,"Por Favor, Espere",;
         {|| lOk:=EJECUTAR("VALRIFSENIAT",cRif,!ISDIGIT(cRif),!ISDIGIT(cRif),NIL,.T.) })

  IF !Empty(oDp:aRif)
     oPos:oNomCli:VarPut(oDp:aRif[1],.T.)
     oPos:oNomCli:Refresh(.T.)
  ENDIF


RETURN .T.

FUNCTION INVLBX()
  LOCAL cWhere:="LEFT(INV_UTILIZ,1)"+GetWhere("=","V")

  cWhere:=cWhere+" AND PRE_CODMON"+GetWhere("=",oDp:cMonedaExt)
  cWhere:=cWhere+" AND PRE_LISTA" +GetWhere("=",oDp:cPrecioPos)

  IF !Empty(oPos:cInvLbxWhere)
     cWhere:=cWhere+" AND "+oPos:cInvLbxWhere
  ENDIF
  
  oDpLbx:=DpLbx("DPINVDIVISA",NIL,cWhere,NIL,NIL,NIL,NIL,NIL,NIL,oPos:oCodInv,NIL)
  oDpLbx:GetValue("INV_CODIGO",oPos:oCodInv)

//  DPFOCUS(oDpLbx:oBrw)

RETURN .T.

FUNCTION VALPESO()
RETURN .T.

FUNCTION VALPRECIO()

  oPos:ISFINITEM(oPos:oPrecio)

RETURN .T.

FUNCTION POSSETPRECIO()

 oPos:lPrecio:=!oPos:lPrecio
 oPos:oPrecio:ForWhen(.T.)

 IF !Empty(oPos:cCodInv)
   DPFOCUS(oPos:oPrecio)
 ENDIF

RETURN .T.

FUNCTION VALUNDMED()
  ? "VALUNDMED()"
RETURN .T.
/*
// Pago con Dolar
*/
FUNCTION PagoDolar()

  IF oPos:nNeto=0
     oPos:oCodInv:MsgErr("Documento sin Monto","Ingresar Productos")
     RETURN .F.
  ENDIF

  IF oDp:nMonedaExt<=1 
     oPos:oCodInv:MsgErr("Requiere Valor de la Divisa","Ejecutar Actualizar Divisa ["+oDp:nMonedaExt+"]")
     EJECUTAR("DPHISMON",1,oDp:cMonedaExt,oDp:dFecha)
     RETURN .F.
  ENDIF

  EJECUTAR("DPPOSEFECTIVODOLAR",oPos)

RETURN .T.

FUNCTION SetTipDoc(cTipDoc,lCalcular)
   LOCAL nColor:=SQLGET("DPTIPDOCCLI","TDC_CLRGRA,TDC_LIBVTA,TDC_IVA,TDC_PAGOS,TDC_CXC","TDC_TIPO"+GetWhere("=",cTipDoc))


   DEFAULT lCalcular:=.T.

   oPos:lLibVta:=DPSQLROW(2,.T.)
   oPos:lCalIva:=DPSQLROW(3,.T.)
   oPos:lPagos :=DPSQLROW(4,.T.)
   oPos:cCxC   :=SQLGET("DPTIPDOCCLI","TDC_CXC","TDC_TIPO"+GetWhere("=",cTipDoc))

   //
   // Devoluciones no acepta pagos
   // 09/08/2022
   // 
   IF oPos:lPagos .AND. "C"$oPos:cCxC
      oPos:lPagos:=.F.
   ENDIF

   oPos:cTipDoc:=cTipDoc
   oPos:oTipDoc:Refresh(.T.)

   IF lCalcular
     oPos:CALCULAR()
   ENDIF

RETURN .T.

FUNCTION SELLIBROS()

  LOCAL cWhere:="INV_GRUPO"+GetWhere("=",oDp:cGruLibros)

  cWhere:=cWhere+" AND PRE_CODMON"+GetWhere("=",oDp:cMonedaExt)
  cWhere:=cWhere+" AND PRE_LISTA" +GetWhere("=",oDp:cPrecioPos)


  IF !Empty(oPos:cInvLbxWhere)
     cWhere:=cWhere+" AND "+oPos:cInvLbxWhere
  ENDIF
  
  oDpLbx:=DpLbx("DPINVLIBROS",NIL,cWhere,NIL,NIL,NIL,NIL,NIL,NIL,oPos:oCodInv,NIL)
  oDpLbx:GetValue("INV_CODIGO",oPos:oCodInv)

   
RETURN .T.

FUNCTION SELPLANTILLA()
  LOCAL cWhere,cCodSuc,nPeriodo,dDesde,dHasta,cTitle,cTipDes
  EJECUTAR("BRPLATODOC",cWhere,cCodSuc,nPeriodo,dDesde,dHasta,cTitle,cTipDes,oPos)
RETURN .T.

FUNCTION VALRIFSENIAT()

   IF oPos:lValRif .AND. !Empty(oPos:cCodCli)
      oPos:VALRIFSENIAT()  
   ENDIF

RETURN .T.

FUNCTION POSGRABAR()
 LOCAL cText:=ALLTRIM(EVAL(oPos:oTipDoc:bSetGet))
 LOCAL oDb  :=OpenOdbc(oDp:cDsnData)

 IF !oPos:lLibVta .AND. Empty(oPos:CCG_RIF)
    oPos:CCG_RIF   :=oPos:cCodCli
    oPos:CCG_NOMBRE:=oPos:cNomCli
    oPos:CCG_DIR1  :=""
    oPos:CCG_DIR2  :=""
    oPos:CCG_DIR3  :=""

   IF oPos:cCodCli=REPLI("0",10) .AND. Empty(oPos:cNomCli)
      oPos:SetMsgErr("Introduzca Nombre del Cliente")
      DPFOCUS(oPos:oCodCli)
      RETURN .F.
   ENDIF  

   IF Empty(oPos:cNomCli) 
      oPos:SetMsgErr("Introduzca Nombre del Cliente")
      DPFOCUS(oPos:oNomCli)
      RETURN .F.
   ENDIF

  ENDIF

  // 18/11/2022, Devolución absoluta
  IF oPos:nNeto<0
    cText:=ALLTRIM(SQLGET("DPTIPDOCCLI","TDC_DESCRI","TDC_TIPO"+GetWhere("=",oDp:cTipDocDev)))
    oPos:nMtoDev:=oPos:nNeto*-1
  ENDIF

  oPos:cCodMon:=oDp:cMonedaExt

  IF !MsgYesNo("Desea Generar ["+cText+"] Monto "+ALLTRIM(FDP(oPos:nNeto,"999,999,999.99")),"Generar Documento")
     RETURN .F.
  ENDIF

  // 20/11/2022 Desactiva la Integridad referencial
  oDb:EXECUTE("SET FOREIGN_KEY_CHECKS = 0")

  IF oPos:SAVETICKET(.t.)
    oPos:POSREINI(.T.)
  ENDIF

  oDb:EXECUTE("SET FOREIGN_KEY_CHECKS = 1")

RETURN .T.

/*
// obtener datos desde el SENIAT
*/
FUNCTION VALRIFSENIAT()
   LOCAL lOk,uValue:=ALLTRIM(oPos:cCodCli),nLen:=LEN(oPos:cNomCli)

   lOk:=EJECUTAR("VALRIFSENIAT",uValue,!ISDIGIT(uValue),ISDIGIT(uValue)) 

   IF lOk .AND. LEN(oDp:aRif)>1 .AND. !("NO ENCON"$oDp:aRif[1])
      oPos:oNomCli:VARPUT(PADR(oDp:aRif[1],nLen),.T.)
   ENDIF

RETURN .F.

// EOF

