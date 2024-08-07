// Programa   : DPCAMPOSOPCSETCOLOR
// Fecha/Hora : 08/09/2019 11:03:42
// Prop�sito  : Agregar Campos en Release 20_07
// Creado Por :
// Llamado por:
// Aplicaci�n :
// Tabla      :

#INCLUDE "DPXBASE.CH"

PROCE MAIN()
  LOCAL cId   :="DPOPCSETCOLOR51",oData,cWhere,cSql,I
  LOCAL oDb   :=OpenOdbc(oDp:cDsnData)
  LOCAL oFrm
  LOCAL aFields:={},cWhere
  LOCAL aPeriodos:={}


/*
  oData:=DATASET(cId,"ALL")

  IF oData:Get(cId,"")<>cId 
     oData:End()
  ELSE
     oData:End()
     RETURN
  ENDIF
*/
/*
  IF oDp:lCrearTablas .OR. Empty(oDb:GetTables())
     oData:=DATASET(cId,"ALL")
     oData:Set(cId,cId)
     oData:Save()
     oData:End()
     RETURN .T.
  ENDIF
*/
  oFrm:=MSGRUNVIEW("Actualizando Colores en las Opciones de los Campos")

  AEVAL({"TFHKA","SAMSUNG","BMC","OKIDATA","HK80","OKIDATA","ACLAS","TFHK"},;
        {|a,n,cWhere| cWhere:="OPC_TABLE"+GetWhere("=","DPSERIEFISCAL")+" AND OPC_CAMPO"+GetWhere("=","SFI_IMPFIS")+" AND OPC_TITULO"+GetWhere("=",a),;
                      SQLDELETE("DPCAMPOSOP",cWhere)})

  EJECUTAR("DPCAMPOSOPCADD","DPSERIEFISCAL","SFI_MODFIS","TFHK.SAMSUNG"       ,.T.,15234048,.T.)
  EJECUTAR("DPCAMPOSOPCADD","DPSERIEFISCAL","SFI_MODFIS","TFHK.HK80"          ,.T.,33023   ,.T.)
  EJECUTAR("DPCAMPOSOPCADD","DPSERIEFISCAL","SFI_MODFIS","TFHK.BMC"           ,.T.,255,.T.)


//EJECUTAR("DPCAMPOSOPCADD","DPSERIEFISCAL","SFI_IMPFIS","ACLAS"            ,.T.,34816,.T.)
  EJECUTAR("DPCAMPOSOPCADD","DPSERIEFISCAL","SFI_IMPFIS","BEMATECH"         ,.T.,33023,.T.)
  EJECUTAR("DPCAMPOSOPCADD","DPSERIEFISCAL","SFI_IMPFIS","EPSON"            ,.T.,32768,.T.)
//EJECUTAR("DPCAMPOSOPCADD","DPSERIEFISCAL","SFI_IMPFIS","OKIDATA"          ,.T.,33023,.T.)
  EJECUTAR("DPCAMPOSOPCADD","DPSERIEFISCAL","SFI_IMPFIS","TFHK_EXE"         ,.T.,16776960,.T.)
  EJECUTAR("DPCAMPOSOPCADD","DPSERIEFISCAL","SFI_IMPFIS","TFHK_DLL"             ,.T.,255     ,.T.)
  EJECUTAR("DPCAMPOSOPCADD","DPSERIEFISCAL","SFI_IMPFIS","Caja Registradora",.T.,12615680,.T.)
  EJECUTAR("DPCAMPOSOPCADD","DPSERIEFISCAL","SFI_IMPFIS","Ninguna"          ,.T.,15859954,.T.)

  EJECUTAR("DPCAMPOSOPCADD","DPPROVEEDORPROG","PGC_PERIOD","Semanal"       ,.T.,14774528,.T.)
  EJECUTAR("DPCAMPOSOPCADD","DPPROVEEDORPROG","PGC_PERIOD","Mensual"       ,.T.,16744576,.T.)
  EJECUTAR("DPCAMPOSOPCADD","DPPROVEEDORPROG","PGC_PERIOD","Trimestral"    ,.T.,4227327 ,.T.)
  EJECUTAR("DPCAMPOSOPCADD","DPPROVEEDORPROG","PGC_PERIOD","Bimestral"     ,.T.,16711935,.T.)
  EJECUTAR("DPCAMPOSOPCADD","DPPROVEEDORPROG","PGC_PERIOD","Cuatrimestral" ,.T.,33023   ,.T.)
  EJECUTAR("DPCAMPOSOPCADD","DPPROVEEDORPROG","PGC_PERIOD","Semestral"     ,.T.,16711808,.T.)

  EJECUTAR("DPCAMPOSOPCADD","DPMENU","MNU_VERTIC","Aplicaciones" ,.T.,34816,.T.)
  EJECUTAR("DPCAMPOSOPCADD","DPMENU","MNU_VERTIC","Consultas"    ,.T.,33023,.T.)
  EJECUTAR("DPCAMPOSOPCADD","DPMENU","MNU_VERTIC","Ficheros"     ,.T.,255,.T.)
  EJECUTAR("DPCAMPOSOPCADD","DPMENU","MNU_VERTIC","Informes"     ,.T.,32768,.T.)
  EJECUTAR("DPCAMPOSOPCADD","DPMENU","MNU_VERTIC","Macros"       ,.T.,33023,.T.)
  EJECUTAR("DPCAMPOSOPCADD","DPMENU","MNU_VERTIC","Procesos"     ,.T.,15234048,.T.)
  EJECUTAR("DPCAMPOSOPCADD","DPMENU","MNU_VERTIC","Transacciones",.T.,12615680,.T.)
  EJECUTAR("DPCAMPOSOPCADD","DPMENU","MNU_VERTIC","Otros"        ,.T.,15859954,.T.)

  EJECUTAR("DPCAMPOSOPCADD","DPTIPDOCPRO","TDC_CXP","D�bito" ,.T.,CLR_HBLUE,.T.)
  EJECUTAR("DPCAMPOSOPCADD","DPTIPDOCPRO","TDC_CXP","Cr�dito",.T.,CLR_HRED ,.T.)
  EJECUTAR("DPCAMPOSOPCADD","DPTIPDOCPRO","TDC_CXP","Neutro" ,.T.,0        ,.T.)

  EJECUTAR("DPCAMPOSOPCADD","DPCLIENTES","CLI_SITUAC","Activo"     ,.T.,CLR_HBLUE,.T.)
  EJECUTAR("DPCAMPOSOPCADD","DPCLIENTES","CLI_SITUAC","Inactivo"   ,.T.,CLR_HRED ,.T.)
  EJECUTAR("DPCAMPOSOPCADD","DPCLIENTES","CLI_SITUAC","Suspendido" ,.T.,19948    ,.T.)
  EJECUTAR("DPCAMPOSOPCADD","DPCLIENTES","CLI_SITUAC","Prospecto"  ,.T.,16711935 ,.T.)

  EJECUTAR("DPCAMPOSOPCADD","DPINV","INV_ESTADO","Activo"     ,.T.,CLR_HBLUE,.T.)
  EJECUTAR("DPCAMPOSOPCADD","DPINV","INV_ESTADO","Inactivo"   ,.T.,CLR_HRED ,.T.)
  EJECUTAR("DPCAMPOSOPCADD","DPINV","INV_ESTADO","Suspendido" ,.T.,19948    ,.T.)

  EJECUTAR("DPCAMPOSOPCADD","DPINV","INV_METCOS","Promedio"   ,.T.,CLR_HBLUE,.T.)
  EJECUTAR("DPCAMPOSOPCADD","DPINV","INV_METCOS","Serializado",.T.,CLR_HRED ,.T.)

  EJECUTAR("DPCAMPOSOPCADD","DPINV","INV_PREREG","Si"   ,.T.,CLR_HBLUE,.T.)
  EJECUTAR("DPCAMPOSOPCADD","DPINV","INV_PREREG","No"   ,.T.,CLR_HRED ,.T.)

  EJECUTAR("DPCAMPOSOPCADD","DPINV","INV_REQMEM","Si"   ,.T.,CLR_HBLUE,.T.)
  EJECUTAR("DPCAMPOSOPCADD","DPINV","INV_REQMEM","No"   ,.T.,CLR_HRED ,.T.)

  EJECUTAR("DPCAMPOSOPCADD","DPINV","INV_UTILIZ","Venta"      ,.T.,CLR_HBLUE ,.T.)

  EJECUTAR("DPCAMPOSOPCADD","DPPROVEEDOR","PRO_SITUAC","Activo"        ,.T.,CLR_HBLUE,.T.)
  EJECUTAR("DPCAMPOSOPCADD","DPPROVEEDOR","PRO_SITUAC","Inactivo"      ,.T.,CLR_HRED ,.T.)
  EJECUTAR("DPCAMPOSOPCADD","DPPROVEEDOR","PRO_SITUAC","Suspendido"    ,.T.,19948    ,.T.)
  EJECUTAR("DPCAMPOSOPCADD","DPPROVEEDOR","PRO_SITUAC","Por Formalizar",.T.,16711935 ,.T.)

  EJECUTAR("DPCAMPOSOPCADD","DPTIPDOCPRO","TDC_INVEXI","Suma"  ,.T.,CLR_HBLUE,.T.)
  EJECUTAR("DPCAMPOSOPCADD","DPTIPDOCPRO","TDC_INVEXI","Resta" ,.T.,CLR_HRED ,.T.)
  EJECUTAR("DPCAMPOSOPCADD","DPTIPDOCPRO","TDC_INVEXI","Neutro",.T.,0        ,.T.)


  EJECUTAR("DPCAMPOSOPCADD","DPTIPDOCCLI","DOC_DOCORG","Documento" ,.T.,CLR_HBLUE,.T.)
  EJECUTAR("DPCAMPOSOPCADD","DPTIPDOCCLI","DOC_DOCORG","Pago"      ,.T.,CLR_HRED ,.T.)
  EJECUTAR("DPCAMPOSOPCADD","DPTIPDOCCLI","DOC_DOCORG","Recibo"    ,.T.,4227072  ,.T.)

  EJECUTAR("DPCAMPOSOPCADD","DPEXPTAREASDEF","TDF_APLICA","Cliente"   ,.T.,CLR_HBLUE,.T.)
  EJECUTAR("DPCAMPOSOPCADD","DPEXPTAREASDEF","TDF_APLICA","Proveedor" ,.T.,CLR_HRED ,.T.)
  EJECUTAR("DPCAMPOSOPCADD","DPEXPTAREASDEF","TDF_APLICA","Trabajador",.T.,4227072  ,.T.)
  EJECUTAR("DPCAMPOSOPCADD","DPEXPTAREASDEF","TDF_APLICA","Todos"     ,.T.,0        ,.T.)

  EJECUTAR("DPCAMPOSOPCADD","DPTIPDOCCLI","TDC_CXC","D�bito" ,.T.,CLR_HBLUE,.T.)
  EJECUTAR("DPCAMPOSOPCADD","DPTIPDOCCLI","TDC_CXC","Cr�dito",.T.,CLR_HRED ,.T.)
  EJECUTAR("DPCAMPOSOPCADD","DPTIPDOCCLI","TDC_CXC","Neutro" ,.T.,0        ,.T.)

  EJECUTAR("DPCAMPOSOPCADD","DPTIPDOCCLI","TDC_INVEXI","Suma"  ,.T.,CLR_HBLUE,.T.)
  EJECUTAR("DPCAMPOSOPCADD","DPTIPDOCCLI","TDC_INVEXI","Resta" ,.T.,CLR_HRED ,.T.)
  EJECUTAR("DPCAMPOSOPCADD","DPTIPDOCCLI","TDC_INVEXI","Neutro",.T.,0        ,.T.)

  EJECUTAR("DPCAMPOSOPCADD","DPTIPDOCCLI","TDC_EXIVAL","Contable"  ,.T.,2255615,.T.)

  EJECUTAR("DPCAMPOSOPCADD","DPTIPDOCCLI","TDC_INVACT","Suma"   ,.T.,CLR_HBLUE,.T.)
  EJECUTAR("DPCAMPOSOPCADD","DPTIPDOCCLI","TDC_INVACT","Resta"  ,.T.,CLR_HRED ,.T.)
  EJECUTAR("DPCAMPOSOPCADD","DPTIPDOCCLI","TDC_INVACT","Ninguna",.T.,0        ,.T.)

  cWhere:="OPC_TABLE"+GetWhere("=","DPASIENTOS")+" AND "+;
          "OPC_CAMPO"+GetWhere("=","MOC_TIPTRA")
  SQLDELETE("DPCAMPOSOP",cWhere)

  EJECUTAR("DPCAMPOSOPCADD","DPASIENTOS","MOC_TIPTRA","Documento"   ,.T.,16744448 ,.T.)
  EJECUTAR("DPCAMPOSOPCADD","DPASIENTOS","MOC_TIPTRA","Pago"        ,.T.,CLR_HRED ,.T.)
  EJECUTAR("DPCAMPOSOPCADD","DPASIENTOS","MOC_TIPTRA","Banco"       ,.T.,16712708 ,.T.)

  cWhere:="OPC_TABLE"+GetWhere("=","DPASIENTOS")+" AND "+;
          "OPC_CAMPO"+GetWhere("=","MOC_ACTUAL")

  SQLDELETE("DPCAMPOSOP",cWhere)
  EJECUTAR("DPCAMPOSOPCADD","DPASIENTOS","MOC_ACTUAL","Si Actualizado",.T.,16744448,.T.)
  EJECUTAR("DPCAMPOSOPCADD","DPASIENTOS","MOC_ACTUAL","No Actualizado",.T.,5548032 ,.T.)
  EJECUTAR("DPCAMPOSOPCADD","DPASIENTOS","MOC_ACTUAL","Auditor"       ,.T.,3566592 ,.T.)

  EJECUTAR("DPCAMPOSOPCADD","DPVENDEDOR","VEN_SITUAC","Activo"       ,.T.,16744448 ,.T.)
  EJECUTAR("DPCAMPOSOPCADD","DPVENDEDOR","VEN_SITUAC","Inactivo"     ,.T.,255      ,.T.)


  EJECUTAR("DPCAMPOSOPCADD","DPCBTE","CBT_ACTUAL","Si Actualizado",.T.,16744448,.T.)
  EJECUTAR("DPCAMPOSOPCADD","DPCBTE","CBT_ACTUAL","No Actualizado",.T.,5548032 ,.T.)
  EJECUTAR("DPCAMPOSOPCADD","DPCBTE","CBT_ACTUAL","Auditor"       ,.T.,3566592 ,.T.)

  EJECUTAR("DPCAMPOSOPCADD","DPDOCCLI","DOC_TIPTRA","Documento"    ,.T.,12016384,.T.)
  EJECUTAR("DPCAMPOSOPCADD","DPDOCCLI","DOC_TIPTRA","Transferencia",.T.,16744576,.T.)


  EJECUTAR("DPCAMPOSOPCADD","DPDOCCLI","DOC_DOCORG","Ventas"   ,.T.,16744448,.T.)
  EJECUTAR("DPCAMPOSOPCADD","DPDOCCLI","DOC_DOCORG","Recibo"   ,.T.,5548032 ,.T.)
  EJECUTAR("DPCAMPOSOPCADD","DPDOCCLI","DOC_DOCORG","Documento",.T.,3566592 ,.T.)


  EJECUTAR("DPCAMPOSOPCADD","DPDOCCLI","DOC_ESTADO","Activo"    ,.T.,16744448,.T.)
  EJECUTAR("DPCAMPOSOPCADD","DPDOCCLI","DOC_ESTADO","Pagado"    ,.T.,16711808,.T.)
  EJECUTAR("DPCAMPOSOPCADD","DPDOCCLI","DOC_ESTADO","Nulo"      ,.T.,255     ,.T.)
  EJECUTAR("DPCAMPOSOPCADD","DPDOCCLI","DOC_ESTADO","Exportado" ,.T.,16744576,.T.)



  EJECUTAR("DPCAMPOSOPCADD","DPDOCPRO","DOC_TIPTRA","Documento"    ,.T.,12016384,.T.)
  EJECUTAR("DPCAMPOSOPCADD","DPDOCPRO","DOC_TIPTRA","Transferencia",.T.,16744576,.T.)
  EJECUTAR("DPCAMPOSOPCADD","DPDOCPRO","DOC_TIPTRA","Pago"         ,.T.,4849421,.T.)

  EJECUTAR("DPCAMPOSOPCADD","DPDOCPRO","DOC_ESTADO","Activo"    ,.T.,16744448,.T.)
  EJECUTAR("DPCAMPOSOPCADD","DPDOCPRO","DOC_ESTADO","Pagado"    ,.T.,16711808,.T.)
  EJECUTAR("DPCAMPOSOPCADD","DPDOCPRO","DOC_ESTADO","Nulo"      ,.T.,8421504,.T.)
  EJECUTAR("DPCAMPOSOPCADD","DPDOCPRO","DOC_ESTADO","Anulado"   ,.T.,8421504,.T.)

  EJECUTAR("DPCAMPOSOPCADD","DPDOCPRO","DOC_ORIGEN","Nacional"  ,.T.,8421504 ,.T.)
  EJECUTAR("DPCAMPOSOPCADD","DPDOCPRO","DOC_ORIGEN","Importado" ,.T.,16711808,.T.)

  EJECUTAR("DPCAMPOSOPCADD","DPDOCMOV","DOC_ESTADO","Activo"    ,.T.,16744448,.T.)
  EJECUTAR("DPCAMPOSOPCADD","DPDOCMOV","DOC_ESTADO","Nulo"      ,.T.,255     ,.T.)

  EJECUTAR("DPCAMPOSOPCADD","DPDOCCLI","DOC_NUMPER","TO=excedi� Espera"     ,.T.,16744448,.T.)
  EJECUTAR("DPCAMPOSOPCADD","DPDOCCLI","DOC_NUMPER","NP=Puerto no Abierto"  ,.T.,255     ,.T.)
  EJECUTAR("DPCAMPOSOPCADD","DPDOCCLI","DOC_NUMPER","ER=Error Impresora"    ,.T.,4144959 ,.T.)

  EJECUTAR("DPCAMPOSOPCADD","DPRECIBOSCLI","REC_ESTADO","Activo"  ,.T.,CLR_HBLUE ,.T.)
  EJECUTAR("DPCAMPOSOPCADD","DPRECIBOSCLI","REC_ESTADO","Nulo"    ,.T.,CLR_HRED  ,.T.)

  EJECUTAR("DPCAMPOSOPCADD","DPRECIBOSCLI","REC_ESTADO","Activo"  ,.T.,CLR_HBLUE ,.T.)
  EJECUTAR("DPCAMPOSOPCADD","DPRECIBOSCLI","REC_ESTADO","Anulado" ,.T.,CLR_HRED  ,.T.)
  EJECUTAR("DPCAMPOSOPCADD","DPRECIBOSCLI","REC_ESTADO","Anulado" ,.T.,CLR_HRED  ,.T.)

  EJECUTAR("DPCAMPOSOPCADD","DPRECIBOSCLI","REC_TIPPAG","Pago"     ,.T.,4227072,.T.)
  EJECUTAR("DPCAMPOSOPCADD","DPRECIBOSCLI","REC_TIPPAG","Anticipo" ,.T.,255,.T.)

  SQLDELETE("DPCAMPOSOP","OPC_TITULO"+GetWhere("=","Anulado")+" AND OPC_TABLE"+GetWhere("=","DPCBTEPAGO"))

  EJECUTAR("DPCAMPOSOPCADD","DPCBTEPAGO","PAG_ESTADO","Activo"  ,.T.,CLR_HBLUE ,.T.)
  EJECUTAR("DPCAMPOSOPCADD","DPCBTEPAGO","PAG_ESTADO","Nulo" ,.T.,CLR_HRED  ,.T.)

  EJECUTAR("DPCAMPOSOPCADD","DPCBTEPAGO","PAG_TIPPAG","Pago"       ,.T.,4227072,.T.)
  EJECUTAR("DPCAMPOSOPCADD","DPCBTEPAGO","PAG_TIPPAG","Anticipo"   ,.T.,255,.T.)
  EJECUTAR("DPCAMPOSOPCADD","DPCBTEPAGO","PAG_TIPPAG","Otros Pagos",.T.,33023,.T.)

  EJECUTAR("DPCAMPOSOPCADD","DPINVPLAABAST","IPA_TIPEXI","F�sica"   ,.T.,16744448 ,.T.)
  EJECUTAR("DPCAMPOSOPCADD","DPINVPLAABAST","IPA_TIPEXI","L�gica"   ,.T.,30444    ,.T.)
  EJECUTAR("DPCAMPOSOPCADD","DPINVPLAABAST","IPA_TIPEXI","Contable" ,.T.,5217536  ,.T.)

  EJECUTAR("DPCAMPOSOPCADD","DPINVPLAABAST","IPA_TIPREP","Compra"     ,.T.,30444    ,.T.)
  EJECUTAR("DPCAMPOSOPCADD","DPINVPLAABAST","IPA_TIPREP","Producci�n" ,.T.,5217536  ,.T.)

 // Tipos de Proveedor
  EJECUTAR("DPCAMPOSOPCADD","DPPROVEEDOR","PRO_TIPO","Proveedor"             ,.T.,34816,.T.)
  EJECUTAR("DPCAMPOSOPCADD","DPPROVEEDOR","PRO_TIPO","Prestador de Servicios",.T.,33023,.T.)
  EJECUTAR("DPCAMPOSOPCADD","DPPROVEEDOR","PRO_TIPO","Recaudador Tributario" ,.T.,255,.T.)
  EJECUTAR("DPCAMPOSOPCADD","DPPROVEEDOR","PRO_TIPO","Accionista"            ,.T.,15234048,.T.)


  EJECUTAR("DPCAMPOSOPCADD","DPPROVEEDOR","PRO_TIPPER","Natural"             ,.T.,4227327,.T.)
  EJECUTAR("DPCAMPOSOPCADD","DPPROVEEDOR","PRO_TIPPER","Jur�dica"            ,.T.,16744448,.T.)
  EJECUTAR("DPCAMPOSOPCADD","DPPROVEEDOR","PRO_TIPPER","Gubernamental"       ,.T.,255,.T.)
  EJECUTAR("DPCAMPOSOPCADD","DPPROVEEDOR","PRO_TIPPER","Consejo Comunal"     ,.T.,11403438,.T.)


  EJECUTAR("DPCAMPOSOPCADD","DPCLIENTES","CLI_TIPPER","Natural"             ,.T.,4227327,.T.)
  EJECUTAR("DPCAMPOSOPCADD","DPCLIENTES","CLI_TIPPER","Jur�dica"            ,.T.,16744448,.T.)
  EJECUTAR("DPCAMPOSOPCADD","DPCLIENTES","CLI_TIPPER","Gubernamental"       ,.T.,255,.T.)

  EJECUTAR("DPCAMPOSOPCADD","DPCLIENTES","CLI_CONESP","Si"            ,.T.,4227327,.T.)
  EJECUTAR("DPCAMPOSOPCADD","DPCLIENTES","CLI_CONESP","No"            ,.T.,16744448,.T.)

  EJECUTAR("DPCAMPOSOPCADD","DPCLIENTES","CLI_DESFIJ","Si"            ,.T.,4227327,.T.)
  EJECUTAR("DPCAMPOSOPCADD","DPCLIENTES","CLI_DESFIJ","No"            ,.T.,16744448,.T.)

  EJECUTAR("DPCAMPOSOPCADD","DPUNDMED","UND_TIPO","Cantidad"  ,.T.,4227327,.T.)
  EJECUTAR("DPCAMPOSOPCADD","DPUNDMED","UND_TIPO","Peso"     ,.T.,16744448,.T.)
  EJECUTAR("DPCAMPOSOPCADD","DPUNDMED","UND_TIPO","Tiempo"   ,.T.,255,.T.)
  EJECUTAR("DPCAMPOSOPCADD","DPUNDMED","UND_TIPO","Volumen"  ,.T.,16711808,.T.)

  EJECUTAR("DPCAMPOSOPCADD","DPCLIENTES","CLI_CATEGO","Afiliados"   ,.T.,CLR_HBLUE,.T.)


  aPeriodos:={}
  AADD(aPeriodos,"Minutos")
  AADD(aPeriodos,"Horas")

  AEVAL(oDp:aPeriodos,{|a,n| AADD(aPeriodos,a)})
  AEVAL(aPeriodos,{|a,n| EJECUTAR("DPCAMPOSOPCADD","DPUNDMED","UND_PERIOD",a ,.T.,0,.T.)})

  EJECUTAR("DPCAMPOSOPCADD","DPUNDMED","UND_PERIODO","Diario"  ,.T.,4227327,.T.)
  EJECUTAR("DPCAMPOSOPCADD","DPUNDMED","UND_TIPO","Peso"     ,.T.,16744448,.T.)
  EJECUTAR("DPCAMPOSOPCADD","DPUNDMED","UND_TIPO","Tiempo"   ,.T.,255,.T.)
  EJECUTAR("DPCAMPOSOPCADD","DPUNDMED","UND_TIPO","Volumen"  ,.T.,16711808,.T.)




//EJECUTAR("DPCAMPOSOPCADD","DPPROVEEDOR","PRO_TIPO","Recaudador Tributario" ,.T.,255    ,.T.)

/*
  DpMsgClose()

  oData:=DATASET(cId,"ALL")
  oData:Set(cId,cId)
  oData:Save()
  oData:End()
*/
  cSql:=" SET FOREIGN_KEY_CHECKS = 1"
  oDb:Execute(cSql)

  oDp:aCamposOpc:={}

RETURN .T.
// EOF




RETURN
