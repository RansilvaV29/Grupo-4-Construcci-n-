# Aretis Deployment

Deployment dockerizado para la plataforma Aretis (Backend Django + Frontend Next.js + MariaDB).

## 🚀 Deployment rápido

Este repositorio permite deployar toda la aplicación Aretis desde cero usando solo Docker y Docker Compose.

### Pre-requisitos

- Docker >= 20.10
- Docker Compose >= 2.0
- Git

### Instrucciones

1. **Clonar este repositorio**

```bash
git clone https://github.com/TU_USUARIO/Grupo-4-Construccion.git
cd Grupo-4-Construccion
```

2. **Configurar variables de entorno**

Copia el archivo de ejemplo y edita con tus valores:

```bash
cp .env.example .env
nano .env  # o usa tu editor preferido
```

Variables críticas a configurar:

**Base de datos:**
- `DATABASE_PASSWORD`: Contraseña para el usuario de la base de datos
- `MARIADB_ROOT_PASSWORD`: Contraseña root de MariaDB
- `DATABASE_NAME`: Nombre de la base de datos (default: db_arte)
- `DATABASE_USER`: Usuario de la base de datos (default: artex_user)

**Django Backend:**
- `DJANGO_SECRET_KEY`: Secret key de Django (genera uno nuevo con: `python -c 'from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())'`)
- `FRONTEND_URL`: URL pública del frontend (ej: http://localhost:3000 o https://tu-dominio.com)
- `EMAIL_HOST_USER`: Email para SMTP
- `EMAIL_HOST_PASSWORD`: Password o App Password para SMTP
- `SENDGRID_API_KEY`: API Key de SendGrid (opcional)

**AWS S3 (Backend y Frontend):**
- `AWS_ACCESS_KEY_ID`: Credenciales de AWS S3
- `AWS_SECRET_ACCESS_KEY`: Credenciales de AWS S3
- `AWS_STORAGE_BUCKET_NAME`: Nombre del bucket S3
- `AWS_S3_CUSTOM_DOMAIN`: Dominio de CloudFront
- `NEXT_PUBLIC_AWS_S3_CUSTOM_DOMAIN`: Mismo dominio para el frontend
- `NEXT_PUBLIC_AX_STORAGE_URL`: URL pública del storage

**Next.js Frontend:**
- `NEXTAUTH_SECRET`: Secret para NextAuth (genera uno con: `openssl rand -base64 32`)
- `NEXTAUTH_URL`: URL pública del frontend
- `NEXT_PUBLIC_BACKEND_URL`: Ruta del backend (usa `/bapi` para Docker)

3. **Iniciar los servicios**

```bash
docker compose -f docker-compose.remote.yml up -d
```

Esto hará:
- ✅ Clonar automáticamente los repos desde GitHub:
  - Backend: https://github.com/Erickxse/dj_py_bck.git
  - Frontend: https://github.com/Erickxse/nx_js_ft.git
- ✅ Construir las imágenes Docker
- ✅ Iniciar MariaDB y cargar el dump.sql inicial (si existe en `initdb/`)
- ✅ Iniciar el backend Django (migraciones + collectstatic automáticas)
- ✅ Iniciar el frontend Next.js con rewrites hacia el backend

**Nota:** El primer build puede tardar 5-10 minutos dependiendo de tu conexión a internet y CPU.

4. **Verificar el estado**

```bash
docker compose -f docker-compose.remote.yml ps
docker compose -f docker-compose.remote.yml logs -f
```

5. **Acceder a la aplicación**

- Frontend: http://localhost:3000
- Backend API: http://localhost:8000
- Django Admin: http://localhost:8000/admin/

## 📁 Estructura del repositorio

```
Grupo-4-Construccion/
├── docker-compose.remote.yml   # Compose para build desde repos Git (GitHub)
├── docker-compose.yml           # Compose local (si tienes los repos clonados localmente)
├── .env.example                 # Template consolidado con TODAS las variables
├── .env                         # Variables de entorno (no versionado, créalo desde .env.example)
├── .gitignore                   # Ignora .env y archivos sensibles
├── initdb/
│   └── dump.sql                 # Dump inicial de la base de datos (opcional)
├── deploy.sh                    # Script de deployment automatizado (opcional)
└── README.md                    # Este archivo
```

**Importante:** Este repositorio NO contiene el código de backend ni frontend. 
Solo contiene la configuración de deployment que descarga automáticamente 
los repositorios desde:
- Backend: https://github.com/Erickxse/dj_py_bck.git
- Frontend: https://github.com/Erickxse/nx_js_ft.git

## 🔧 Comandos útiles

### Ver logs
```bash
# Todos los servicios
docker compose -f docker-compose.remote.yml logs -f

# Solo backend
docker compose -f docker-compose.remote.yml logs -f backend

# Solo frontend
docker compose -f docker-compose.remote.yml logs -f frontend
```

### Reiniciar servicios
```bash
docker compose -f docker-compose.remote.yml restart backend
docker compose -f docker-compose.remote.yml restart frontend
```

### Rebuild de imágenes (cuando hay cambios en los repos)
```bash
docker compose -f docker-compose.remote.yml build --no-cache
docker compose -f docker-compose.remote.yml up -d
```

### Detener todos los servicios
```bash
docker compose -f docker-compose.remote.yml down
```

### Limpiar todo (incluyendo volúmenes)
```bash
docker compose -f docker-compose.remote.yml down -v
```

## 🌐 Deployment en producción

### VPS / Servidor dedicado

1. SSH al servidor
2. Instalar Docker y Docker Compose
3. Clonar este repo
4. Configurar `.env` con valores de producción
5. Ejecutar `docker compose -f docker-compose.remote.yml up -d`

### Consideraciones de seguridad

- ❌ **NO** commits `.env` al repositorio
- ✅ Usa secretos o variables de entorno del servidor
- ✅ Configura un reverse proxy (nginx/Caddy) con SSL
- ✅ Cambia los puertos expuestos o usa solo red interna
- ✅ Implementa backups de la base de datos

### Reverse proxy con Nginx (ejemplo)

```nginx
server {
    listen 80;
    server_name aretis.example.com;

    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    location /bapi/ {
        proxy_pass http://localhost:8000/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

## 🗄️ Base de datos

### Backup

```bash
docker compose -f docker-compose.remote.yml exec db mysqldump -u root -p db_arte > backup_$(date +%Y%m%d).sql
```

### Restaurar

```bash
docker compose -f docker-compose.remote.yml exec -T db mysql -u root -p db_arte < backup.sql
```

## 🔄 Actualizar a última versión

```bash
# Rebuild desde los últimos commits en GitHub
docker compose -f docker-compose.remote.yml build --no-cache backend frontend
docker compose -f docker-compose.remote.yml up -d
```

## 🐛 Troubleshooting

### Error: backend unhealthy
Revisa los logs del backend:
```bash
docker compose -f docker-compose.remote.yml logs backend
```

Problemas comunes:
- Database no está lista → espera más tiempo o aumenta `start_period`
- Migraciones fallan → revisa credenciales de DB

### Error: frontend 401 en login
- Verifica que `NEXTAUTH_SECRET` esté configurado
- Revisa que backend esté accessible desde frontend

### Imágenes S3 no cargan (403 Forbidden)
- Configura el bucket S3 como público
- O implementa URLs firmadas

## 📝 Licencia

[Especifica tu licencia aquí]

## 🤝 Contribuir

[Instrucciones de contribución si aplica]
