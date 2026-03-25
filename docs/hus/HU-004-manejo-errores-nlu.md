# HU-004 - Manejo de errores NLU

## Historia
Como usuario,
quiero feedback claro cuando la extracción falla,
para corregir el texto y reintentar.

## Prioridad
Must

## Criterios de aceptación

### Escenario 1 - Error de extracción
- GIVEN que el texto no permite inferir monto
- WHEN el usuario procesa el gasto
- THEN la app muestra estado de error
- AND no inserta ningún registro

### Escenario 2 - Reintento
- GIVEN que ocurrió un error previo
- WHEN el usuario corrige el texto y reintenta
- THEN el sistema procesa y guarda correctamente

## Casos borde
- Texto ambiguo
- Símbolos especiales

## Dependencias
- HU-001
- HU-003

## Trazabilidad técnica
- `lib/features/expenses/presentation/providers/expense_capture_controller.dart`
- `lib/features/expenses/presentation/pages/home_page.dart`

## Definición de listo
- Los errores son visibles y el usuario puede reintentar sin reiniciar la app.
