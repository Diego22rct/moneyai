# HU-002 - Listado persistente

## Historia
Como usuario,
quiero ver mis gastos guardados al abrir la app,
para revisar el historial sin volver a capturarlo.

## Prioridad
Must

## Criterios de aceptación

### Escenario 1 - Carga inicial
- GIVEN que existen gastos en SQLite
- WHEN la app abre la pantalla principal
- THEN se listan los gastos ordenados por fecha descendente

### Escenario 2 - Reinicio de app
- GIVEN que se registró un gasto
- WHEN el usuario cierra y abre la app
- THEN el gasto sigue visible en el listado

## Casos borde
- Base de datos vacía
- Registros con timestamps cercanos

## Dependencias
- HU-001

## Trazabilidad técnica
- `lib/features/expenses/presentation/providers/expense_list_provider.dart`
- `lib/features/expenses/data/datasources/expense_local_datasource.dart`
- `lib/features/expenses/data/services/sqlite_service.dart`

## Definición de listo
- Los gastos se leen desde SQLite en cada inicio.
