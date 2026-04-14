# ⚽ API Football

API REST construida con **FastAPI** para consultar y gestionar información de jugadores de fútbol. Las escrituras son procesadas de forma **asíncrona** mediante **RabbitMQ** y un worker dedicado. La infraestructura completa está automatizada con **Terraform (OpenTofu)** sobre **AWS**, con balanceador de carga y configuración centralizada en **Parameter Store**.

---

## 📋 Tabla de contenidos

- [Descripción](#-descripción)
- [Tecnologías](#-tecnologías)
- [Arquitectura](#-arquitectura)
- [Estructura del proyecto](#-estructura-del-proyecto)
- [Requisitos previos](#-requisitos-previos)
- [Variables de entorno](#-variables-de-entorno)
- [Instalación local](#-instalación-local)
- [Ejecución con Docker](#-ejecución-con-docker)
- [Pruebas unitarias](#-pruebas-unitarias)
- [Chequeo de código estático](#-chequeo-de-código-estático)
- [Despliegue en AWS con Terraform](#-despliegue-en-aws-con-terraform)
- [Swagger / Documentación de la API](#-swagger--documentación-de-la-api)
- [Endpoints](#-endpoints)
- [Modelo de datos](#-modelo-de-datos)

---

## 📖 Descripción

**API Football** es una API REST desarrollada como proyecto del curso de **Computación en la Nube**. Permite consultar y gestionar información de jugadores de fútbol: nombre, equipo, posición, goles en carrera y número de camiseta.

Las operaciones de escritura (crear y eliminar jugadores) se procesan de forma **asíncrona**: la API publica un mensaje en una cola de **RabbitMQ** y un **worker** independiente lo consume y ejecuta la operación en **MongoDB**.

La infraestructura está completamente automatizada con **Terraform (OpenTofu)**:
- Cada servicio corre en su propia instancia **EC2**
- Las IPs de MongoDB y RabbitMQ se almacenan y leen desde **AWS Parameter Store**
- Un **Application Load Balancer** distribuye el tráfico entre dos instancias de la API

---

## 🛠 Tecnologías

| Tecnología | Uso |
|---|---|
| **FastAPI** | Framework principal de la API |
| **Python 3.12** | Lenguaje de programación |
| **MongoDB** | Base de datos NoSQL |
| **RabbitMQ** | Cola de mensajes para operaciones asíncronas |
| **Pika** | Cliente Python para RabbitMQ |
| **Docker / Docker Compose** | Contenedores |
| **Terraform (OpenTofu)** | Infraestructura como código |
| **AWS EC2** | Cómputo en la nube |
| **AWS Parameter Store (SSM)** | Almacenamiento de IPs de servicios |
| **AWS ALB** | Balanceador de carga |
| **pytest** | Pruebas unitarias |
| **ruff** | Linter / chequeo de código estático |

---

## 🏗 Arquitectura

```
Internet
    │
    ▼ (puerto 80)
[Application Load Balancer]
    │                   │
    ▼                   ▼
[EC2: API 1]       [EC2: API 2]        ← FastAPI (puerto 8000)
    │                   │
    └────────┬──────────┘
             │ publica mensajes
             ▼
    [EC2: RabbitMQ]                    ← Message Broker (puerto 5672)
             │
             ▼ consume mensajes
    [EC2: Worker]                      ← Procesa create / delete
             │
             ▼
    [EC2: MongoDB]                     ← Base de datos (puerto 27017)

             ▲
             │ lee IPs al iniciar
    [AWS Parameter Store]
      /football/mongo_ip
      /football/rabbitmq_ip
```

**Flujo de una operación de escritura:**
1. El cliente hace `POST /players` o `DELETE /players/{id}` a la API (vía ALB)
2. La API publica un mensaje en la cola `player_tasks` de RabbitMQ
3. El worker consume el mensaje y ejecuta la operación en MongoDB

**Flujo de una operación de lectura:**
1. El cliente hace `GET /players` o `GET /players/{id}`
2. La API consulta directamente MongoDB y devuelve la respuesta

---

## 📁 Estructura del proyecto

```
API-FOOTBALL/
├── app/
│   ├── database/           # Conexión a MongoDB
│   ├── routes/
│   │   └── player_routes.py
│   ├── schemas/
│   │   └── player_schema.py
│   ├── services/
│   │   └── player_service.py
│   ├── main.py
│   ├── rabbitmq.py         # Publicador de mensajes
│   └── worker.py           # Consumidor de la cola
├── terraform/
│   ├── main.tf             # EC2, ALB, Parameter Store, Security Groups
│   ├── variables.tf
│   ├── outputs.tf
│   └── scripts/
│       ├── api.sh
│       ├── rabbitmq.sh
│       ├── worker.sh
│       └── mongo.sh
├── .env
├── Dockerfile
├── Dockerfile.local
├── docker-compose.yml
├── requirements.txt
├── pyproject.toml
└── README.md
```

---

## ✅ Requisitos previos

- Python 3.12+
- Docker y Docker Compose
- Cuenta de AWS con credenciales configuradas (`aws configure`)

---

## 🔧 Variables de entorno

Crear un archivo `.env` en la raíz del proyecto con las siguientes variables:

```env
MONGO_URI=mongodb://user:admin@localhost:27017/?authSource=admin

RABBITMQ_HOST=rabbitmq
RABBITMQ_USER=user
RABBITMQ_PASSWORD=admin
RABBITMQ_PORT=5672
RABBITMQ_QUEUE=player_tasks
```

> En el despliegue en EC2, los valores de `MONGO_URI` y `RABBITMQ_HOST` se construyen dinámicamente leyendo las IPs desde **AWS Parameter Store** (`/football/mongo_ip` y `/football/rabbitmq_ip`).

---

## 💻 Instalación local

```bash
# Clonar el repositorio
git clone https://github.com/AlejandroSnap/API-FOOTBALL.git
cd API-FOOTBALL

# Crear entorno virtual
python -m venv .venv
source .venv/bin/activate       # Linux/Mac
# .venv\Scripts\activate        # Windows

# Instalar dependencias
pip install -r requirements.txt
```

Iniciar la API:

```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Iniciar el worker (en otra terminal):

```bash
python -m app.worker
```

Acceder a: `http://localhost:8000/docs`

---

## 🐳 Ejecución con Docker

```bash
docker compose up --build
```

Esto levanta todos los servicios:
- API en `http://localhost:8000`
- RabbitMQ en puerto `5672` / panel web en `http://localhost:15672`
- MongoDB en puerto `27017`
- Worker procesando la cola en background

Para detener:

```bash
docker compose down
```

---

## 🧪 Pruebas unitarias

Las pruebas están escritas con **pytest**.

```bash
# Correr todas las pruebas
pytest

# Con detalle
pytest -v

# Con reporte de cobertura
pytest --cov=app
```

---

## 🔍 Chequeo de código estático

Se usa **ruff** como linter.

```bash
# Verificar el código
ruff check .

# Corregir automáticamente lo que sea posible
ruff check . --fix
```

La configuración se encuentra en `pyproject.toml`.

---

## ☁️ Despliegue en AWS con Terraform

La infraestructura crea **5 instancias EC2** y un **Application Load Balancer**.

### 1. Configurar credenciales AWS

```bash
aws configure
```

### 2. Inicializar OpenTofu

```bash
cd terraform
terraform init
```

### 3. Revisar el plan

```bash
terraform plan
```

### 4. Aplicar la infraestructura

```bash
terraform apply
```

Recursos que se crean automáticamente:

| Recurso | Nombre | Descripción |
|---|---|---|
| EC2 | `football-api-1` | Primera instancia de la API |
| EC2 | `football-api-2` | Segunda instancia de la API |
| EC2 | `rabbitmq-server` | Broker de mensajes |
| EC2 | `worker-server` | Consumidor de la cola |
| EC2 | `mongodb-server` | Base de datos |
| EIP | `rabbitmq-static-ip` | IP estática para RabbitMQ |
| EIP | `mongodb-static-ip` | IP estática para MongoDB |
| SSM | `/football/rabbitmq_ip` | IP de RabbitMQ en Parameter Store |
| SSM | `/football/mongo_ip` | IP de MongoDB en Parameter Store |
| ALB | `football-lb-api` | Balanceador de carga (puerto 80) |
| Target Group | `football-api-tg` | Apunta a las 2 APIs en puerto 8000 |

El ALB hace health check en `/health` de cada instancia antes de enviarle tráfico.

### 5. Acceder a la API

Después del `tofu apply`, usar la DNS del Load Balancer:

```
http://<DNS_DEL_ALB>/docs
```

### 6. Destruir la infraestructura

```bash
tofu destroy
```

---

## 📚 Swagger / Documentación de la API

FastAPI genera automáticamente la documentación interactiva.

| Entorno | URL |
|---|---|
| Local | `http://localhost:8000/docs` |
| EC2 (vía ALB) | `http://<DNS_DEL_ALB>/docs` |
| ReDoc (alternativa) | `http://localhost:8000/redoc` |

---

## 🔗 Endpoints

| Método | Ruta | Descripción |
|---|---|---|
| `GET` | `/health` | Health check del servidor |
| `GET` | `/players` | Listar todos los jugadores |
| `GET` | `/players/{id}` | Obtener un jugador por ID |
| `POST` | `/players` | Crear un jugador (asíncrono vía RabbitMQ) |
| `PATCH` | `/players/{id}` | Actualizar parcialmente un jugador |
| `DELETE` | `/players/{id}` | Eliminar un jugador (asíncrono vía RabbitMQ) |

---

## 📐 Modelo de datos

### Player

```json
{
  "id": 10,
  "name": "Lionel Messi",
  "team_id": 3,
  "career_goals": 819,
  "jersey_number": 10,
  "position": "FWD"
}
```

| Campo | Tipo | Descripción |
|---|---|---|
| `id` | `int` | Identificador del jugador |
| `name` | `str` | Nombre completo |
| `team_id` | `int` | ID del equipo al que pertenece |
| `career_goals` | `int` | Goles acumulados en su carrera |
| `jersey_number` | `int` | Número de camiseta |
| `position` | `enum` | Posición: `GK`, `DEF`, `MID`, `FWD` |

### PlayerUpdate (PATCH)

Todos los campos son opcionales:

```json
{
  "name": "Lionel Messi",
  "team_id": 5,
  "career_goals": 820,
  "jersey_number": 10,
  "position": "FWD"
}
```

---

## 👤 Autores

* Alejandro Casas
* Miguel Rodriguez
— Curso de Computación en la Nube
