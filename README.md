<div align="center">
  <img src="https://s3.eu-south-2.amazonaws.com/agendat.s3/logoAgendatNoFondo.png" alt="Logo d'Agenda't" width="140">
  <h1>Agenda't Frontend</h1>
  <p>
    App Flutter d'Agenda't per descobrir esdeveniments culturals, gestionar l'agenda personal,
    parlar amb amics i publicar ressenyes.
  </p>
  <p>
    <a href="/Users/polmontanera/Desktop/Q6%202526/PES/Agendat-backend/README.md">Explora la documentació</a>
  </p>
  <p>
    <a href="http://nattech.fib.upc.edu:40410/">Backend de producció</a>
    ·
    <a href="assets/icons/logoAgendat.png">Logo</a>
    ·
    <a href="/Users/polmontanera/Desktop/Q6%202526/PES/Agendat-backend/README.md">README del backend</a>
  </p>
</div>


## Què Inclou L'App

- Feed d'esdeveniments amb cerca i filtres
- Vista de mapa amb marcadors d'esdeveniments i accessos a navegació
- Agenda personal amb vista de calendari i de llista
- Sol·licituds d'amistat, recomanacions, visites de perfil i bloquejos
- Xat en temps real
- Invitacions a esdeveniments
- Ressenyes amb likes, traduccions i multimèdia
- Configuració de notificacions i idioma
- Sincronització opcional amb Google Calendar

## Idiomes Suportats

- Català
- Castellà
- Anglès

## Requisits

- Flutter SDK `>=3.11.0 <4.0.0`
- Backend d'Agenda't en execució

Instal·la les dependències:

```bash
flutter pub get
```

## Connexió Amb El Backend

Hi ha dos backends disponibles:

En local:
- `localhost:8080/#/` - Usat per a desenvolupament.



Al Virtech:
- `http://nattech.fib.upc.edu:40410/` - Usat a producció


Per defecte, es fa servir el backend en local. Per executar l'app en local fent servir el backend de producció, executa `flutter run` amb els flags:

```bash
--dart-define=API_BASE_URL=http://nattech.fib.upc.edu:40410/ --web-port=5555
```
`--web-port=5555`és opcional, només si es volen fer servir els serveis de Google (Google Sign In & Google Calendar.)

## Guia Detallada D'Execució

### 1. Arrenca primer el backend

Des del repositori del backend:

```bash
docker compose up --build -d
```

Comprova que Swagger s'obre a:

```text
http://localhost:8080/
```

### 2. Instal·la les dependències del frontend

```bash
flutter pub get
```

### 3. Executa l'app

#### Web

```bash
flutter run -d chrome --web-port=5555
```


#### Dispositiu Android físic amb `adb reverse` (per les notificacions)

Comanda directa:
```powershell
.\scripts\run_android_docker.ps1 -DeviceId <device-id>
```

Exemple fent servir el backend desplegat:

```bash
flutter run -d chrome --dart-define=API_BASE_URL=http://nattech.fib.upc.edu:40410
```


## Estructura Del Projecte

- `lib/features/auth`: login, registre, recuperació de contrasenya i onboarding
- `lib/features/events`: detall d'esdeveniment, assistència i invitacions
- `lib/features/map`: pantalla de mapa, filtres i previsualitzacions de marcadors
- `lib/features/agenda`: agenda i vistes de calendari
- `lib/features/social`: recomanacions, sol·licituds, cerca d'usuaris i amics
- `lib/features/chat`: missatgeria en temps real
- `lib/features/profile`: perfil, usuaris bloquejats, configuració i interessos
- `lib/features/reviews`: creació i interacció amb ressenyes

## Contribucions

Si vols contribuir al frontend, treballa sempre sobre una branca nova i intenta que cada canvi tingui un abast clar.

Flux recomanat:

1. Fes pull de la branca `develop`.
2. Crea una branca descriptiva per a la funcionalitat o correcció.
3. Executa `flutter pub get` i valida que el projecte continua compilant.
4. Obre una pull request amb una explicació breu i concreta.

Abans d'enviar una contribució, assegura't que:

- no s'han introduït URLs, claus o credencials sensibles
- s'han revisat els canvis amb dispositius de diferents mides 