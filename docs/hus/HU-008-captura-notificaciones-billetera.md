# HU-008 - Captura de notificaciones de billeteras digitales

## Historia
Como usuario,
quiero que MoneyAI detecte automáticamente los pagos realizados con Google Wallet y Google Pay a través de las notificaciones del sistema,
para tener mis transacciones listas para confirmar en una bandeja de pendientes sin digitarlas manualmente ni comprometer mi privacidad.

## Prioridad
Alta

## Criterios de aceptación

### Escenario 1 - Captura en segundo plano / app cerrada
- GIVEN que el usuario tiene activado el acceso a notificaciones para MoneyAI
- AND realiza un pago con Google Wallet
- WHEN el sistema Android emite la notificación de pago
- THEN el servicio nativo (`MoneyAiNotificationListener`) encola la notificación en una base local privada
- AND al abrir MoneyAI, la señal se procesa y aparece en la Bandeja de Billeteras con el monto, comercio y fecha detectados.

### Escenario 2 - Revisión y confirmación del movimiento
- GIVEN que hay una captura pendiente en la Bandeja de Billeteras
- WHEN el usuario presiona "Revisar"
- THEN se precarga el borrador en la pantalla de revisión (`ReviewInterpretationPage`) con la categoría sugerida
- AND al confirmar, el movimiento se guarda en la tabla `expenses` y la captura se marca como confirmada, eliminando el texto crudo por privacidad.

### Escenario 3 - Descarte de notificación
- GIVEN una captura en la Bandeja de Billeteras
- WHEN el usuario presiona "Descartar"
- THEN la captura se marca como descartada y se remueve de la lista de pendientes.

### Escenario 4 - Deduplicación de notificaciones
- GIVEN una notificación ya registrada o actualizada por el sistema
- WHEN Android vuelve a emitir la misma notificación dentro de la misma ventana de tiempo
- THEN no se genera un movimiento duplicado en la bandeja.

### Escenario 5 - Notificaciones no financieras ignoradas
- GIVEN una notificación de Google Wallet que no corresponde a una transacción (p. ej. tarjeta agregada, aviso de seguridad)
- WHEN el parser procesa la señal
- THEN no genera ningún movimiento pendiente y se limpia de la cola nativa.

## Casos borde
- Formatos numéricos variados (`S/ 12.50`, `S/.1,200.00`, `$15.99`, `25,50 €`).
- Reembolsos o devoluciones (se interpretan como tipo `income`).
- Android 13+ con ajustes restringidos para APKs no provenientes de Google Play (se ofrece guía contextual y botón para acceder a Información de la App).
- Plataformas sin soporte (iOS o escritorio): el servicio opera de forma segura sin excepciones.

## Dependencias
- HU-001 (Registro por texto)
- HU-002 (Listado persistente)
- HU-005 (Privacidad local-first)
- HU-006 (Estados de UI)

## Trazabilidad técnica
- `android/app/src/main/kotlin/com/github/diego22rct/moneyai/capture/`
  - `MoneyAiNotificationListener.kt`
  - `NotificationInboxStore.kt`
  - `NotificationCapturePlugin.kt`
  - `CapturePrefs.kt`
- `lib/features/wallet_capture/`
  - `data/parsers/google_wallet_parser.dart`
  - `data/parsers/money_amount_extractor.dart`
  - `data/datasources/wallet_capture_local_datasource.dart`
  - `data/repositories/wallet_capture_repository_impl.dart`
  - `presentation/pages/wallet_inbox_page.dart`
  - `presentation/widgets/notification_capture_settings_section.dart`
  - `presentation/widgets/capture_lifecycle_listener.dart`

## Definición de listo
- Detección nativa on-device operativa sin conexión a internet ni envío remoto de datos.
- Cobertura de pruebas unitarias para extracción de montos, parsers y repositorio de capturas.
- Integración en la shell principal con insignia de pendientes en el icono de notificaciones.
