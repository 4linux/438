#!/bin/bash

# Inicia display virtual com resolução maior
Xvfb :1 -screen 0 1366x768x16 &

# Aguarda o display subir
sleep 2

# Inicia o gerenciador de janelas
DISPLAY=:1 fluxbox &

# Aguarda o fluxbox carregar completamente
sleep 3

# Inicia o VNC Server
x11vnc -display :1 -forever -nopw -shared -bg

# Inicia noVNC apontando para a interface web
/opt/novnc/utils/novnc_proxy --vnc localhost:5900 --listen 6080 --web /opt/novnc &

# Aguarda um pouco para garantir que tudo foi iniciado
sleep 2

# Inicia o VisualVM com o classpath adicional
DISPLAY=:1 bash /srv/visualvm/bin/visualvm --cp:a /srv/visualvm/jboss-client.jar &

# Evita que o script finalize e mate o container
wait
