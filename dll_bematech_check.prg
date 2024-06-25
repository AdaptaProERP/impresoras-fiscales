// Programa   : DLL_BEMATECH_CHECK        
// Fecha/Hora : 24/06/2024 15:19:11
// Propósito  : Detecta estado de la impresora
// Creado Por : Juan Navas
// Llamado por: DLL_BEMATECH
// Aplicación :
// Tabla      :

#INCLUDE "DPXBASE.CH"

PROCE MAIN()
 LOCAL cError:="",nRet,lVerCup:=.T.,lShow:=.T.
 LOCAL iACK,iST1,iST2

 WHILE .T.

  //??"else cError", nRet
    iACK := 0
    iST1 := 0
    iST2 := 0
    nRet := BmVerEstado( @iACK, @iST1, @iST2 )

    iACK:=oBema:ACX
    iST1:=oBema:ST1
    iST2:=oBema:ST2

  //??"else2222 cError", nRet, iACK, iST1, iST2
    IF iACK = 21
      MensajeErr("La impresora ha retornado NAK !", [Atención] )
    ELSE

    IF ( iST1 <> 0 ) .OR. ( iST2 <> 0 )

        cError:=""
        // Analiza ST1

        IF ( iST1 >= 128 )
           iST1 := iST1 - 128
           cError := cError+ "Fin de Papel" + chr(13)
        ENDIF

        IF ( iST1 >= 64 )
            iST1 := iST1 - 64
            cError := cError+ "Poco Papel" + chr(13)
        ENDIF

        IF ( iST1 >= 32 )
            iST1 := iST1 - 32
            cError := cError+ "Error en el Reloj" + chr(13)
        ENDIF

        IF ( iST1 >= 16 )
          iST1 := iST1 - 16
          cError := cError+ 'Impresora con error' + chr(13)
        ENDIF

        IF ( iST1 >= 8 )
          iST1 :=  iST1 - 8
          cError := cError+ "Primer dato del comando no fue ESC" + chr(13)
        ENDIF

        IF iST1 >= 4
          iST1 :=  iST1 - 4
          cError := cError+ "Comando inexistente" + chr(13)
        ENDIF

       if iST1 >= 2
          iST1 :=  iST1 - 2
          if lVerCup
             cError := cError+ "Cupón fiscal abierto" + chr(13)
          ENDIF
       ENDIF

       IF iST1 >= 1
          iST1 :=  iST1 - 1
          cError := cError+ "Número de parámetros inválidos" + chr(13)
       ENDIF

       //  Analisa ST2
       IF iST2 >= 128
          iST2 :=  iST2 - 128
          cError := cError+ "Tipo de parámetro de comando inválido" + chr(13)
       ENDIF

       IF iST2 >= 64
          iST2 :=  iST2 - 64
          cError := cError+ "Memória fiscal llena" + chr(13)
       ENDIF

       IF iST2 >= 32
          iST2 :=  iST2 - 32
          cError := cError+ "Error en la CMOS" + chr(13)
       ENDIF

       IF iST2 >= 16
          iST2 :=  iST2 - 16
          cError := cError+ "Alicuota no programada" + chr(13)
       ENDIF

       IF iST2 >= 8
          iST2 :=  iST2 - 8
          cError := cError+ "Capacidad de Alicuota Programables llena" + chr(13)
       ENDIF

       IF iST2 >= 4
          iST2 :=  iST2 - 4
          cError := cError+ "Cancelamiento no permitido" + chr(13)
       ENDIF

       IF iST2 >= 2
          iST2 :=  iST2 - 2
          cError := cError+ "RIF del propietario no Programados" + chr(13)
       ENDIF

       IF iST2 >= 1
          iST2 :=  iST2 - 1
          cError := cError+ "Comando no ejecutado" + chr(13)
       ENDIF

       //Alert (cError, "Atención" )

       IF !EMPTY(cError)
          cError:="Error:"+LSTR(nRet)+", "+cError
          IF lShow
             MensajeErr(cError,"Error Impresora Bematech.")
           ENDIF
       ENDIF

     ENDIF

       // Return (cError)
    ENDIF

     IF EMPTY(cError) .OR.  !("Fin de Papel" $ cError .OR. "Poco Papel" $ cError)
        EXIT
     ENDIF

  ENDDO

  //??"endif cError", cError

  IF !EMPTY(cError)
     cError:="Error:"+LSTR(nRet)+", "+cError
     IF lShow
       MensajeErr(cError,"Error Impresora Bematech")
     ENDIF
  ENDIF

RETURN cError

FUNCTION BmVerEstado(ACX ,ST1,ST2 ) 
   LOCAL hDLL   :=oDp:nBemaDLL
   LOCAL uResult:=NIL 
   LOCAL cFunc  :="Bematech_FI_VerificaEstadoImpresora"
   LOCAL cFarProc 

   oBema:ACX:=ACX
   oBema:ST1:=ST1
   oBema:ST2:=ST2

   IF !oDp:lImpFisModVal
     cFarProc:= GetProcAddress(hDLL,cFunc,.T.,7,10 ,10,10 )
     uResult := CallDLL(cFarProc,@ACX ,@ST1,@ST2 )

     oBema:ACX:=ACX
     oBema:ST1:=ST1
     oBema:ST2:=ST2
   ENDIF

   oBema:oFile:AppStr("BmVerEstado(ACX->"+CTOO(ACX,"C")+;
                                        ",ST1->"+CTOO(ST1,"C")+;
                                        ",ST2->"+CTOO(ST2,"C")+")nResult="+CTOO(uResult,"C")+CRLF)


RETURN uResult
