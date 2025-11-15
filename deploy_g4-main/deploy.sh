#!/bin/bash
# Script helper para deployment de Aretis
# Uso: ./deploy.sh [start|stop|restart|rebuild|logs|status]

set -e

COMPOSE_FILE="docker-compose.remote.yml"

function check_env() {
    if [ ! -f .env ]; then
        echo "❌ Error: archivo .env no encontrado"
        echo "📝 Copia .env.example a .env y configura tus valores:"
        echo "   cp .env.example .env"
        echo "   nano .env"
        exit 1
    fi
}

function start() {
    check_env
    echo "🚀 Iniciando servicios Aretis..."
    docker compose -f $COMPOSE_FILE up -d
    echo "✅ Servicios iniciados"
    echo "📊 Verifica el estado con: ./deploy.sh status"
}

function stop() {
    echo "🛑 Deteniendo servicios Aretis..."
    docker compose -f $COMPOSE_FILE down
    echo "✅ Servicios detenidos"
}

function restart() {
    echo "🔄 Reiniciando servicios Aretis..."
    docker compose -f $COMPOSE_FILE restart
    echo "✅ Servicios reiniciados"
}

function rebuild() {
    check_env
    echo "🔨 Reconstruyendo imágenes desde GitHub..."
    docker compose -f $COMPOSE_FILE build --no-cache
    echo "🚀 Reiniciando servicios..."
    docker compose -f $COMPOSE_FILE up -d
    echo "✅ Rebuild completado"
}

function logs() {
    SERVICE=${2:-}
    if [ -z "$SERVICE" ]; then
        echo "📋 Mostrando logs de todos los servicios..."
        docker compose -f $COMPOSE_FILE logs -f
    else
        echo "📋 Mostrando logs de $SERVICE..."
        docker compose -f $COMPOSE_FILE logs -f $SERVICE
    fi
}

function status() {
    echo "📊 Estado de los servicios:"
    docker compose -f $COMPOSE_FILE ps
    echo ""
    echo "🏥 Health checks:"
    docker compose -f $COMPOSE_FILE ps --format json | jq -r '.[] | "\(.Service): \(.Health)"'
}

function backup_db() {
    BACKUP_FILE="backup_$(date +%Y%m%d_%H%M%S).sql"
    echo "💾 Creando backup de la base de datos..."
    docker compose -f $COMPOSE_FILE exec -T db mysqldump -u root -p"${MARIADB_ROOT_PASSWORD}" db_arte > "$BACKUP_FILE"
    echo "✅ Backup guardado en: $BACKUP_FILE"
}

function restore_db() {
    RESTORE_FILE=${2:-}
    if [ -z "$RESTORE_FILE" ]; then
        echo "❌ Error: especifica el archivo SQL a restaurar"
        echo "Uso: ./deploy.sh restore backup_20231113.sql"
        exit 1
    fi
    
    if [ ! -f "$RESTORE_FILE" ]; then
        echo "❌ Error: archivo $RESTORE_FILE no encontrado"
        exit 1
    fi
    
    echo "⚠️  ADVERTENCIA: Esto sobrescribirá la base de datos actual"
    read -p "¿Continuar? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "📥 Restaurando base de datos desde $RESTORE_FILE..."
        docker compose -f $COMPOSE_FILE exec -T db mysql -u root -p"${MARIADB_ROOT_PASSWORD}" db_arte < "$RESTORE_FILE"
        echo "✅ Base de datos restaurada"
    else
        echo "❌ Restauración cancelada"
    fi
}

function help() {
    echo "Aretis Deployment Helper"
    echo ""
    echo "Uso: ./deploy.sh [comando] [opciones]"
    echo ""
    echo "Comandos:"
    echo "  start       - Iniciar todos los servicios"
    echo "  stop        - Detener todos los servicios"
    echo "  restart     - Reiniciar todos los servicios"
    echo "  rebuild     - Reconstruir imágenes desde GitHub y reiniciar"
    echo "  logs [srv]  - Ver logs (opcionalmente de un servicio específico)"
    echo "  status      - Ver estado de los servicios"
    echo "  backup      - Crear backup de la base de datos"
    echo "  restore <f> - Restaurar base de datos desde archivo"
    echo "  help        - Mostrar esta ayuda"
    echo ""
    echo "Ejemplos:"
    echo "  ./deploy.sh start"
    echo "  ./deploy.sh logs backend"
    echo "  ./deploy.sh rebuild"
    echo "  ./deploy.sh backup"
    echo "  ./deploy.sh restore backup_20231113.sql"
}

# Main
case "${1:-}" in
    start)
        start
        ;;
    stop)
        stop
        ;;
    restart)
        restart
        ;;
    rebuild)
        rebuild
        ;;
    logs)
        logs "$@"
        ;;
    status)
        status
        ;;
    backup)
        backup_db
        ;;
    restore)
        restore_db "$@"
        ;;
    help|--help|-h)
        help
        ;;
    *)
        echo "❌ Comando desconocido: ${1:-}"
        echo ""
        help
        exit 1
        ;;
esac
