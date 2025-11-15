# Guía de Deployment en Servidor

Esta guía detalla cómo deployar Aretis en un servidor VPS/dedicado desde cero.

##  Pre-requisitos del servidor

- Ubuntu 20.04+ / Debian 11+ (recomendado) o CentOS 8+
- Mínimo 2GB RAM (recomendado 4GB+)
- 20GB+ espacio en disco
- Acceso root o sudo

## 🔧 Instalación de Docker

### Ubuntu/Debian

```bash
# Actualizar sistema
sudo apt update && sudo apt upgrade -y

# Instalar dependencias
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common

# Agregar repositorio de Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Instalar Docker
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Habilitar Docker al inicio
sudo systemctl enable docker
sudo systemctl start docker

# Agregar usuario al grupo docker (reemplaza 'usuario' con tu username)
sudo usermod -aG docker $USER
newgrp docker

# Verificar instalación
docker --version
docker compose version
```

### CentOS/RHEL

```bash
# Actualizar sistema
sudo yum update -y

# Instalar dependencias
sudo yum install -y yum-utils

# Agregar repositorio
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

# Instalar Docker
sudo yum install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Iniciar Docker
sudo systemctl start docker
sudo systemctl enable docker

# Agregar usuario al grupo
sudo usermod -aG docker $USER
newgrp docker
```

## 🚀 Deployment de Aretis

### 1. Clonar repositorio de deployment

```bash
cd /opt  # o la ubicación que prefieras
git clone https://github.com/TU_USUARIO/aretis-deploy.git
cd aretis-deploy
```

### 2. Configurar variables de entorno

```bash
cp .env.example .env
nano .env  # o vim, dependiendo de tu preferencia
```

**Variables críticas a configurar:**

```bash
# Genera contraseñas seguras
DATABASE_PASSWORD=$(openssl rand -base64 32)
MARIADB_ROOT_PASSWORD=$(openssl rand -base64 32)
DJANGO_SECRET_KEY=$(python3 -c "import secrets; print(secrets.token_urlsafe(50))")
NEXTAUTH_SECRET=$(openssl rand -base64 32)

# Configura tus credenciales AWS
AWS_ACCESS_KEY_ID=tu_access_key
AWS_SECRET_ACCESS_KEY=tu_secret_key
AWS_STORAGE_BUCKET_NAME=tu_bucket

# Email
EMAIL_HOST_USER=tu_email@gmail.com
EMAIL_HOST_PASSWORD=tu_app_password
```

### 3. Iniciar servicios

```bash
# Usando el script helper
./deploy.sh start

# O manualmente
docker compose -f docker-compose.remote.yml up -d
```

### 4. Verificar estado

```bash
./deploy.sh status

# Deberías ver algo como:
# NAME                  IMAGE               STATUS              HEALTH
# aretis-db-1          mariadb:11          Up 2 minutes        healthy
# aretis-backend-1     ...                 Up 1 minute         healthy
# aretis-frontend-1    ...                 Up 30 seconds       running
```

### 5. Ver logs

```bash
# Todos los servicios
./deploy.sh logs

# Solo un servicio
./deploy.sh logs backend
```

##  Configurar Nginx como Reverse Proxy

### Instalar Nginx

```bash
sudo apt install -y nginx
```

### Configurar sitio

```bash
sudo nano /etc/nginx/sites-available/aretis
```

Contenido:

```nginx
server {
    listen 80;
    server_name tu-dominio.com www.tu-dominio.com;

    # Frontend Next.js
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }

    # Backend API
    location /bapi/ {
        proxy_pass http://localhost:8000/;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Admin de Django (opcional, puede requerir auth adicional)
    location /admin/ {
        proxy_pass http://localhost:8000/admin/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    # Archivos estáticos del backend
    location /static/ {
        proxy_pass http://localhost:8000/static/;
    }
}
```

### Habilitar sitio

```bash
sudo ln -s /etc/nginx/sites-available/aretis /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

##  Configurar SSL con Let's Encrypt

```bash
# Instalar Certbot
sudo apt install -y certbot python3-certbot-nginx

# Obtener certificado
sudo certbot --nginx -d tu-dominio.com -d www.tu-dominio.com

# El certificado se renovará automáticamente
```

##  Configurar Firewall

```bash
# UFW (Ubuntu)
sudo ufw allow ssh
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable

# Firewalld (CentOS)
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --reload
```

## Monitoreo y Logs

### Ver logs en tiempo real

```bash
./deploy.sh logs
```

### Logs de Nginx

```bash
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log
```

### Logs de Docker

```bash
docker compose -f docker-compose.remote.yml logs -f --tail=100
```

##  Backups

### Backup automático con cron

```bash
# Editar crontab
crontab -e

# Agregar backup diario a las 2 AM
0 2 * * * cd /opt/aretis-deploy && ./deploy.sh backup && find . -name "backup_*.sql" -mtime +7 -delete
```

### Backup manual

```bash
./deploy.sh backup
```

##  Actualizar a última versión

```bash
cd /opt/aretis-deploy
./deploy.sh rebuild
```

Esto:
1. Descarga los últimos cambios de los repos de GitHub
2. Reconstruye las imágenes
3. Reinicia los servicios

##  Ajustes de rendimiento

### Recursos de Docker

Edita `/etc/docker/daemon.json`:

```json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
```

Reinicia Docker:

```bash
sudo systemctl restart docker
```

### Escalar workers de Gunicorn

Edita el Dockerfile del backend y cambia `--workers`:

```dockerfile
CMD gunicorn artex_api.wsgi:application --bind 0.0.0.0:${PORT} --workers 4 --timeout 90
```

Recomendación: `workers = 2 * CPU_cores + 1`

##  Seguridad

### Mejores prácticas

1. **No expongas puertos directamente**: Usa Nginx como proxy
2. **Cambia los puertos por defecto** en docker-compose si es necesario
3. **Usa secretos de Docker** para credenciales sensibles
4. **Mantén actualizado** el sistema y Docker
5. **Implementa fail2ban** para proteger SSH
6. **Habilita logs de auditoría**

### Fail2ban para SSH

```bash
sudo apt install -y fail2ban
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
```

##  Troubleshooting

### Backend no inicia

```bash
# Ver logs detallados
docker compose -f docker-compose.remote.yml logs backend

# Verificar conexión a DB
docker compose -f docker-compose.remote.yml exec backend python manage.py check
```

### Frontend build falla

```bash
# Limpiar y rebuild
docker compose -f docker-compose.remote.yml build --no-cache frontend
```

### Base de datos corrupta

```bash
# Restaurar desde backup
./deploy.sh restore backup_YYYYMMDD.sql
```

### Problemas de memoria

```bash
# Ver uso de recursos
docker stats

# Limpiar recursos no usados
docker system prune -a
```
