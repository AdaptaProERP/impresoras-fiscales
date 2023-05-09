// Programa   : DLL_TFHKA_TEST
// Fecha/Hora : 07/10/2022 12:00:00 M
// Propósito  : LLamadas TFHKA DLL
// Creado Por :
// Llamado por:DLL_IMPFISCAL
// Aplicación :
// Tabla      :

#INCLUDE "DPXBASE.CH"

PROCE MAIN()
  LOCAL lStatus,lError
  LOCAL lRespuesta,lRespuesta2
  LOCAL cFileLog:=""

  IF TYPE("oTFHKA")="O"

    TDpClass():New(NIL,"oTFHKA")
    oTFHKA:hDll    :=NIL
    oTFHKA:cName   :="TFHKA"
    oTFHKA:cFileDll:="tfhkaif.dll"
    oTFHKA:cEstatus:=""
    oTFHKA:oFile   :=NIL

  ENDIF
  
  IF !FILE(oTFHKA:cFileDll)
    ? "No se Encuenta Archivo "+oTFHKA:cFileDll
    RETURN NIL
  ENDIF

  oTFHKA:cFileLog:="TEST.LOG"
  oTFHKA:oFile   :=TFile():New(oTFHKA:cFileLog)

? oTFHKA:cFileLog

  oTFHKA:hDll    := LoadLibrary(oTFHKA:cFileDll)
  oTFHKA:cPort   :="COM4" // Valor por Defecto

  IF !(Abs(oTFHKA:hDLL) > 32)
     MensajeErr("Error Leyendo Libreria "+oTFHKA:cFileDll)
     oTFHKA:IFCERRARDLL()
     RETURN NIL
  ENDIF

  MSGALERT(oTFHKA:hDll,"LEE EL DLL: ")

  //oTFHKA:IFABRIRDLL()

  oTFHKA:IFOPEN()

  oTFHKA:IFABREFISCAL()

  oTFHKA:IFRENGLON()   
    
  oTFHKA:IFPRINT()

  oTFHKA:IFCLOSE()

  SysRefresh(.T.)

RETURN .T.

//////////////////////////////////////
//////////// FUNCIONES////////////////
//////////////////////////////////////
FUNCTION IFOPEN()
  LOCAL cResp,lResp
 
  lResp:=PFRUNCMD("OpenFpCtrl","COM4")

? lResp,"lResp"

/*
  IF lRespuesta#1
     lRespuesta=oTFHKA:IFCLOSE()
     lRespuesta2=oTFHKA:PFRUNCMD("OpenFpCtrl","COM4")
     IF lRespuesta2#1
  	   ? "NO ABRIO EL PUERTO COMx"
        RETURN NIL
     ENDIF
  ENDIF
? "ABRIENDO EL PUERTO COMx" 
*/		
RETURN .T.

FUNCTION IFABREFISCAL()
  LOCAL cResp
  LOCAL lStatus,lError,lCadena

  lStatus:=0
  lError :=0
  lCadena:=""
  
/*
    cResp:=oTFHKA:PFRUNCMD("sendcmd",@lStatus,@lError,CHR(105)+CHR(70)+CHR(42) + "Nro. Factura: " + "0000000001")
    cResp:=oTFHKA:PFRUNCMD("sendcmd",@lStatus,@lError,CHR(105)+CHR(68)+CHR(42) + "Fecha: " + "07-10-2022")
    cResp:=oTFHKA:PFRUNCMD("sendcmd",@lStatus,@lError,CHR(105)+CHR(83)+CHR(42) + "Nombre : " + "EL CLIENTE DEMO")
    cResp:=oTFHKA:PFRUNCMD("sendCmd",@lStatus,@lError,CHR(105)+CHR(82)+CHR(42) + "Rif/Cedula : " + "V00000000")
    cResp:=oTFHKA:PFRUNCMD("sendCmd",@lStatus,@lError,CHR(105)+CHR(48)+CHR(48) + "Telefono : " + "0000-0000000")
    cResp:=oTFHKA:PFRUNCMD("sendCmd",@lStatus,@lError,CHR(105)+CHR(48)+CHR(48) + "Direccion : " + "CARACAS")
	 
*/	 

    cResp:=oTFHKA:PFRUNCMD("sendCmd",@lStatus,@lError,CHR(105)+CHR(82)+CHR(42) + "Rif/Cedula : " + "V00000000")
    cResp:=oTFHKA:PFRUNCMD("sendcmd",@lStatus,@lError,CHR(105)+CHR(83)+CHR(42) + "Nombre : " + "EL CLIENTE DEMO")
    cResp:=oTFHKA:PFRUNCMD("sendCmd",@lStatus,@lError,CHR(105)+CHR(48)+CHR(48) + "Telefono : " + "0000-0000000")
    cResp:=oTFHKA:PFRUNCMD("sendCmd",@lStatus,@lError,CHR(105)+CHR(48)+CHR(48) + "Direccion : " + "CARACAS")
    cResp:=oTFHKA:PFRUNCMD("sendcmd",@lStatus,@lError,CHR(105)+CHR(70)+CHR(42) + "Nro. Factura: " + "0000000001")
    cResp:=oTFHKA:PFRUNCMD("sendcmd",@lStatus,@lError,CHR(105)+CHR(68)+CHR(42) + "Fecha: " + "07-10-2022")

RETURN .T.



FUNCTION IFRENGLON()   
  LOCAL cResp,lResp
  LOCAL lStatus,lError,lCadena

  lStatus:=0
  lError :=0
  lCadena:=""

  lCadena := "!00000000010000001000EL PRODUCTO DE PRUEBA"
  cResp   :=oTFHKA:PFRUNCMD("sendcmd",lStatus,lError,lCadena)

RETURN lResp

FUNCTION IFPRINT()
  LOCAL cResp:="1"

If cResp#1
   ? "Error y procedo a anular esta factura" 
    oTFHKA:PFRUNCMD("Sendcmd",@lstatus, @lerror, "7")
ELSE
    // SI IGTF NO ESTA ACTIVO, ENTONCES SE COMENTA LA LINEA CON EL NUMERO 3 Y EL 199 PARA DEJAR SOLO EL 110 COMO PAGO DIRECTO EN EFECTIVO
    oTFHKA:PFRUNCMD("Sendcmd",@lstatus, @lerror, "3")
    oTFHKA:PFRUNCMD("Sendcmd",@lstatus, @lerror, "110")
    oTFHKA:PFRUNCMD("Sendcmd",@lstatus, @lerror, "199")
ENDIF

RETURN .T.

FUNCTION IFREPORTEX()
  oTFHKA:PFRUNCMD("Sendcmd",@lstatus,@lerror, "I0X")
RETURN

FUNCTION IFREPORTEZ()
  oTFHKA:PFRUNCMD("Sendcmd",@lstatus,@lerror, "I0Z")
  oTFHKA:PFRUNCMD("closefpctrl","")
RETURN 

FUNCTION PFRUNCMD(cFunc,cPar1,cPar2,cPar3,cPar4,cPar5,cPar6,cPar7,cPar8,cPar9)
  LOCAL uResult, cFarProc, hDLL:=oTFHKA:hDll 
     
  cFarProc:= GetProcAddress(hDLL,cFunc,.T.,7,8,8,8,8,8,8,8,8,8 )
  uResult := CallDLL(cFarProc,cPar1,cPar2,cPar3,cPar4,cPar5,cPar6,cPar7,cPar8,cPar9)  

  IF ValType(uResult)="C" 
    oEpson:oFile:AppStr(cFunc+","+cPar1+CTOO(uResult,"C"))
  ENDIF

RETURN uResult

FUNCTION IFCLOSE()

   IF oTFHKA:hDLL>0
     oTFHKA:PFRUNCMD("closefpctrl","")
   ENDIF

   oTFHKA:IFCERRARDLL()

   IF(oTFHKA:oFile=NIL,NIL,oTFHKA:oFile:Close())

RETURN 


FUNCTION IFABRIRDLL()
  LOCAL cFileLog:=""


  IF !FILE(oTFHKA:cFileDll)
    ? "No se Encuenta Archivo "+oTFHKA:cFileDll
    RETURN NIL
  ENDIF

  oTFHKA:oFile:=TFile():New(cFileLog)

  oTFHKA:hDll    := LoadLibrary(oTFHKA:cFileDll)
  oTFHKA:cPort   :="COM4" // Valor por Defecto

  IF !(Abs(oTFHKA:hDLL) > 32)
     MensajeErr("Error Leyendo Libreria "+oTFHKA:cFileDll)
     oTFHKA:IFCERRARDLL()
     RETURN NIL
  ENDIF

  MSGALERT(oTFHKA:hDll,"LEE EL DLL: ")

RETURN .T.

FUNCTION IFCERRARDLL()

? oTFHKA:hDLL,"oTFHKA:hDLL "
  FreeLibrary(oTFHKA:hDLL ) 
  oTFHKA:hDLL:=NIL

RETURN .T.

/*
0 No hay error.
1 Fin en la entrega de papel.
2 Error de índole mecánico en la entrega de papel.
3 Fin en la entrega de papel y error mecánico.
80 Comando invalido o valor invalido. 
84 Tasa invalida.
88No hay asignadas directivas. 
92 Comando invalido.
96Error fiscal. 
100 Error de la memoria fiscal.
108Memoria fiscal llena. 
112 Buffer completo. (debe enviar el comando de reinicio)
128Error en la comunicación. 
137 No hay respuesta.
144Error LRC. 
145 Error interno api.
153Error en la apertura del archivo.
*/

//
