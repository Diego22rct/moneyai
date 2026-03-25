# HU-001 - Registro por texto

## Historia
Como usuario,
quiero registrar un gasto escribiendo una frase natural,
para guardar movimientos de forma rápida.

## Prioridad
Must

## Criterios de aceptación

### Escenario 1 - Registro exitoso
- GIVEN que el usuario escribe un texto con monto
- WHEN presiona Procesar
- THEN el sistema extrae datos del gasto y lo guarda en SQLite
- AND muestra confirmación de guardado

### Escenario 2 - Entrada vacía
- GIVEN que el campo de texto está vacío
- WHEN presiona Procesar
- THEN el sistema bloquea el envío
- AND muestra mensaje de validación

## Casos borde
- Texto con moneda no explícita
- Texto con descripción corta
- Texto con espacios extra

## Dependencias
- HU-003
- HU-006

## Trazabilidad técnica
- `lib/features/expenses/presentation/pages/home_page.dart`
- `lib/features/expenses/presentation/providers/expense_capture_controller.dart`
- `lib/features/expenses/domain/usecases/record_text_expense.dart`

## Definición de listo
- Se puede registrar un gasto por texto y se persiste correctamente.
