# HU-007 - Preparación para STT

## Historia
Como equipo,
quiero dejar un contrato de entrada desacoplado,
para integrar STT en la siguiente iteración sin romper el core.

## Prioridad
Could

## Criterios de aceptación

### Escenario 1 - Entrada abstraída
- GIVEN la capa de aplicación
- WHEN invoca el caso de uso de registro
- THEN el caso de uso acepta texto como fuente actual
- AND permite extender a voz mediante una interfaz

### Escenario 2 - No regresión
- GIVEN que se agrega una fuente de voz futura
- WHEN se mantiene el flujo de texto
- THEN el comportamiento de registro por texto no se altera

## Casos borde
- Fuentes múltiples de entrada
- Conversión de voz a texto vacía

## Dependencias
- HU-001

## Trazabilidad técnica
- `lib/features/expenses/domain/usecases/record_text_expense.dart`
- `lib/features/expenses/domain/repositories/expense_repository.dart`

## Definición de listo
- Existe punto claro de extensión para STT sin acoplar la UI a una implementación concreta.
