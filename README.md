# Agendat-backend

Aquest és el repositori fronted en flutter del projecte **Agenda't**

Autors:
* Jordi Abelló --- jordi.abello.sunyer@estudiantat.upc.edu
* Àngela Buxó --- angela.buxo@estudiantat.upc.edu
* Noel Freire --- noel.freire@estudiantat.upc.edu
* Sergi Galan --- sergi.galan.soler@estudiantat.upc.edu
* Paula Mas --- paula.mas.pascual@estudiantat.upc.edu
* Pol Montanera --- pol.montanera@estudiantat.upc.edu
* Víctor Rocha --- victor.rocha@estudiantat.upc.edu

## 📋 Requisits Previs (Instal·lació de Flutter)

Abans de començar, assegura't de tenir instal·lat:

* **Flutter SDK**: [Guia d'instal·lació](https://docs.flutter.dev/get-started/install) (es recomana la versió estable més recent).

#### Instal·lació de **Python** (Necessari per a les eines de control)
Encara que estiguem programant en Dart/Flutter, utilitzem `pre-commit` per gestionar les revisions de codi. 

### ⚠️ IMPORTANT: Evita la Microsoft Store
**No instal·lis Python des de la botiga de Windows.** Dona problemes de rutes.

1. Baixa l'instal·lador oficial de **Python 3.12.10** des de [Python.org](https://www.python.org/downloads/).
2. **MOLT IMPORTANT:** Durant l'instal·lació, marca la casella **"Add Python 3.12 to PATH"**.
3. Un cop instal·lat, obre una terminal (PowerShell) i comprova que la ruta és la correcta:
   ```powershell
   where.exe python
* **Pre-commit**: El framework de hooks que ja fem servir al backend. Si no el tens:
    ```bash
    pip install pre-commit
    ```

--- 

## Configuració Inicial

Abans de començar a treballar, segueix aquests passos per tenir-ho tot a punt:

### 1. Clona el repositori
```bash
git clone [https://github.com/](https://github.com/)[EL-TEU-USUARI]/[NOM-DEL-REPO].git
cd [NOM-DEL-REPO]
```
### 2. Descarrega les dependències de Flutter

```bash
flutter pub get
```

### 3. Activa els "hooks" de qualitat

Això configurarà les revisions automàtiques que s'executaran abans de cada `git commit`:
```bash
pre-commit install
```

## 🛡️ Instal·lació de Pre-commit
Aquest repositori està configurat per passar tres filtres abans de permetre qualsevol commit:

1. **Flutter Format**: Revisa que el codi segueixi l'estil oficial de Dart (comes, espais i salts de línia).
2. **Flutter Analyze**: L'analitzador estàtic (l'equivalent a Pylint). Revisa errors de sintaxi, variables no utilitzades i bones pràctiques definides a analysis_options.yaml.
3. **Flutter Test**: Executa la suite de tests unitaris per assegurar que els nous canvis no trenquen funcionalitats ja existents.

## 📁 Estructura del Projecte
* `lib/`: Codi font de l'aplicació.

* `test/`: Tests unitaris i de widgets

* `analysis_options.yaml`: Configuració de les regles del linter (analitzador)

* `.pre-commit-config.yaml`: Configuració dels hooks automàtics

### 🔄 Com funciona el flux de treball?
A partir d'ara, el procés per fer canvis serà aquest:

1. Modifica el codi: Escriu les teves millores o correccions.

2. Prepara els fitxers: Fes git add . (o els fitxers que vulguis).

3. Fes el commit: Executa git commit -m "Descripció del que has fet".

**Què passarà en fer el commit?**
Automàticament, s'executaran les revisions configurades (neteja d'espais, format de codi, revisió de sintaxi, etc.):

* ✅ **Si tot està bé (Passed)**: El commit es crearà normalment.

* ❌ **Si es troben errors (Failed)**:

    * El sistema t'avisarà i aturarà el commit.

    * Si l'error era de format (com espais sobrants), el pre-commit els haurà arreglat per tu automàticament. Només hauràs de fer un altre git add . i tornar a intentar el commit.

    * Si l'error és de sintaxi, hauràs de corregir-lo manualment abans de poder fer el commit.
