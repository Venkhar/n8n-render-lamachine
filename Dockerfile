FROM n8nio/n8n:latest

# Passer en root pour les installations
USER root

# Installer Node.js et npm si nécessaire (généralement déjà présents)
RUN npm install -g npm@latest

# Installer le serveur MCP Haloscan
RUN npm install -g @occirank/haloscan-server

# Créer le répertoire de configuration MCP
RUN mkdir -p /home/node/.config/claude

# Créer le fichier de configuration MCP
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

# Changer la propriété du répertoire de configuration
RUN chown -R node:node /home/node/.config

# Revenir à l'utilisateur node
USER node

# Exposer le port N8N (5678 par défaut)
EXPOSE 5678

# Commande de démarrage
CMD ["n8n", "start"]
