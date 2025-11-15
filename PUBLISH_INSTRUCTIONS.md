# 📦 Instrucciones para publicar el repositorio de deployment

## Paso 1: Crear repositorio en GitHub

1. Ve a https://github.com/new
2. Nombre del repositorio: `aretis-deploy`
3. Descripción: "Docker Compose deployment configuration for Aretis platform"
4. Visibilidad: **Private** (recomendado, contiene configuración de infraestructura)
5. NO inicialices con README, .gitignore o licencia (ya los tienes localmente)
6. Crea el repositorio

## Paso 2: Preparar archivos locales

```bash
cd /home/esmora/visual/aretis/deploy

# Verificar que .gitignore existe
cat .gitignore

# Asegurarte de que .env NO se suba (verificar que está en .gitignore)
grep -q "^.env$" .gitignore && echo "✅ .env está ignorado" || echo "❌ Agrega .env a .gitignore"

# Verificar archivos que se subirán
ls -la
```

## Paso 3: Inicializar repositorio Git

```bash
cd /home/esmora/visual/aretis/deploy

# Inicializar git (si no está inicializado)
git init

# Agregar archivos
git add .

# Hacer commit inicial
git commit -m "Initial commit: Aretis deployment configuration

- Docker Compose con build desde repos GitHub
- Scripts de deployment helper
- Documentación completa de deployment
- Configuración de ejemplo (.env.example)
- SQL dump inicial"

# Conectar con el repositorio remoto (reemplaza TU_USUARIO)
git remote add origin https://github.com/TU_USUARIO/aretis-deploy.git

# Verificar remote
git remote -v

# Push al repositorio
git branch -M main
git push -u origin main
```

## Paso 4: Verificar en GitHub

1. Ve a https://github.com/TU_USUARIO/aretis-deploy
2. Verifica que NO aparece el archivo `.env` (solo `.env.example`)
3. Verifica que están todos los archivos necesarios:
   - ✅ docker-compose.remote.yml
   - ✅ README.md
   - ✅ DEPLOYMENT_GUIDE.md
   - ✅ .env.example
   - ✅ .gitignore
   - ✅ deploy.sh
   - ✅ initdb/dump.sql

## Paso 5: Actualizar los Dockerfiles en los repos de frontend/backend

### Frontend (https://github.com/esmora2/frontend_exhibidor_dearte)

```bash
cd /home/esmora/visual/aretis/frontend_exhibidor_dearte

# Verificar cambios
git status
git diff Dockerfile

# Commit y push del Dockerfile actualizado
git add Dockerfile
git commit -m "feat: Add build args support for NEXT_PUBLIC_* env vars

- Accept NEXT_PUBLIC_AWS_S3_CUSTOM_DOMAIN as build arg
- Accept NEXT_PUBLIC_AX_STORAGE_URL as build arg  
- Allows building from remote repos with proper env injection"

git push origin deploy
```

### Backend (https://github.com/esmora2/backend_exhibidor_dearte)

El Dockerfile del backend ya está listo, pero verifica si necesitas push de cambios:

```bash
cd /home/esmora/visual/aretis/backend_exhibidor_dearte

# Verificar estado
git status

# Si hay cambios en los serializers
git add apps/service_product/serializers.py apps/stand/serializers.py
git commit -m "feat: Add S3 URL builder to serializers

- Build complete S3 URLs for media files
- Support both S3 and local media storage
- Return full URLs instead of filenames"

git push origin deploy
```

## Paso 6: Probar deployment remoto

En una máquina limpia (o VM):

```bash
# Clonar solo el repo de deployment
git clone https://github.com/TU_USUARIO/aretis-deploy.git
cd aretis-deploy

# Configurar .env
cp .env.example .env
nano .env  # Configurar valores reales

# Iniciar deployment
./deploy.sh start

# Verificar
./deploy.sh status
```

## 📝 Estructura final de repositorios

Tendrás 3 repositorios en GitHub:

### 1. `frontend_exhibidor_dearte` (código frontend)
- URL: https://github.com/esmora2/frontend_exhibidor_dearte
- Branch: `deploy`
- Contiene: Código Next.js, Dockerfile con build args

### 2. `backend_exhibidor_dearte` (código backend)
- URL: https://github.com/esmora2/backend_exhibidor_dearte
- Branch: `deploy`
- Contiene: Código Django, Dockerfile, serializers con S3

### 3. `aretis-deploy` (configuración de deployment) **NUEVO**
- URL: https://github.com/TU_USUARIO/aretis-deploy
- Branch: `main`
- Contiene:
  - docker-compose.remote.yml (referencia a repos 1 y 2)
  - Scripts de deployment
  - Documentación
  - SQL dump inicial
  - .env.example (NO incluye .env con secretos)

## 🔄 Flujo de trabajo completo

### Desarrollo
1. Haces cambios en `frontend_exhibidor_dearte` o `backend_exhibidor_dearte`
2. Commit y push a la rama `deploy`

### Deployment
1. En el servidor: `cd aretis-deploy`
2. Ejecuta: `./deploy.sh rebuild`
3. Docker Compose clona automáticamente los últimos commits de los repos
4. Construye y despliega

## 🔐 Seguridad

### NO subas a Git:
- ❌ `.env` (credenciales reales)
- ❌ Backups de DB con datos reales
- ❌ Archivos de certificados SSL
- ❌ Claves privadas

### SÍ sube a Git:
- ✅ `.env.example` (plantilla sin secretos)
- ✅ docker-compose.yml
- ✅ Documentación
- ✅ Scripts
- ✅ SQL dump inicial (si no contiene datos sensibles)

## 📧 Variables de entorno en servidor

En producción, considera usar:
- **Docker secrets**
- **Variables de entorno del sistema**
- **Servicios de gestión de secretos** (AWS Secrets Manager, HashiCorp Vault, etc.)

Ejemplo con Docker secrets:

```yaml
services:
  backend:
    secrets:
      - db_password
      - django_secret
    environment:
      DATABASE_PASSWORD_FILE: /run/secrets/db_password
      DJANGO_SECRET_KEY_FILE: /run/secrets/django_secret

secrets:
  db_password:
    file: ./secrets/db_password.txt
  django_secret:
    file: ./secrets/django_secret.txt
```

## ✅ Checklist final

Antes de considerar completo:

- [ ] Repositorio `aretis-deploy` creado y pusheado
- [ ] `.env` está en `.gitignore` y NO se subió
- [ ] Dockerfile del frontend actualizado con build args
- [ ] Cambios en serializers del backend pusheados
- [ ] README.md está actualizado y claro
- [ ] `deploy.sh` tiene permisos de ejecución
- [ ] Probado en una máquina limpia
- [ ] Documentación revisada

## 🎉 ¡Listo!

Ahora puedes deployar Aretis en cualquier servidor simplemente clonando el repo `aretis-deploy` y ejecutando `./deploy.sh start`.
