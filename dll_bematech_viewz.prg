// Programa   : DLL_BEMATECH_VIEWZ
// Fecha/Hora : 13/06/2017 15:04:37
// Prop�sito  : Visualizar Registros de Lectura del Reporte Z
// Creado Por : Autom�ticamente por BRWMAKER
// Llamado por: <DPXBASE>
// Aplicaci�n : Gerencia 
// Tabla      : <TABLA>

#INCLUDE "DPXBASE.CH"

PROCE MAIN(cCodigo,cWhere,cCodSuc,nPeriodo,dDesde,dHasta,cTitle,cTableA)
   LOCAL aData,aFechas,cFileMem:="USER\BRPLANTILLADOC.MEM",V_nPeriodo:=4,cCodPar
   LOCAL V_dDesde:=CTOD(""),V_dHasta:=CTOD("")
   LOCAL cServer:=oDp:cRunServer,aVars:={}
   LOCAL lConectar:=.F.,cSql

   oDp:cRunServer:=NIL

   IF !Empty(cServer)

     MsgRun("Conectando con Servidor "+cServer+" ["+ALLTRIM(SQLGET("DPSERVERBD","SBD_DOMINI","SBD_CODIGO"+GetWhere("=",cServer)))+"]",;
            "Por Favor Espere",{||lConectar:=EJECUTAR("DPSERVERDBOPEN",cServer)})

     IF !lConectar
        RETURN .F.
     ENDIF

   ENDIF 


   IF Type("oBemaViewZ")="O" .AND. oBemaViewZ:oWnd:hWnd>0
      EJECUTAR("BRRUNNEW",oBemaViewZ,GetScript())
      RETURN oBemaViewZ
   ENDIF

   IF Empty(oDp:hDllRtf) // Carga RTF
      oDp:hDLLRtf := LoadLibrary( "Riched20.dll" )
   ENDIF

   cTitle:="Reporte Z en formato Digital para Impresora Bematech " +IF(Empty(cTitle),"",cTitle)

   oDp:oFrm:=NIL

   DEFAULT cCodSuc :=oDp:cSucursal,;
           nPeriodo:=4,;
           dDesde  :=CTOD(""),;
           dHasta  :=CTOD(""),;
           cWhere  :="",;
           cCodigo :="B",;
           cTableA :="DPAUDELIMODCNF"	

   cWhere:="DOC_SERFIS"+GetWhere("=",cCodigo)

   IF .T. .AND. (!nPeriodo=10 .AND. (Empty(dDesde) .OR. Empty(dhasta)))

       aFechas:=EJECUTAR("DPDIARIOGET",nPeriodo)
       dDesde :=aFechas[1]
       dHasta :=aFechas[2]

   ENDIF

   aData:=LEERDATA(HACERWHERE(dDesde,dHasta,cWhere),NIL,cServer,cTableA)

   cSql :=oDp:cWhere

   IF Empty(aData)
      MensajeErr("no hay "+cTitle,"Informaci�n no Encontrada")
      RETURN .F.
   ENDIF

   ViewData(aData,cTitle,oDp:cWhere)

   oDp:oFrm:=oBemaViewZ
            
RETURN .T. 

FUNCTION ViewData(aData,cTitle,cWhere_)
   LOCAL oBrw,oCol,aTotal:=ATOTALES(aData)
   LOCAL oFont,oFontB,oFontC
   LOCAL aPeriodos:=ACLONE(oDp:aPeriodos)
   LOCAL aCoors:=GetCoors( GetDesktopWindow() )

   DEFINE FONT oFont  NAME "Tahoma"      SIZE 0, -12 
   DEFINE FONT oFontB NAME "Tahoma"      SIZE 0, -12 
   DEFINE FONT oFontC NAME "Courier New" SIZE 0, -12 BOLD

   DpMdi(cTitle,"oBemaViewZ","") // BRPLANTILLADOC.EDT")

   // oBemaViewZ:Windows(0,0,600,1010,.T.) // Maximizado

   oBemaViewZ:Windows(0,0,aCoors[3]-160,aCoors[4]-10,.T.) // Maximizado

   oBemaViewZ:lMsgBar  :=.F.
   oBemaViewZ:cPeriodo :=aPeriodos[nPeriodo]
   oBemaViewZ:cCodSuc  :=cCodSuc
   oBemaViewZ:nPeriodo :=nPeriodo
   oBemaViewZ:cNombre  :=""
   oBemaViewZ:dDesde   :=dDesde
   oBemaViewZ:cServer  :=cServer
   oBemaViewZ:dHasta   :=dHasta
   oBemaViewZ:cWhere   :=cWhere
   oBemaViewZ:cWhere_  :=cWhere_
   oBemaViewZ:cWhereQry:=""
   oBemaViewZ:cSql     :=oDp:cSql
   oBemaViewZ:oWhere   :=TWHERE():New(oBemaViewZ)
   oBemaViewZ:cCodPar  :=cCodPar // C�digo del Par�metro
   oBemaViewZ:lWhen    :=.T.
   oBemaViewZ:cTextTit :="" // Texto del Titulo Heredado
   oBemaViewZ:oDb      :=oDp:oDb
   oBemaViewZ:cBrwCod  :=""
   oBemaViewZ:lTmdi    :=.T.
   oBemaViewZ:cWhereCli:=""
   oBemaViewZ:cTitleCli:=NIL
   oBemaViewZ:cCodigo  :=cCodigo
   oBemaViewZ:oMemo    :=NIL
   oBemaViewZ:cMemo    :=""
   oBemaViewZ:cTableA  :=cTableA

   oBemaViewZ:oBrw:=TXBrowse():New( IF(oBemaViewZ:lTmdi,oBemaViewZ:oWnd,oBemaViewZ:oDlg ))
   oBemaViewZ:oBrw:SetArray( aData, .F. )
   oBemaViewZ:oBrw:SetFont(oFont)

   oBemaViewZ:oBrw:lFooter     := .F.
   oBemaViewZ:oBrw:lHScroll    := .T.
   oBemaViewZ:oBrw:nHeaderLines:= 2
   oBemaViewZ:oBrw:nDataLines  := 1
   oBemaViewZ:oBrw:nFooterLines:= 1

   oBemaViewZ:aData            :=ACLONE(aData)
   oBemaViewZ:nClrText :=0
   oBemaViewZ:nClrPane1:=16774120
   oBemaViewZ:nClrPane2:=16771538

   AEVAL(oBemaViewZ:oBrw:aCols,{|oCol|oCol:oHeaderFont:=oFont})

   oCol:=oBemaViewZ:oBrw:aCols[1]
   oCol:cHeader      :='#Reg'
   oCol:bLClickHeader:= {|r,c,f,o| SortArray( o, oBemaViewZ:oBrw:aArrayData ) } 
   oCol:nWidth       := 70

   oCol:=oBemaViewZ:oBrw:aCols[2]
   oCol:cHeader      :='#Zeta'
   oCol:bLClickHeader:= {|r,c,f,o| SortArray( o, oBemaViewZ:oBrw:aArrayData ) } 
   oCol:nWidth       := 60

   oCol:=oBemaViewZ:oBrw:aCols[3]
   oCol:cHeader      :='#Serie'
   oCol:bLClickHeader:= {|r,c,f,o| SortArray( o, oBemaViewZ:oBrw:aArrayData ) } 
   oCol:nWidth       := 60

   oCol:=oBemaViewZ:oBrw:aCols[4]
   oCol:cHeader      :='Ultima'+CRLF+"Factura"
   oCol:bLClickHeader:= {|r,c,f,o| SortArray( o, oBemaViewZ:oBrw:aArrayData ) } 
   oCol:nWidth       := 60


   oCol:=oBemaViewZ:oBrw:aCols[5]
   oCol:cHeader      :="Base"+CRLF+'Imponible'
   oCol:bLClickHeader := {|r,c,f,o| SortArray( o, oBemaViewZ:oBrw:aArrayData ) } 
   oCol:nWidth       := 120
   oCol:nDataStrAlign:= AL_RIGHT 
   oCol:nHeadStrAlign:= AL_RIGHT 
   oCol:nFootStrAlign:= AL_RIGHT 
   oCol:cEditPicture :='9,999,999,999,999,999.99'
   oCol:bStrData:={|nMonto,oCol|nMonto:= oBemaViewZ:oBrw:aArrayData[oBemaViewZ:oBrw:nArrayAt,5],; 
                                oCol   := oBemaViewZ:oBrw:aCols[5],;
                                FDP(nMonto,oCol:cEditPicture)}
   oCol:cFooter      :=FDP(aTotal[5],oCol:cEditPicture)


   oCol:=oBemaViewZ:oBrw:aCols[6]
   oCol:cHeader      :="Monto"+CRLF+'Exento'
   oCol:bLClickHeader := {|r,c,f,o| SortArray( o, oBemaViewZ:oBrw:aArrayData ) } 
   oCol:nWidth       := 120
   oCol:nDataStrAlign:= AL_RIGHT 
   oCol:nHeadStrAlign:= AL_RIGHT 
   oCol:nFootStrAlign:= AL_RIGHT 
   oCol:cEditPicture :='9,999,999,999,999,999.99'
   oCol:bStrData:={|nMonto,oCol|nMonto:= oBemaViewZ:oBrw:aArrayData[oBemaViewZ:oBrw:nArrayAt,6],; 
                                oCol   := oBemaViewZ:oBrw:aCols[6],;
                                FDP(nMonto,oCol:cEditPicture)}
   oCol:cFooter      :=FDP(aTotal[6],oCol:cEditPicture)

   oCol:=oBemaViewZ:oBrw:aCols[7]
   oCol:cHeader      :="Monto"+CRLF+'IVA'
   oCol:bLClickHeader := {|r,c,f,o| SortArray( o, oBemaViewZ:oBrw:aArrayData ) } 
   oCol:nWidth       := 120
   oCol:nDataStrAlign:= AL_RIGHT 
   oCol:nHeadStrAlign:= AL_RIGHT 
   oCol:nFootStrAlign:= AL_RIGHT 
   oCol:cEditPicture :='9,999,999,999,999,999.99'
   oCol:bStrData:={|nMonto,oCol|nMonto:= oBemaViewZ:oBrw:aArrayData[oBemaViewZ:oBrw:nArrayAt,7],; 
                                oCol   := oBemaViewZ:oBrw:aCols[7],;
                                FDP(nMonto,oCol:cEditPicture)}
   oCol:cFooter      :=FDP(aTotal[7],oCol:cEditPicture)


   oCol:=oBemaViewZ:oBrw:aCols[8]
   oCol:cHeader      :="Monto"+CRLF+'Neto'
   oCol:bLClickHeader := {|r,c,f,o| SortArray( o, oBemaViewZ:oBrw:aArrayData ) } 
   oCol:nWidth       := 120
   oCol:nDataStrAlign:= AL_RIGHT 
   oCol:nHeadStrAlign:= AL_RIGHT 
   oCol:nFootStrAlign:= AL_RIGHT 
   oCol:cEditPicture :='9,999,999,999,999,999.99'
   oCol:bStrData:={|nMonto,oCol|nMonto:= oBemaViewZ:oBrw:aArrayData[oBemaViewZ:oBrw:nArrayAt,8],; 
                                oCol   := oBemaViewZ:oBrw:aCols[8],;
                                FDP(nMonto,oCol:cEditPicture)}
   oCol:cFooter      :=FDP(aTotal[8],oCol:cEditPicture)


   oCol:=oBemaViewZ:oBrw:aCols[9]
   oCol:cHeader      :="Monto"+CRLF+'IGTF'
   oCol:bLClickHeader := {|r,c,f,o| SortArray( o, oBemaViewZ:oBrw:aArrayData ) } 
   oCol:nWidth       := 120
   oCol:nDataStrAlign:= AL_RIGHT 
   oCol:nHeadStrAlign:= AL_RIGHT 
   oCol:nFootStrAlign:= AL_RIGHT 
   oCol:cEditPicture :='9,999,999,999,999,999.99'
   oCol:bStrData:={|nMonto,oCol|nMonto:= oBemaViewZ:oBrw:aArrayData[oBemaViewZ:oBrw:nArrayAt,9],; 
                                oCol  := oBemaViewZ:oBrw:aCols[9],;
                                FDP(nMonto,oCol:cEditPicture)}
   oCol:cFooter      :=FDP(aTotal[9],oCol:cEditPicture)


   oCol:=oBemaViewZ:oBrw:aCols[10]
   oCol:cHeader      :='Fecha'
   oCol:bLClickHeader:= {|r,c,f,o| SortArray( o, oBemaViewZ:oBrw:aArrayData ) } 
   oCol:nWidth       := 70

   oCol:=oBemaViewZ:oBrw:aCols[11]
   oCol:cHeader      :='Hora'
   oCol:bLClickHeader:= {|r,c,f,o| SortArray( o, oBemaViewZ:oBrw:aArrayData ) } 
   oCol:nWidth       := 70

   oCol:=oBemaViewZ:oBrw:aCols[11]
   oCol:cHeader      :='#Reg'+CRLF+"Ticket"
   oCol:bLClickHeader:= {|r,c,f,o| SortArray( o, oBemaViewZ:oBrw:aArrayData ) } 
   oCol:nWidth       := 70





   oBemaViewZ:oBrw:bClrStd               := {|oBrw,nClrText,aData|oBrw:=oBemaViewZ:oBrw,aData:=oBrw:aArrayData[oBrw:nArrayAt],;
                                           oBemaViewZ:nClrText,;
                                          {nClrText,iif( oBrw:nArrayAt%2=0, oBemaViewZ:nClrPane1, oBemaViewZ:nClrPane2 ) } }

   oBemaViewZ:oBrw:bClrHeader            := {|| { oDp:nLbxClrHeaderText, oDp:nLbxClrHeaderPane}}
   oBemaViewZ:oBrw:bClrFooter            := {|| { oDp:nLbxClrHeaderText, oDp:nLbxClrHeaderPane}}


   oBemaViewZ:oBrw:bLDblClick:={|oBrw|oBemaViewZ:RUNCLICK() }

   oBemaViewZ:oBrw:bChange:={||oBemaViewZ:BRWCHANGE()}
   oBemaViewZ:oBrw:CreateFromCode()

   oBemaViewZ:bValid   :={|| EJECUTAR("BRWSAVEPAR",oBemaViewZ)}
   oBemaViewZ:BRWRESTOREPAR()

//   @ 10,0 GET oBemaViewZ:oMemo VAR oBemaViewZ:cMemo  MULTI HSCROLL FONT oFontB

   @ 10,0 RICHEDIT oBemaViewZ:oMemo VAR oBemaViewZ:cMemo OF oBemaViewZ:oWnd HSCROLL  FONT oFontC


   @ 0,0 SPLITTER oBemaViewZ:oHSplit ;
         HORIZONTAL;
         PREVIOUS CONTROLS oBemaViewZ:oBrw ;
         HINDS CONTROLS oBemaViewZ:oMemo;
         TOP MARGIN 40 ;
         BOTTOM MARGIN 40 ;
         SIZE 300, 4  PIXEL ;
         OF oBemaViewZ:oWnd ;
         _3DLOOK

  oBemaViewZ:oWnd:oClient := oBemaViewZ:oHSplit

  oBemaViewZ:Activate({||oBemaViewZ:ViewDatBar()})

RETURN .T.

/*
// Barra de Botones
*/
FUNCTION ViewDatBar()
   LOCAL oCursor,oBar,oBtn,oFont,oCol,nCol:=30-4
   LOCAL oDlg:=IF(oBemaViewZ:lTmdi,oBemaViewZ:oWnd,oBemaViewZ:oDlg)
   LOCAL nLin:=0
   LOCAL nWidth:=oBemaViewZ:oBrw:nWidth()
   LOCAL nAltoBrw:=150

   /*   
   //  Ubicamos el Area del Primer Objeto o Browse.
   */

   oBemaViewZ:oBrw:Move(032,0,800,nAltoBrw,.T.)

   oBemaViewZ:oHSplit:Move(oBemaViewZ:oBrw:nHeight()+oBemaViewZ:oBrw:nTop(),0)
   oBemaViewZ:oMemo:Move(oBemaViewZ:oBrw:nHeight()+oBemaViewZ:oBrw:nTop()+5,0,800,400,.T.)

   oBemaViewZ:oHSplit:AdjLeft()
   oBemaViewZ:oHSplit:AdjRight()

   oBemaViewZ:oBrw:GoBottom(.T.)
   oBemaViewZ:oBrw:Refresh(.T.)

   DEFINE CURSOR oCursor HAND
   IF !oDp:lBtnText 
     DEFINE BUTTONBAR oBar SIZE 52-15,60-15 OF oDlg 3D CURSOR oCursor
   ELSE 
     DEFINE BUTTONBAR oBar SIZE oDp:nBtnWidth,oDp:nBarnHeight+6 OF oDlg 3D CURSOR oCursor 
   ENDIF 


   DEFINE FONT oFont  NAME "Tahoma"   SIZE 0, -12 BOLD

 // Emanager no Incluye consulta de Vinculos

   oBemaViewZ:oFontBtn   :=oFont    
   oBemaViewZ:nClrPaneBar:=oDp:nGris
   oBemaViewZ:oBrw:oLbx  :=oBemaViewZ
  

   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\XBROWSE.BMP";
          TOP PROMPT "Detalles";
          ACTION oBemaViewZ:VERDETALLES()

   oBtn:cToolTip:="Ver detalles"


   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\ZOOM.BMP";
          TOP PROMPT "Zoom";
          ACTION IF(oBemaViewZ:oWnd:IsZoomed(),oBemaViewZ:oWnd:Restore(),oBemaViewZ:oWnd:Maximize())

   oBtn:cToolTip:="Maximizar"


   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\XFIND.BMP";
            TOP PROMPT "Buscar"; 
              ACTION  EJECUTAR("BRWSETFIND",oBemaViewZ:oBrw)

   oBtn:cToolTip:="Buscar"

   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\FILTRAR.BMP";
          TOP PROMPT "Filtrar"; 
          ACTION  EJECUTAR("BRWSETFILTER",oBemaViewZ:oBrw)

   oBtn:cToolTip:="Filtrar Registros"

/*
   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\OPTIONS.BMP",NIL,"BITMAPS\OPTIONSG.BMP";
          TOP PROMPT "Opciones"; 
          ACTION  EJECUTAR("BRWSETOPTIONS",oBemaViewZ:oBrw);
          WHEN LEN(oBemaViewZ:oBrw:aArrayData)>1

   oBtn:cToolTip:="Filtrar seg�n Valores Comunes"

   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME DPBMP("Search3.bmp");
          ACTION RTFFIND(oBemaViewZ:oWnd,oBemaViewZ:oMemo) 

*/

IF nWidth>400

 
     DEFINE BUTTON oBtn;
            OF oBar;
            NOBORDER;
            FONT oFont;
            FILENAME "BITMAPS\EXCEL.BMP";
            TOP PROMPT "Excel"; 
            ACTION  (EJECUTAR("BRWTOEXCEL",oBemaViewZ:oBrw,oBemaViewZ:cTitle,oBemaViewZ:cNombre))

     oBtn:cToolTip:="Exportar hacia Excel"

     oBemaViewZ:oBtnXls:=oBtn

ENDIF

   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\html.BMP";
          TOP PROMPT "Html"; 
          ACTION  (EJECUTAR("BRWTOHTML",oBemaViewZ:oBrw))

   oBtn:cToolTip:="Generar Archivo html"

   oBemaViewZ:oBtnHtml:=oBtn

  

IF nWidth>300

   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\PREVIEW.BMP";
          TOP PROMPT "Preview"; 
          ACTION  (EJECUTAR("BRWPREVIEW",oBemaViewZ:oBrw))

   oBtn:cToolTip:="Previsualizaci�n"

   oBemaViewZ:oBtnPreview:=oBtn

ENDIF

/*
   IF ISSQLGET("DPREPORTES","REP_CODIGO","BRPLANTILLADOC")

     DEFINE BUTTON oBtn;
            OF oBar;
            NOBORDER;
            FONT oFont;
            FILENAME "BITMAPS\XPRINT.BMP";
            TOP PROMPT "Imprimir"; 
            ACTION  oBemaViewZ:IMPRIMIR()

      oBtn:cToolTip:="Imprimir"

     oBemaViewZ:oBtnPrint:=oBtn

   ENDIF
*/

IF nWidth>700


   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\QUERY.BMP";
          ACTION oBemaViewZ:BRWQUERY()

   oBtn:cToolTip:="Imprimir"

ENDIF


   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\xTOP.BMP";
          TOP PROMPT "Primero"; 
          ACTION  (oBemaViewZ:oBrw:GoTop(),oBemaViewZ:oBrw:Setfocus())

IF nWidth>800 .OR. nWidth=0

   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\xSIG.BMP";
          TOP PROMPT "Avance"; 
          ACTION  (oBemaViewZ:oBrw:PageDown(),oBemaViewZ:oBrw:Setfocus())

  DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\xANT.BMP";
          TOP PROMPT "Anterior"; 
          ACTION  (oBemaViewZ:oBrw:PageUp(),oBemaViewZ:oBrw:Setfocus())

ENDIF


  DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\xFIN.BMP";
          TOP PROMPT "Ultimo"; 
          ACTION  (oBemaViewZ:oBrw:GoBottom(),oBemaViewZ:oBrw:Setfocus())


   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\XSALIR.BMP";
          TOP PROMPT "Cerrar"; 
          ACTION  oBemaViewZ:Close()

  oBemaViewZ:oBrw:SetColor(0,oBemaViewZ:nClrPane1)

  EVAL(oBemaViewZ:oBrw:bChange)
 
  oBar:SetColor(CLR_BLACK,oDp:nGris)

  AEVAL(oBar:aControls,{|o,n|o:SetColor(CLR_BLACK,oDp:nGris)})


  // Controles se Inician luego del Ultimo Boton
  nLin:=32
  AEVAL(oBar:aControls,{|o,n|nLin:=nLin+o:nWidth() })

  DEFINE FONT oFont  NAME "Tahoma"   SIZE 0, -11 BOLD

  
  //
  // Campo : Periodo
  //
  
  @ 10+nCol, nLin COMBOBOX oBemaViewZ:oPeriodo  VAR oBemaViewZ:cPeriodo ITEMS aPeriodos;
                SIZE 100,NIL;
                PIXEL;
                OF oBar;
                FONT oFont;
                ON CHANGE oBemaViewZ:LEEFECHAS();
                WHEN oBemaViewZ:lWhen 


  ComboIni(oBemaViewZ:oPeriodo )

  @ 10+nCol, nLin+103 BUTTON oBemaViewZ:oBtn PROMPT " < " SIZE 27,24;
                 FONT oFont;
                 PIXEL;
                 OF oBar;
                 ACTION (EJECUTAR("PERIODOMAS",oBemaViewZ:oPeriodo:nAt,oBemaViewZ:oDesde,oBemaViewZ:oHasta,-1),;
                         EVAL(oBemaViewZ:oBtn:bAction));
                WHEN oBemaViewZ:lWhen 


  @ 10+nCol, nLin+130 BUTTON oBemaViewZ:oBtn PROMPT " > " SIZE 27,24;
                 FONT oFont;
                 PIXEL;
                 OF oBar;
                 ACTION (EJECUTAR("PERIODOMAS",oBemaViewZ:oPeriodo:nAt,oBemaViewZ:oDesde,oBemaViewZ:oHasta,+1),;
                         EVAL(oBemaViewZ:oBtn:bAction));
                WHEN oBemaViewZ:lWhen 


  @ 10+nCol, nLin+170-10 BMPGET oBemaViewZ:oDesde  VAR oBemaViewZ:dDesde;
                PICTURE "99/99/9999";
                PIXEL;
                NAME "BITMAPS\Calendar.bmp";
                ACTION LbxDate(oBemaViewZ:oDesde ,oBemaViewZ:dDesde);
                SIZE 76,24;
                OF   oBar;
                WHEN oBemaViewZ:oPeriodo:nAt=LEN(oBemaViewZ:oPeriodo:aItems) .AND. oBemaViewZ:lWhen ;
                FONT oFont

   oBemaViewZ:oDesde:cToolTip:="F6: Calendario"

  @ 10+nCol, nLin+252 BMPGET oBemaViewZ:oHasta  VAR oBemaViewZ:dHasta;
                PICTURE "99/99/9999";
                PIXEL;
                NAME "BITMAPS\Calendar.bmp";
                ACTION LbxDate(oBemaViewZ:oHasta,oBemaViewZ:dHasta);
                SIZE 80,23;
                WHEN oBemaViewZ:oPeriodo:nAt=LEN(oBemaViewZ:oPeriodo:aItems) .AND. oBemaViewZ:lWhen ;
                OF oBar;
                FONT oFont

   oBemaViewZ:oHasta:cToolTip:="F6: Calendario"

   @ 10+nCol, nLin+335+10 BUTTON oBemaViewZ:oBtn PROMPT " > " SIZE 27,24;
               FONT oFont;
               OF oBar;
               PIXEL;
               WHEN oBemaViewZ:oPeriodo:nAt=LEN(oBemaViewZ:oPeriodo:aItems);
               ACTION oBemaViewZ:HACERWHERE(oBemaViewZ:dDesde,oBemaViewZ:dHasta,oBemaViewZ:cWhere,.T.);
               WHEN oBemaViewZ:lWhen

  AEVAL(oBar:aControls,{|o|o:ForWhen(.T.)})

  BMPGETBTN(oBar,oFont,13)

  @ 2,400+32+30 SAY " Serie "     RIGHT OF oBar BORDER SIZE 60,20 PIXEL COLOR oDp:nClrLabelText,oDp:nClrLabelPane FONT oFont
//  @21,400+32+62+75 SAY " Impresora"  RIGHT OF oBar BORDER SIZE 68,20 PIXEL COLOR oDp:nClrLabelText,oDp:nClrLabelPane FONT oFont

  @ 02,500+62   SAY oBemaViewZ:oNombre PROMPT " "+SQLGET("DPSERIEFISCAL",[CONCAT(SFI_MODELO," ",SFI_IMPFIS)],"SFI_LETRA"+GetWhere("=",oBemaViewZ:cCodigo));
                    OF oBar PIXEL SIZE 367,20 BORDER BORDER COLOR oDp:nClrYellowText,oDp:nClrYellow FONT oFont

  @ 02,400+32+90 SAY " "+oBemaViewZ:cCodigo+" ";
                 OF oBar PIXEL SIZE 40,20 BORDER BORDER COLOR oDp:nClrYellowText,oDp:nClrYellow FONT oFont

  
  oBemaViewZ:oBar:=oBar
 
RETURN .T.

/*
// Evento para presionar CLICK
*/
FUNCTION RUNCLICK()
RETURN .T.


/*
// Imprimir
*/
FUNCTION IMPRIMIR()
RETURN .T.

FUNCTION LEEFECHAS()
RETURN .T.


FUNCTION HACERWHERE(dDesde,dHasta,cWhere_,lRun)
   LOCAL cWhere:=""

   DEFAULT lRun:=.F.

   // Campo fecha no puede estar en la nueva clausula
   IF "DPDOCCLI.DOC_FECHA"$cWhere
     RETURN ""
   ENDIF

   IF !Empty(dDesde)
       cWhere:=GetWhereAnd('DPDOCCLI.DOC_FECHA',dDesde,dHasta)
   ELSE
     IF !Empty(dHasta)
       cWhere:=GetWhereAnd('DPDOCCLI.DOC_FECHA',dDesde,dHasta)
     ENDIF
   ENDIF


   IF !Empty(cWhere_)
      cWhere:=cWhere + IIF( Empty(cWhere),""," AND ") +cWhere_
   ENDIF

   IF lRun

     IF !Empty(oBemaViewZ:cWhereQry)
       cWhere:=cWhere + oBemaViewZ:cWhereQry
     ENDIF

     oBemaViewZ:LEERDATA(cWhere,oBemaViewZ:oBrw,oBemaViewZ:cServer)

   ENDIF

RETURN cWhere


FUNCTION LEERDATA(cWhere,oBrw,cServer,cTableA)
   LOCAL aData:={},aTotal:={},oCol,cSql,aLines:={}
   LOCAL oDb

   DEFAULT cWhere:=""

   IF !Empty(cServer)

     IF !EJECUTAR("DPSERVERDBOPEN",cServer)
        RETURN .F.
     ENDIF

     oDb:=oDp:oDb

   ENDIF

   DEFAULT cTableA:="DPAUDELIMODCNF"

    cSql:=[ SELECT ]+;
          [ DOC_NUMERO,DOC_GIRNUM AS ZETA,DOC_SERFIS,DOC_NUMFIS,]+;
          [ DOC_BASNET,DOC_MTOEXE,DOC_MTOIVA,DOC_NETO,DOC_OTROS AS IGTF,DOC_FECHA,DOC_HORA,DOC_NUMMEM ]+;
          [ FROM dpdoccli ]+;
          [ WHERE DOC_TIPDOC="ZIF" ]+IF(Empty(cWhere),""," AND "+cWhere)

   cSql:=EJECUTAR("WHERE_VAR",cSql)

   oDp:lExcluye:=.T.

   aData:=ASQL(cSql,oDb)

   oDp:cWhere:=cWhere


   IF EMPTY(aData)
      aData:=EJECUTAR("SQLARRAYEMPTY",cSql,oDb)
   ENDIF

   IF ValType(oBrw)="O"

      oBemaViewZ:cSql   :=cSql
      oBemaViewZ:cWhere_:=cWhere

      aTotal:=ATOTALES(aData)

      oBrw:aArrayData:=ACLONE(aData)
      oBrw:nArrayAt  :=1
      oBrw:nRowSel   :=1

      oBemaViewZ:oBrw:aCols[1]:cFooter:=" #"+LSTR(LEN(aData))
   
      oBrw:Refresh(.T.)
      AEVAL(oBemaViewZ:oBar:aControls,{|o,n| o:ForWhen(.T.)})

      EJECUTAR("BRWCALTOTALES",oBrw)

      oBemaViewZ:SAVEPERIODO()
      oBemaViewZ:BRWCHANGE()

   ENDIF

RETURN aData


FUNCTION SAVEPERIODO()
  LOCAL cFileMem:="USER\BRPLANTILLADOC.MEM",V_nPeriodo:=oBemaViewZ:nPeriodo
  LOCAL V_dDesde:=oBemaViewZ:dDesde
  LOCAL V_dHasta:=oBemaViewZ:dHasta

  SAVE TO (cFileMem) ALL LIKE "V_*"

RETURN .T.

/*
// Permite Crear Filtros para las B�quedas
*/
FUNCTION BRWQUERY()
     EJECUTAR("BRWQUERY",oBemaViewZ)
RETURN .T.

/*
// Ejecuci�n Cambio de Linea 
*/
FUNCTION BRWCHANGE()
  LOCAL nNumMem:=oBemaViewZ:oBrw:aArrayData[oBemaViewZ:oBrw:nArrayAt,12]

  oBemaViewZ:cMemo:=SQLGET("DPMEMO","MEM_MEMO","MEM_NUMERO"+GetWhere("=",nNumMem))
 // oBemaViewZ:oBrw:aArrayData[oBemaViewZ:oBrw:nArrayAt,12]
  oBemaViewZ:oMemo:VarPut(oBemaViewZ:cMemo,.T.)

 
RETURN NIL

/*
// Refrescar Browse
*/
FUNCTION BRWREFRESCAR()
    LOCAL cWhere


    IF Type("oBemaViewZ")="O" .AND. oBemaViewZ:oWnd:hWnd>0

      cWhere:=" "+IIF(!Empty("oBemaViewZ":cWhere_),"oBemaViewZ":cWhere_,"oBemaViewZ":cWhere)
      cWhere:=STRTRAN(cWhere," WHERE ","")


      oBemaViewZ:LEERDATA(oBemaViewZ:cWhere_,oBemaViewZ:oBrw,oBemaViewZ:cServer)
      oBemaViewZ:oWnd:Show()
      oBemaViewZ:oWnd:Maximize()

    ENDIF

RETURN NIL

FUNCTION TXTGUARDAR()
  LOCAL cFile:=oDp:cBin+"TEMP\FILE.TXT"

  DPWRITE(cFile,oBemaViewZ:cMemo)

//  SHELLEXECUTE(oDp:oFrameDp:hWND,"open",cFile)
  CursorWait()
//  MemoWrit(oRun:cFileTxt,OEMTOANSI(MemoRead(oRun:cFileTxt)))
  WinExec(  GetWinDir()+ "\NOTEPAD.EXE "+cFile)

RETURN .T.

FUNCTION BRWRESTOREPAR()
RETURN EJECUTAR("BRWRESTOREPAR",oBemaViewZ)

FUNCTION VERDETALLES()
   ? "VERDETALLES"
RETURN .T.

// EOF
