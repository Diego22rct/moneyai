# HU-005 - Privacidad local-first

## Historia
Como usuario,
quiero que mis datos financieros se procesen localmente,
para mantener mi privacidad.

## Prioridad
Must

## Criterios de aceptación

### Escenario 1 - Persistencia local
- GIVEN que el usuario registra un gasto
- WHEN termina el procesamiento
- THEN la información se guarda localmente en SQLite
- AND no se envía a servicios externos

### Escenario 2 - Operación sin red
- GIVEN que el dispositivo está sin internet
- WHEN el usuario registra un gasto por texto
- THEN el flujo sigue funcionando

## Casos borde
- Red inestable
- Modo avión

## Dependencias
- HU-001
- HU-002

## Trazabilidad técnica
- `lib/features/expenses/data/services/sqlite_service.dart`
- `lib/features/expenses/data/repositories/expense_repository_impl.dart`

## Definición de listo
- El core de gastos funciona sin conectividad y sin envío remoto.
