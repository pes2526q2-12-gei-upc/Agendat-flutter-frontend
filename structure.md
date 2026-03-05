# agenda't - FrontEnd (flutter)

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Estructura del Projecte

```bash
lib/
│
├── main.dart
├── app.dart
│
├── core/
│   ├── theme/
│   ├── constants/
│   ├── utils/
│   └── widgets/
│
├── shared/
│   ├── models/
│   ├── services/
│   └── repositories/
│
├── features/
│   ├── auth/
│   ├── events/
│   ├── map/
│   ├── agenda/
│   ├── reviews/
│   ├── chat/
│   └── profile/
│
└── routing/
    └── app_router.dart
```

## Fitxers principals

### main.dart

Punt d’entrada de l’aplicació.

Responsabilitat:
	•	Inicialitzar l’app
	•	Cridar runApp()

⸻

### app.dart

Configuració global de l’aplicació.

Responsabilitats:
	•	Configurar MaterialApp
	•	Definir el theme
	•	Inicialitzar el router
	•	Configurar gestió d’estat global (si escau)

Aquí es defineix la configuració principal del sistema.

⸻

### Carpeta core/

Conté codi global reutilitzable a tota l’aplicació. No ha de dependre de cap feature concreta.

### core/theme/

Gestió del disseny visual:
	•	colors.dart
	•	text_styles.dart
	•	theme.dart

Defineix:
	•	Colors corporatius
	•	Estils de text
	•	Configuració global del tema

⸻

### core/constants/

Constants globals:
	•	URLs base del backend
	•	Claus de configuració
	•	Strings estàtiques

⸻

### core/utils/

Funcions utilitàries reutilitzables:
	•	Formatadors de data
	•	Validators
	•	Helpers genèrics

⸻

### core/widgets/

Widgets reutilitzables comuns a tota l’app:

Exemples:
	•	CustomButton
	•	LoadingIndicator
	•	ErrorView
	•	CustomTextField

Objectiu: Evitar duplicació de codi UI.

⸻

### Carpeta shared/

Conté elements compartits entre diferents features.

### shared/models/

Models de dades generals que poden ser utilitzats per múltiples funcionalitats.

Exemple:
	•	User
	•	Event (si és transversal)

⸻

### shared/services/

Serveis globals:
	•	HTTP client base
	•	Gestió d’autenticació
	•	Interceptors

⸻

### shared/repositories/

Repositoris compartits entre features.

Responsabilitat:
	•	Abstracció d’accés a dades
	•	Comunicació amb backend
	•	Transformació JSON → Model

⸻

### Carpeta features/

Conté totes les funcionalitats principals de l’aplicació.

Cada funcionalitat és independent i encapsulada.

Això permet:
	•	Treballar en paral·lel
	•	Evitar dependències circulars
	•	Escalar el projecte

⸻

### Estructura interna d’una Feature

Exemple (features/events/):

```bash
events/
│
├── data/
│   ├── event_model.dart
│   ├── events_repository.dart
│
├── presentation/
│   ├── screens/
│   ├── widgets/
│   └── providers/
```

### data/

Conté:
	•	Models específics
	•	Repositoris propis de la feature
	•	Fonts de dades

Responsabilitat:
Gestió de dades i comunicació amb backend.

⸻

### presentation/

Conté la part visual.

### screens/
Pantalles completes (pages).

Exemple:
	•	events_list_screen.dart
	•	event_detail_screen.dart

### widgets/
Widgets específics d’aquesta feature.

### providers/
Gestió d’estat (Riverpod / Provider / Bloc).

Responsabilitat:
	•	Control de lògica UI
	•	Estat reactiu
	•	Comunicació amb repository

### Carpeta routing/

Conté la configuració de navegació.

### app_router.dart

Responsabilitats:
	•	Definir rutes
	•	Controlar navegació
	•	Centralitzar la configuració de pantalles

Això evita definir rutes disperses pel projecte.