# Base image N8N officielle
FROM n8nio/n8n:latest

# Informations du maintainer
LABEL maintainer="votre-email@exemple.com"
LABEL description="N8N with Haloscan MCP Server"

# Passer en root pour les installations système
USER root

# Mettre à jour les packages et installer les dépendances
RUN apk update && apk add --no-cache \
    bash \
    curl \
    git \
    && rm -rf /var/cache/apk/*

# Installer Node.js global packages
RUN npm install -g \
    npm@latest \
    @occirank/haloscan-server

# Créer la structure de répertoires pour MCP
RUN mkdir -p /home/node/.config/claude \
    && mkdir -p /home/node/.config/mcp \
    && mkdir -p /var/log/mcp

# Créer le fichier de configuration MCP initial
RUN echo '{\
  "mcpServers": {\
    "haloscan": {\
      "command": "npx",\
      "args": ["-y", "@occirank/haloscan-server", "start"],\
      "env": {\
        "HALOSCAN_API_KEY": "PLACEHOLDER_API_KEY"\
      }\
    }\
  }\
}' > /home/node/.config/claude/claude_desktop_config.json

# Créer le fichier de configuration MCP pour N8N
RUN echo '{\
  "servers": {\
    "haloscan": {\
      "host": "localhost",\
      "port": 3001,\
      "protocol": "http"\
    }\
  }\
}' > /home/node/.config/mcp/config.json

# Copier le script de démarrage personnalisé
COPY start.sh /home/node/start.sh

# Rendre le script exécutable et ajuster les permissions
RUN chmod +x /home/node/start.sh \
    && chown -R node:node /home/node/.config \
    && chown -R node:node /var/log/mcp \
    && chown node:node /home/node/start.sh

# Revenir à l'utilisateur node pour la sécurité
USER node

# Variables d'environnement par défaut
ENV NODE_ENV=production
ENV N8N_HOST=0.0.0.0
ENV N8N_PORT=5678
ENV N8N_PROTOCOL=http
ENV WEBHOOK_URL=https://n8n-czuq.onrender.com/
ENV GENERIC_TIMEZONE=Europe/Paris

# Exposer les ports
EXPOSE 5678 3001

# Point de santé pour Render
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD curl -f http://localhost:5678/healthz || exit 1

# Commande de démarrage
CMD ["/home/node/start.sh"]
