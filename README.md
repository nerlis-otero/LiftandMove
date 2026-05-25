# Lift&Move

Sistema de Información para la Gestión y Seguimiento de Rutinas de Entrenamiento Físico.

Aplicación móvil desarrollada con Flutter y FastAPI que permite a usuarios de gimnasio registrar, organizar y hacer seguimiento personalizado de sus rutinas de entrenamiento, adaptadas a sus metas y perfil individual.

---

## Equipo

| Nombre | Rol |
|---|---|
| Nerlis Otero Pérez | Desarrollo frontend y backend |
| Isabel Páez Matallana | Desarrollo frontend y backend |
| Susana Rosales Castellar | Desarrollo frontend y backend |
| Carlos Manrique Fals | Desarrollo frontend y backend |

**Materia:** Desarrollo de Software  
**Docente:** Marco Antonio Almanza Ibarra  
**Programa:** Ingeniería de Sistemas  
**Universidad:** Universidad Tecnológica de Bolívar

---

## Tecnologías

**Frontend**
- Flutter (Dart)
- table_calendar
- flutter_secure_storage
- http
- flutter_svg

**Backend**
- FastAPI (Python)
- PyMySQL
- JWT (python-jose)
- Uvicorn

**Base de Datos**
- MySQL

**Catálogo de ejercicios**
- [free-exercise-db](https://github.com/yuhonas/free-exercise-db)

---

## Arquitectura

```
Flutter (frontend)
      |
      | HTTP / REST API / JSON
      |
FastAPI (backend)
      |
      | SQL Queries
      |
MySQL (base de datos)
```

---

## Funcionalidades

- Registro de usuario con encuesta inicial (sexo, edad, peso, estatura, objetivo)
- Autenticación con JWT
- Gestión de rutinas con nombre, días de la semana y período de vigencia
- Catálogo de ejercicios con búsqueda por nombre y clasificación por grupo muscular
- Registro de sets, repeticiones y peso por ejercicio
- Calendario interactivo con rutinas asignadas por fecha
- Marcado de rutina como completada
- Estadísticas y metas personalizadas según objetivo del usuario
- Perfil de usuario
- Panel de administración

---

## Módulo de Estadísticas

El sistema adapta el seguimiento al objetivo elegido por el usuario:

| Objetivo | Métrica |
|---|---|
| Perder peso | Peso actual vs peso objetivo |
| Ganar músculo | Series semanales vs meta |
| Ganar fuerza | Peso máximo levantado vs meta |
| Ser más flexible | Días completados en la semana vs meta |

---

## Estructura del Repositorio

```
LiftandMove/
├── front/                  # Aplicación Flutter
│   └── lib/
│       ├── core/           # Configuración, tema, servicios
│       └── screens/        # Pantallas de la app
├── back/                   # Backend FastAPI
│   └── main.py             # Endpoints y lógica de negocio
├── PASOS_PARA_CORRER_LA_APP
└── README.md
```

---

## Instalación y Ejecución

### Requisitos previos

- Flutter SDK 3.x
- Python 3.10+
- MySQL 8.x

### Backend

```bash
cd back
pip install fastapi uvicorn pymysql python-jose passlib python-multipart
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

### Frontend

```bash
cd front
flutter pub get
flutter run
```

Asegúrate de actualizar la URL del backend en:

```
front/lib/core/api_config.dart
```

```dart
class ApiConfig {
  static const String baseUrl = 'http://TU_IP:8000';
}
```

---

## Base de Datos

Las tablas principales del sistema son:

```
usuarios
rutina_plantilla
rutina_dias
rutina_ejercicio
rutina_completada
ejercicios
registro_peso
```

El script SQL de creación de tablas se encuentra en el archivo `PASOS_PARA_CORRER_LA_APP` del repositorio.

---

## Requisitos Funcionales Implementados

| ID | Descripción |
|---|---|
| RF-001 | Registro de usuario con datos personales |
| RF-002 | Registro de entrenamientos con fecha |
| RF-003 | Registro de ejercicio por sesión |
| RF-004 | Sets y repeticiones por ejercicio |
| RF-005 | Peso utilizado por ejercicio |
| RF-007 | Cálculo automático de IMC |
| RF-008 | Consulta de historial de entrenamientos |
| RF-009 | Selección de objetivo de entrenamiento |
| RF-010 | Definición de peso y medidas meta |

---

## Licencia

Proyecto académico desarrollado para la materia Desarrollo de Software.  
Universidad Tecnológica de Bolívar, Cartagena de Indias, Colombia, 2026.
