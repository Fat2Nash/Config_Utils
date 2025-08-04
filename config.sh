#!/bin/bash

# ======================
# Configuration MyTools
# ======================

# Configuration MySQL
MYSQL_USER="user"
MYSQL_PASSWORD="MyUserPassword"

# Configuration Git (optionnel - sera demandé si non configuré)
GIT_USER_NAME=""
GIT_USER_EMAIL=""

# Configuration SSH (optionnel - sera demandé si non configuré)
SSH_EMAIL=""

# Fichier de log
LOG_FILE="/tmp/mytools.log"

# Paquets essentiels à vérifier
ESSENTIAL_PACKAGES=("curl" "wget" "git" "openssh-client")

# Services à surveiller
MONITORED_SERVICES=("mysql" "redis-server" "nginx" "apache2")

# Configuration du benchmark
BENCHMARK_CPU_PRIME=20000
BENCHMARK_DISK_SIZE="1G"

# Timeout pour les opérations réseau (en secondes)
NETWORK_TIMEOUT=30

# Couleurs personnalisées (optionnel)
CUSTOM_COLORS=false
# Si CUSTOM_COLORS=true, vous pouvez personnaliser les couleurs ici
# RED='\033[0;31m'
# GREEN='\033[0;32m'
# etc.