# 🚀 Guía Rápida de Deployment

Esta guía te ayudará a deployar la aplicación Artex completa en minutos.

## Prerequisitos

- Docker >= 20.10
- Docker Compose >= 2.0
- Conexión a internet (para clonar repos de GitHub)

## Pasos de Deployment

### 1. Clonar el repositorio de deployment

```bash
git clone https://github.com/TU_USUARIO/Grupo-4-Construccion.git
cd Grupo-4-Construccion
```

### 2. Configurar variables de entorno

```bash
# Copiar el template
cp .env.example .env

# Editar con tus valores
nano .env  # o vim, code, etc.
```

**Variables MÍNIMAS que debes cambiar:**

```bash
# Seguridad
DATABASE_PASSWORD=tu_password_seguro_aqui
MARIADB_ROOT_PASSWORD=otro_password_seguro_aqui
DJANGO_SECRET_KEY=tu_django_secret_key_aqui
NEXTAUTH_SECRET=tu_nextauth_secret_aqui

# AWS S3 (si usas S3)
AWS_ACCESS_KEY_ID=tu_aws_key
AWS_SECRET_ACCESS_KEY=tu_aws_secret
AWS_STORAGE_BUCKET_NAME=tu-bucket

# Email
EMAIL_HOST_USER=tu-email@gmail.com
EMAIL_HOST_PASSWORD=tu-app-password
```

**Generar secrets seguros:**

```bash
# Django Secret Key
python3 -c 'from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())'

# NextAuth Secret
openssl rand -base64 32
```

### 3. Iniciar el deployment

```bash
docker compose -f docker-compose.remote.yml up -d
```

Esto descargará los repositorios de GitHub y construirá todo automáticamente.

### 4. Verificar el estado

```bash
# Ver todos los servicios
docker compose -f docker-compose.remote.yml ps

# Ver logs en tiempo real
docker compose -f docker-compose.remote.yml logs -f

# Ver solo logs del backend
docker compose -f docker-compose.remote.yml logs -f backend

# Ver solo logs del frontend
docker compose -f docker-compose.remote.yml logs -f frontend
```

### 5. Acceder a la aplicación

- **Frontend:** http://localhost:3000
- **Backend API:** http://localhost:8000/api/
- **Django Admin:** http://localhost:8000/admin/

## 🔄 Actualizar a la última versión

Cuando hagas cambios en los repositorios de backend o frontend:

```bash
# Rebuild desde GitHub (última versión)
docker compose -f docker-compose.remote.yml build --no-cache backend frontend

# Reiniciar servicios
docker compose -f docker-compose.remote.yml up -d
```

## 🛑 Detener servicios

```bash
# Detener sin borrar datos
docker compose -f docker-compose.remote.yml down

# Detener y borrar TODO (incluyendo base de datos)
docker compose -f docker-compose.remote.yml down -v
```

## 🐛 Troubleshooting Rápido

### Backend no inicia (unhealthy)

```bash
# Ver logs del backend
docker compose -f docker-compose.remote.yml logs backend

# Problemas comunes:
# - Database no está lista → espera 2-3 minutos
# - Migraciones fallan → revisa credenciales de DB en .env
# - Falta alguna variable → compara con .env.example
```

### Frontend no carga

```bash
# Ver logs del frontend
docker compose -f docker-compose.remote.yml logs frontend

# Problemas comunes:
# - Backend no está listo → espera a que backend esté healthy
# - Error 401 en login → revisa NEXTAUTH_SECRET en .env
```

### Imágenes S3 no cargan

```bash
# Verifica las variables AWS en .env:
AWS_S3_CUSTOM_DOMAIN=tu-cloudfront-domain
NEXT_PUBLIC_AWS_S3_CUSTOM_DOMAIN=tu-cloudfront-domain
AWS_ACCESS_KEY_ID=tu-key
AWS_SECRET_ACCESS_KEY=tu-secret
AWS_STORAGE_BUCKET_NAME=tu-bucket
```

## 📊 Comandos útiles

```bash
# Reiniciar un servicio específico
docker compose -f docker-compose.remote.yml restart backend
docker compose -f docker-compose.remote.yml restart frontend

# Ver uso de recursos
docker stats

# Entrar a un contenedor
docker compose -f docker-compose.remote.yml exec backend bash
docker compose -f docker-compose.remote.yml exec frontend sh

# Backup de base de datos
docker compose -f docker-compose.remote.yml exec db mysqldump -u root -p${MARIADB_ROOT_PASSWORD} db_arte > backup_$(date +%Y%m%d).sql

# Restaurar base de datos
docker compose -f docker-compose.remote.yml exec -T db mysql -u root -p${MARIADB_ROOT_PASSWORD} db_arte < backup.sql
```

## 🌐 Deployment en Producción

### Cambios necesarios en `.env`:

```bash
# URLs públicas
FRONTEND_URL=https://tu-dominio.com
NEXTAUTH_URL=https://tu-dominio.com

# Seguridad
DEBUG=False

# Passwords únicos y seguros
DATABASE_PASSWORD=password_produccion_super_seguro
MARIADB_ROOT_PASSWORD=root_password_super_seguro
```

### Configurar reverse proxy (Nginx ejemplo):

```nginx
server {
    listen 80;
    server_name tu-dominio.com;

    # Frontend
    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Backend API
    location /bapi/ {
        proxy_pass http://localhost:8000/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

Luego agrega SSL con Certbot:

```bash
sudo certbot --nginx -d tu-dominio.com
```

## ✅ Checklist de Deployment

- [ ] Variables de entorno configuradas en `.env`
- [ ] Passwords cambiados de los defaults
- [ ] Django Secret Key generada
- [ ] NextAuth Secret generada
- [ ] Credenciales AWS S3 configuradas (si aplica)
- [ ] Email SMTP configurado
- [ ] `docker compose up` ejecutado exitosamente
- [ ] Backend accesible en http://localhost:8000
- [ ] Frontend accesible en http://localhost:3000
- [ ] Login funciona correctamente
- [ ] Imágenes S3 cargan correctamente
- [ ] Reverse proxy configurado (producción)
- [ ] SSL certificado instalado (producción)
- [ ] Backups automáticos configurados (producción)

## 📞 Soporte

Si tienes problemas, revisa:
1. Los logs de los contenedores
2. Que todas las variables de `.env` estén configuradas
3. Que los puertos 3000, 8000, 3307 no estén en uso
4. Que Docker tenga suficiente memoria (mínimo 4GB recomendado)

---

**Repositorios:**
- Backend: https://github.com/Erickxse/dj_py_bck.git
- Frontend: https://github.com/Erickxse/nx_js_ft.git
- Deployment: Este repositorio
