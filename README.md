# ⚽ API Football

API REST construida con **FastAPI** para gestionar datos de fútbol jugadores de futbol(edad, posicion, dorsal), desplegada en **AWS EC2** usando infraestructura como código con **Terraform (OpenTofu)**, base de datos **MongoDB**, balanceador de carga y configuración centralizada con **AWS Parameter Store**.

---

## 📋 Tabla de contenidos

- [Descripción](#-descripción)
- [Tecnologías](#-tecnologías)
- [Arquitectura](#-arquitectura)
- [Requisitos previos](#-requisitos-previos)
- [Instalación local](#-instalación-local)
- [Ejecución con Docker](#-ejecución-con-docker)
- [Pruebas unitarias](#-pruebas-unitarias)
- [Chequeo de código estático](#-chequeo-de-código-estático)
- [Despliegue en AWS EC2 con Terraform](#-despliegue-en-aws-ec2-con-terraform)
- [Swagger / Documentación de la API](#-swagger--documentación-de-la-api)
- [Endpoints principales](#-endpoints-principales)

---

## 📖 Descripción

**API Football** es una API REST desarrollada como proyecto del curso de **Computación en la Nube**. Permite consultar y gestionar información acerca de jugadores de futbol tales como
nombre, edad, posicion, dorsal.

La infraestructura está completamente automatizada con **Terraform (OpenTofu)**:
- Cada servicio corre en su propia instancia **EC2**
- Las IPs de los servicios se obtienen dinámicamente desde **AWS Parameter Store**
- Un **Application Load Balancer (ALB)** distribuye el tráfico entre al menos dos instancias de la API

---

## 🛠 Tecnologías

| Tecnología | Uso |
|---|---|
| **FastAPI** | Framework principal de la API |
| **Python 3.12** | Lenguaje de programación |
| **MongoDB** | Base de datos NoSQL |
| **Docker / Docker Compose** | Contenedores |
| **Terraform (OpenTofu)** | Infraestructura como código |
| **AWS EC2** | Cómputo en la nube |
| **AWS Parameter Store** | Configuración centralizada de IPs |
| **AWS ALB** | Balanceador de carga |
| **pytest** | Pruebas unitarias |
| **ruff** | Linter / chequeo de código estático |

---

## 🏗 Arquitectura

```
Internet
    │
    ▼
[Application Load Balancer]
    │              │
    ▼              ▼
[EC2 - API 1]  [EC2 - API 2]   ← FastAPI + Docker
    │              │
    └──────┬───────┘
           ▼
    [EC2 - MongoDB]
           │
           ▼
  [AWS Parameter Store]
  (almacena IPs de servicios)
```

- El ALB recibe el tráfico y lo distribuye entre dos instancias de la API.
- Cada instancia de la API obtiene la IP de MongoDB desde **AWS Parameter Store** al arrancar.
- La base de datos corre en su propia instancia EC2 separada.

---

## ✅ Requisitos previos

- Python 3.12+
- Docker y Docker Compose
- OpenTofu (Terraform) instalado
- Cuenta de AWS con credenciales configuradas (`aws configure`)
- `uv` (gestor de paquetes, opcional)

---

## 💻 Instalación local

```bash
# Clonar el repositorio
git clone https://github.com/AlejandroSnap/API-FOOTBALL.git
cd API-FOOTBALL

# Crear entorno virtual e instalar dependencias
python -m venv .venv
source .venv/bin/activate        # Linux/Mac
# .venv\Scripts\activate         # Windows

pip install -r requirements.txt
```

Configurar variables de entorno copiando el archivo `.env`:

```bash
cp .env .env.local
# Editar .env.local con tus valores locales
```

Variables principales del `.env`:

```env
MONGO_URI=mongodb://localhost:27017
DB_NAME=football
```

Iniciar la API localmente:

```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Acceder a: `http://localhost:8000/docs`

---

## 🐳 Ejecución con Docker

### Desarrollo local

```bash
docker compose up --build
```

Esto levanta:
- La API en `http://localhost:8000`
- MongoDB en el puerto `27017`

Para detener:

```bash
docker compose down
```

---

## 🧪 Pruebas unitarias

Las pruebas están escritas con **pytest** y cubren los endpoints y funciones principales de la API.

```bash
# Instalar dependencias de prueba (si no están instaladas)
pip install -r requirements.txt

# Correr todas las pruebas
pytest

# Con verbose
pytest -v

# Ver cobertura
pytest --cov=app
```

---

## 🔍 Chequeo de código estático

Se usa **ruff** como linter para revisar errores, malas prácticas y estilo de código.

```bash
# Verificar el código
ruff check .

# Corregir automáticamente
ruff check . --fix
```

La configuración de ruff se encuentra en `pyproject.toml`.

---

## ☁️ Despliegue en AWS EC2 con Terraform

La infraestructura completa se crea con **OpenTofu (Terraform)**.

### 1. Configurar credenciales AWS

```bash
aws configure
# Ingresar: Access Key, Secret Key, Region (us-east-1), formato (json)
```

### 2. Inicializar Terraform

```bash
cd terraform
tofu init
```

### 3. Revisar el plan de infraestructura

```bash
tofu plan
```

### 4. Aplicar la infraestructura

```bash
tofu apply
```

Esto crea automáticamente:
- 2 instancias EC2 para la API
- 1 instancia EC2 para MongoDB
- 1 Application Load Balancer
- Security Groups con los puertos necesarios abiertos (8000, 27017)
- Parámetros en AWS Parameter Store con las IPs de cada servicio

### 5. Acceder a la API

Después del despliegue, Terraform mostrará la **DNS del Load Balancer**. Acceder a:

```
http://<DNS_DEL_ALB>/docs
```

### 6. Destruir la infraestructura (cuando no se necesite)

```bash
tofu destroy
```

---

### Parameter Store

El código de la API lee la IP de MongoDB directamente desde AWS Parameter Store:

```python
# Ejemplo de cómo se obtiene la IP
import boto3

ssm = boto3.client('ssm', region_name='us-east-1')
mongo_ip = ssm.get_parameter(Name='/football/mongo_ip')['Parameter']['Value']
```

Los parámetros que se crean son:
- `/football/mongo_ip` — IP privada de la instancia MongoDB
- `/football/api_ip_1` — IP de la primera instancia API
- `/football/api_ip_2` — IP de la segunda instancia API

---

## 📚 Swagger / Documentación de la API

FastAPI genera automáticamente la documentación interactiva.

| Entorno | URL |
|---|---|
| Local | `http://localhost:8000/docs` |
| EC2 (via ALB) | `http://<DNS_DEL_ALB>/docs` |
| Alternativa (ReDoc) | `http://localhost:8000/redoc` |

---

## 🔗 Endpoints principales

| Método | Ruta | Descripción |
|---|---|---|
| `GET` | `/` | Health check |
| `GET` | `/equipos` | Listar todos los equipos |
| `POST` | `/equipos` | Crear un equipo |
| `GET` | `/equipos/{id}` | Obtener un equipo por ID |
| `PUT` | `/equipos/{id}` | Actualizar un equipo |
| `DELETE` | `/equipos/{id}` | Eliminar un equipo |
| `GET` | `/jugadores` | Listar jugadores |
| `POST` | `/jugadores` | Crear un jugador |
| `GET` | `/partidos` | Listar partidos |
| `POST` | `/partidos` | Registrar un partido |

La documentación completa e interactiva está disponible en `/docs` (Swagger UI).

---

## 👤 Autor

**AlejandroSnap**  
Proyecto final — Curso de Computación en la Nube
