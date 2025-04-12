FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Instala dependências
RUN apt update && apt install -y \
    openjdk-17-jdk \
    wget unzip curl git \
    x11vnc xvfb fluxbox \
    net-tools supervisor \
    python3 python3-websockify \
    && apt clean

# Instala VisualVM
RUN wget https://github.com/oracle/visualvm/releases/download/2.1.10/visualvm_2110.zip \
    && unzip visualvm_2110.zip \
    && mv visualvm_2110 /srv/visualvm \
    && rm visualvm_2110.zip

# Instala noVNC
RUN git clone https://github.com/novnc/noVNC.git /opt/novnc && \
    git clone https://github.com/novnc/websockify /opt/novnc/utils/websockify

# Copia o arquivo jboss-client.jar
COPY jboss-client.jar /srv/visualvm/jboss-client.jar

# Copia script de inicialização
COPY start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 6080

CMD ["/start.sh"]
