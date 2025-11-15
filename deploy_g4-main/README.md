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
git clone https://github.com/USUARIO/aretis-deploy.git
cd aretis-deploy
```

2. **Configurar variables de entorno**

Copia el archivo de ejemplo y edita con tus valores:

```bash
cp .env.example .env
nano .env  # o usa tu editor preferido
```

Variables críticas a configurar:
- `DATABASE_PASSWORD`: Contraseña para la base de datos
- `MARIADB_ROOT_PASSWORD`: Contraseña root de MariaDB
- `DJANGO_SECRET_KEY`: Secret key de Django (genera uno nuevo)
- `NEXTAUTH_SECRET`: Secret para NextAuth (genera uno nuevo)
- `AWS_ACCESS_KEY_ID`: Credenciales de AWS S3
- `AWS_SECRET_ACCESS_KEY`: Credenciales de AWS S3

3. **Iniciar los servicios**

```bash
docker compose -f docker-compose.remote.yml up -d
```

Esto hará:
- ✅ Clonar automáticamente los repos de frontend y backend desde GitHub
- ✅ Construir las imágenes Docker
- ✅ Iniciar MariaDB y cargar el dump.sql inicial
- ✅ Iniciar el backend Django (migraciones + collectstatic)
- ✅ Iniciar el frontend Next.js

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
aretis-deploy/
├── docker-compose.remote.yml   # Compose para build desde repos Git
├── docker-compose.yml           # Compose local (opcional)
├── .env.example                 # Template de variables de entorno
├── .env                         # Variables de entorno (no versionado)
├── initdb/
│   └── dump.sql                 # Dump inicial de la base de datos
└── README.md                    # Este archivo
```

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
