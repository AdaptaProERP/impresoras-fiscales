// Programa   : DLL_BEMATECH_SETIVA
// Fecha/Hora : 12/07/2024 15:44:46
// Propósito  : Programar tasas de IVA
// Creado Por : Juan Navas
// Llamado por: MENU Serie Fiscal
// Aplicación :
// Tabla      :

#INCLUDE "DPXBASE.CH"

PROCE MAIN()
  LOCAL aIva:=ASQL("SELECT TIP_CODIGO FROM DPIVATIP WHERE TIP_VENTA=1 AND TIP_ACTIVO=1")

RETURN .T.
// EOF

