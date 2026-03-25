# AGENTS.md - MoneyAI

Este archivo define las reglas operativas para cualquier agente que trabaje en este repositorio.

## 1) Misión del proyecto

MoneyAI es una app móvil Flutter de finanzas personales con enfoque local-first.
Objetivo: registrar gastos en lenguaje natural, priorizando privacidad total.

Regla principal:
- Ningún dato financiero personal sale del dispositivo.
- El procesamiento de voz y entendimiento de contexto ocurre localmente.

## 2) Regla obligatoria de Skills

Antes de responder o ejecutar cambios:

1. Revisar las skills disponibles para la tarea.
2. Si una skill aplica, cargar su `SKILL.md` como primera acción.
3. No continuar sin haber leido la skill relevante.
4. Si aplican varias skills, cargar todas antes de implementar.
5. No mencionar una skill en la respuesta si no fue cargada.

Skills comunes para este repo:
- `flutter-architecting-apps`
- `flutter-managing-state`
- `flutter-working-with-databases`
- `flutter-building-layouts`
- `flutter-theming-apps`
- `flutter-animating-apps`
- `flutter-handling-concurrency`

## 3) Arquitectura de agentes

### MoneyAI-STT (Transcriptor)
- Modelo: Whisper-tiny (mobile optimized).
- Funcion: audio -> texto crudo.
- Idioma objetivo: espanol con modismos regionales.

### MoneyAI-NLU (Contexto)
- Modelo: Llama 3.2 1B o Qwen 2.5 1.5B (cuantizado).
- Funcion: extraer estructura financiera desde texto.
- Debe producir JSON con:
  - `amount`
  - `currency`
  - `description`
  - `category`
  - `timestamp`

### MoneyAI-Engine (Orquestador)
- Gestiona UI Flutter.
- Coordina estados de IA.
- Persiste datos en SQLite.
- Activa feedback visual y animaciones.

## 4) Stack tecnico base

- Framework: Flutter
- STT: `whisper_flutter`
- LLM local: `llama_cpp_dart`
- Persistencia: `sqflite`
- Estado: Riverpod o Bloc

## 5) Flujo de procesamiento

Entrada ejemplo:
- "Gaste 60 soles en ropa en el centro"

Pipeline:
1. Captura de micro-audio en Flutter.
2. STT transcribe a texto.
3. NLU aplica prompt de extraccion.
4. Se valida JSON de salida.
5. Registro inmediato en tabla `expenses`.

Prompt de sistema recomendado:

"Eres MoneyAI. Extrae monto, moneda, descripcion y categoria del texto. Categorias: [Comida, Transporte, Ropa, Salud, Entretenimiento, Hogar, Otros]. Responde solo JSON."

Ejemplo de salida:

```json
{
  "amount": 60,
  "currency": "PEN",
  "description": "Ropa en el centro",
  "category": "Ropa",
  "timestamp": "2026-03-24T21:48:00Z"
}
```

## 6) Convenciones de implementacion

- Priorizar cambios pequenos y verificables.
- Mantener compatibilidad con Android primero.
- Si hay duda de arquitectura, usar skill de arquitectura antes de codificar.
- Si hay cambios de UI, usar skills de layout/theming/animaciones.
- Si hay persistencia, usar skill de base de datos.
- Si hay trabajo pesado (parsing, inferencia, post-proceso), evaluar isolates.

## 7) Roadmap funcional

1. Branding (logo + paleta neon purpura/verde financiero).
2. Integracion de modelos locales (`.bin` / `.gguf`) en assets.
3. Modulo de voz con feedback visual (AvatarGlow o equivalente).
4. Refinamiento del prompt con correcciones del usuario.
5. Dashboard por categorias de gasto.

## 8) Prompts de identidad visual

- Logo:
  - "Minimalist logo for 'MoneyAI' app, abstract brain shape combined with a coin/currency symbol, futuristic neon colors, white background, high resolution vector style."
- UI:
  - "Modern mobile UI for MoneyAI expense tracker, showing a sleek dark theme with a glowing purple microphone button, clean transaction cards with category icons, glassmorphism design, Flutter Material 3."

## 9) Definicion de exito

Un cambio se considera correcto cuando:
- Respeta privacidad local-first.
- Sigue la regla obligatoria de skills.
- Mantiene salida JSON estable para gastos.
- Persiste correctamente en SQLite.
- No rompe la experiencia principal de captura por voz.