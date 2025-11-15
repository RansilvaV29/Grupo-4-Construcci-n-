# ⚡ Instrucciones de Publicación

## 📤 Pasos para Publicar los Cambios

### 1️⃣ Repositorio Backend (dj_py_bck)

```bash
cd /home/esmora/visual/Aretis_G8/dj_py_bck

# Verificar que .env está ignorado
git status

# Agregar el nuevo Dockerfile
git add Dockerfile

# Commit
git commit -m "feat: Add Dockerfile for containerized deployment"

# Push a GitHub
git push origin main
```

### 2️⃣ Repositorio de Deployment (Grupo-4-Construccion)

```bash
cd /home/esmora/visual/Aretis_G8/Grupo-4-Construcci-n-

# Verificar archivos modificados/nuevos
git status

# Agregar todos los archivos nuevos y modificados
git add .env.example
git add .gitignore
git add docker-compose.remote.yml
git add README.md
git add QUICK_START.md
git add CAMBIOS_REALIZADOS.md

# Verificar que .env NO está en staging (debe estar ignorado)
git status

# Commit
git commit -m "feat: Update deployment config with new repos and comprehensive env management"

# Push a GitHub
git push origin main
```

## ⚠️ IMPORTANTE: Verificaciones de Seguridad

Antes de hacer push, asegúrate de que:

### ❌ NO subir estos archivos:
- `.env` (con valores reales)
- `*.backup`
- `*.sql` (dumps de producción)
- Credenciales o passwords

### ✅ SÍ subir estos archivos:
- `.env.example` (con placeholders)
- `.gitignore`
- `Dockerfile`
- `docker-compose.remote.yml`
- Documentación

### Comando para verificar:
```bash
# Ver qué archivos están siendo trackeados
git ls-files | grep -E "\.env$|password|secret"

# Si aparece .env, eliminarlo del staging:
git reset .env
```

## 🧪 Probar el Deployment

### En local (simular deployment remoto):

```bash
# Ir al directorio de deployment
cd /home/esmora/visual/Aretis_G8/Grupo-4-Construcci-n-

# Crear .env desde el ejemplo
cp .env.example .env

# Editar con tus valores reales
nano .env

# Ejecutar deployment
docker compose -f docker-compose.remote.yml up -d

# Ver logs
docker compose -f docker-compose.remote.yml logs -f

# Verificar estado
docker compose -f docker-compose.remote.yml ps
```

### Verificar que funciona:
- ✅ Backend: http://localhost:8000/admin/
- ✅ Frontend: http://localhost:3000
- ✅ Login funciona
- ✅ Imágenes S3 cargan
- ✅ Base de datos conecta correctamente

## 🚀 Deployment en Servidor Remoto

### Una vez verificado en local:

```bash
# En el servidor remoto
ssh usuario@tu-servidor.com

# Clonar el repo de deployment
git clone https://github.com/TU_USUARIO/Grupo-4-Construccion.git
cd Grupo-4-Construccion

# Configurar variables de entorno
cp .env.example .env
nano .env  # Editar con valores de producción

# Iniciar deployment
docker compose -f docker-compose.remote.yml up -d

# Ver logs
docker compose -f docker-compose.remote.yml logs -f
```

## 📋 Checklist Final

Antes de declarar el deployment completo:

### Repositorio Backend
- [ ] `Dockerfile` creado y pusheado a GitHub
- [ ] `.env` está en `.gitignore`
- [ ] Código está en rama `main`
- [ ] Build funciona: `docker build -t test-backend .`

### Repositorio Frontend
- [ ] `Dockerfile.remote` existe
- [ ] `.env` está en `.gitignore`
- [ ] Código está en rama `main`
- [ ] Build funciona con build args

### Repositorio Deployment
- [ ] `.env.example` creado con todas las variables
- [ ] `.gitignore` ignora archivos sensibles
- [ ] `docker-compose.remote.yml` apunta a repos correctos
- [ ] README actualizado con instrucciones
- [ ] QUICK_START.md creado
- [ ] `.env` NO está commiteado

### Testing
- [ ] Deployment funciona en local
- [ ] Backend accesible y saludable
- [ ] Frontend accesible y conecta al backend
- [ ] Base de datos inicia correctamente
- [ ] Migraciones se ejecutan automáticamente
- [ ] Login funciona
- [ ] Imágenes S3 cargan (si aplica)

### Producción
- [ ] Variables de entorno de producción configuradas
- [ ] Passwords seguros y únicos generados
- [ ] SSL configurado (si aplica)
- [ ] Reverse proxy configurado (si aplica)
- [ ] Backups de base de datos configurados
- [ ] Monitoring básico configurado

## 🆘 Si algo sale mal

### Backend no inicia
```bash
# Ver logs detallados
docker compose -f docker-compose.remote.yml logs backend

# Problemas comunes:
# - Database no conecta → revisar credenciales en .env
# - Migraciones fallan → revisar DATABASE_NAME
# - Puerto ocupado → cambiar en docker-compose
```

### Frontend no inicia
```bash
# Ver logs detallados
docker compose -f docker-compose.remote.yml logs frontend

# Problemas comunes:
# - Backend no disponible → esperar a que backend esté healthy
# - Build args incorrectos → revisar NEXT_PUBLIC_* en .env
# - Error 401 → revisar NEXTAUTH_SECRET
```

### Rebuild desde cero
```bash
# Detener todo
docker compose -f docker-compose.remote.yml down -v

# Limpiar imágenes
docker compose -f docker-compose.remote.yml build --no-cache

# Reiniciar
docker compose -f docker-compose.remote.yml up -d
```

## 📞 Soporte

Si necesitas ayuda:
1. Revisar logs: `docker compose logs -f`
2. Revisar este documento y QUICK_START.md
3. Verificar que todas las variables de .env estén configuradas
4. Comparar tu .env con .env.example

---

**¡Todo listo para deployment! 🎉**

Recuerda: La clave está en mantener `.env` fuera del repositorio y usar `.env.example` como template.
