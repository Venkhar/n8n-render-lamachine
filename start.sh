#!/bin/bash

echo "🚀 Démarrage de N8N avec MCP Haloscan..."

# Configuration des logs
exec > >(tee -a /var/log/mcp/startup.log) 2>&1

# Fonction de logging
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

log "Configuration de l'environnement MCP..."

# Remplacer la clé API placeholder si définie
if [ ! -z "$HALOSCAN_API_KEY" ]; then
    log "Configuration de la clé API Haloscan..."
    sed -i "s/PLACEHOLDER_API_KEY/$HALOSCAN_API_KEY/g" /home/node/.config/claude/claude_desktop_config.json
else
    log "⚠️  ATTENTION: HALOSCAN_API_KEY non définie!"
fi

# Créer un fichier de statut pour le health check
echo "starting" > /tmp/app-status

# Fonction de nettoyage
cleanup() {
    log "🛑 Arrêt des services..."
    kill $MCP_PID 2>/dev/null
    kill $N8N_PID 2>/dev/null
    echo "stopped" > /tmp/app-status
    exit 0
}

# Capturer les signaux d'arrêt
trap cleanup SIGTERM SIGINT

# Démarrer le serveur MCP Haloscan en arrière-plan
log "Démarrage du serveur MCP Haloscan..."
npx @occirank/haloscan-server start &
MCP_PID=$!

# Attendre que le serveur MCP soit prêt
log "Attente du démarrage MCP..."
for i in {1..30}; do
    if curl -s http://localhost:3001/health >/dev/null 2>&1; then
        log "✅ Serveur MCP Haloscan prêt!"
        break
    fi
    if [ $i -eq 30 ]; then
        log "❌ Timeout: Serveur MCP non accessible"
        exit 1
    fi
    sleep 2
done

# Marquer l'application comme prête
echo "ready" > /tmp/app-status

# Démarrer N8N
log "Démarrage de N8N..."
n8n start &
N8N_PID=$!

# Attendre que N8N soit prêt
log "Attente du démarrage N8N..."
for i in {1..60}; do
    if curl -s http://localhost:5678/healthz >/dev/null 2>&1; then
        log "✅ N8N prêt et accessible!"
        break
    fi
    sleep 3
done

log "🎉 Tous les services sont démarrés!"
log "N8N disponible sur le port 5678"
log "MCP Haloscan disponible sur le port 3001"

# Attendre la fin des processus
wait $N8N_PID
