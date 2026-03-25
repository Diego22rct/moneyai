# HU-003 - Validación de extracción

## Historia
Como usuario,
quiero que solo se guarden gastos válidos,
para mantener mi historial limpio y confiable.

## Prioridad
Must

## Criterios de aceptación

### Escenario 1 - JSON válido
- GIVEN que el motor de extracción devuelve datos válidos
- WHEN el sistema valida el resultado
- THEN permite persistir el gasto

### Escenario 2 - Datos inválidos
- GIVEN que falta monto o categoría inválida
- WHEN el sistema valida el resultado
- THEN rechaza la persistencia
- AND muestra un mensaje de error

## Casos borde
- Monto en formato decimal con coma o punto
- Categoría no reconocida

## Dependencias
- HU-004

## Trazabilidad técnica
- `lib/features/expenses/data/services/local_nlu_service.dart`
- `lib/features/expenses/domain/entities/expense.dart`
- `lib/core/constants/expense_categories.dart`

## Definición de listo
- No se guarda ningún gasto con campos obligatorios faltantes.
