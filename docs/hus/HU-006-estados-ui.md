# HU-006 - Estados de UI

## Historia
Como usuario,
quiero ver estados de carga, éxito y error,
para entender el resultado del procesamiento.

## Prioridad
Should

## Criterios de aceptación

### Escenario 1 - Cargando
- GIVEN que el usuario procesa un gasto
- WHEN el sistema está extrayendo datos
- THEN la UI muestra estado de carga

### Escenario 2 - Éxito
- GIVEN que el gasto se guardó
- WHEN termina el proceso
- THEN la UI muestra estado de éxito breve

### Escenario 3 - Error
- GIVEN que ocurre una validación fallida
- WHEN termina el proceso
- THEN la UI muestra mensaje de error

## Casos borde
- Procesamientos consecutivos
- Reintento rápido tras error

## Dependencias
- HU-001
- HU-004

## Trazabilidad técnica
- `lib/features/expenses/presentation/providers/expense_capture_controller.dart`
- `lib/features/expenses/presentation/pages/home_page.dart`

## Definición de listo
- Los tres estados son distinguibles y consistentes para el usuario.
