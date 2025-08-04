#!/bin/bash

# ======================
# Script MyTools - Version Améliorée
# Auteur: Fat2Nash
# Description: Outil complet de configuration et déploiement
# ======================

# ======================
# Section 1: Configuration & Variables
# ======================

# Définir des couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Emojis et symboles
CHECK_MARK="✅"
CROSS_MARK="❌"
WARNING_MARK="⚠️"
INFO_MARK="ℹ️"
ROCKET_MARK="🚀"
GEAR_MARK="⚙️"
KEY_MARK="🔑"
SERVER_MARK="🖥️"
DATABASE_MARK="🗄️"
NETWORK_MARK="🌐"

# Variables de configuration
MYSQL_USER="user"
MYSQL_PASSWORD="MyUserPassword"
SCRIPT_VERSION="2.0.0"
LOG_FILE="/tmp/mytools.log"

# Variables d'état
SUDO_AVAILABLE=false
GITHUB_CONNECTED=false
GIT_CONFIGURED=false
SSH_KEYS_EXIST=false

# ======================
# Section 2: Fonctions utilitaires
# ======================

# Fonction de logging
log_message() {
    local level=$1
    local message=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
    echo -e "$message"
}

# Fonction pour afficher un titre stylisé
print_title() {
    local title=$1
    echo -e "\n${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC} ${WHITE}$title${NC} ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}\n"
}

# Fonction pour afficher un message de succès
print_success() {
    echo -e "${CHECK_MARK} ${GREEN}$1${NC}"
    log_message "SUCCESS" "$1"
}

# Fonction pour afficher un message d'erreur
print_error() {
    echo -e "${CROSS_MARK} ${RED}$1${NC}"
    log_message "ERROR" "$1"
}

# Fonction pour afficher un message d'avertissement
print_warning() {
    echo -e "${WARNING_MARK} ${YELLOW}$1${NC}"
    log_message "WARNING" "$1"
}

# Fonction pour afficher un message d'information
print_info() {
    echo -e "${INFO_MARK} ${BLUE}$1${NC}"
    log_message "INFO" "$1"
}

# Fonction pour demander confirmation
ask_confirmation() {
    local message=$1
    echo -e "${YELLOW}$message${NC} (o/n)"
    read -r response
    [[ "$response" =~ ^[Oo]$ ]]
}

# Fonction pour attendre l'utilisateur
wait_for_user() {
    local message=${1:-"Appuyez sur Entrée pour revenir au menu principal..."}
    echo -e "\n${CYAN}$message${NC}"
    read -r
}

# Fonction pour vérifier si une commande existe
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# ======================
# Section 3: Vérifications système
# ======================

# Vérification des droits sudo
check_sudo_rights() {
    print_info "Vérification des droits sudo..."
    
    if sudo -n true 2>/dev/null; then
        SUDO_AVAILABLE=true
        print_success "Droits sudo disponibles"
        return 0
    else
        print_warning "Demande des droits sudo..."
        if sudo -v; then
            SUDO_AVAILABLE=true
            print_success "Droits sudo accordés"
            return 0
        else
            print_error "Impossible d'obtenir les droits sudo. Certaines fonctionnalités ne seront pas disponibles."
            return 1
        fi
    fi
}

# Vérification de la connectivité internet
check_internet_connection() {
    print_info "Vérification de la connectivité internet..."
    
    if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
        print_success "Connexion internet disponible"
        return 0
    else
        print_error "Aucune connexion internet détectée"
        return 1
    fi
}

# Vérification des prérequis système
check_system_requirements() {
    print_info "Vérification des prérequis système..."
    
    local missing_packages=()
    
    # Vérifier les paquets essentiels
    local essential_packages=("curl" "wget" "git" "openssh-client")
    
    for package in "${essential_packages[@]}"; do
        if ! command_exists "$package"; then
            missing_packages+=("$package")
        fi
    done
    
    if [ ${#missing_packages[@]} -eq 0 ]; then
        print_success "Tous les prérequis sont installés"
        return 0
    else
        print_warning "Paquets manquants détectés: ${missing_packages[*]}"
        
        if [ "$SUDO_AVAILABLE" = true ] && ask_confirmation "Voulez-vous installer les paquets manquants ?"; then
            sudo apt update
            sudo apt install -y "${missing_packages[@]}"
            print_success "Paquets installés avec succès"
            return 0
        else
            print_error "Installation des paquets annulée"
            return 1
        fi
    fi
}

# ======================
# Section 4: Configuration GitHub
# ======================

# Vérification de la configuration Git
check_git_config() {
    print_info "Vérification de la configuration Git..."
    
    local git_name=$(git config --global user.name 2>/dev/null)
    local git_email=$(git config --global user.email 2>/dev/null)
    
    if [ -n "$git_name" ] && [ -n "$git_email" ]; then
        GIT_CONFIGURED=true
        print_success "Configuration Git trouvée: $git_name <$git_email>"
        
        # Vérifier le type d'authentification utilisé
        check_authentication_method
        
        return 0
    else
        print_warning "Configuration Git manquante"
        return 1
    fi
}

# Vérifier la méthode d'authentification utilisée
check_authentication_method() {
    print_info "Vérification de la méthode d'authentification..."
    
    # Vérifier si on est dans un dépôt Git
    if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        local remote_url=$(git remote get-url origin 2>/dev/null)
        
        if [[ "$remote_url" == git@github.com:* ]]; then
            print_success "Méthode d'authentification: SSH"
            print_info "URL distante: $remote_url"
        elif [[ "$remote_url" == https://github.com/* ]]; then
            print_success "Méthode d'authentification: HTTPS"
            print_info "URL distante: $remote_url"
            
            # Vérifier le credential helper
            local helper=$(git config --global credential.helper)
            if [ -n "$helper" ]; then
                print_success "Credential helper configuré: $helper"
            else
                print_warning "Aucun credential helper configuré pour HTTPS"
            fi
        else
            print_info "URL distante: $remote_url"
        fi
    else
        print_info "Pas dans un dépôt Git"
    fi
}

# Diagnostic SSH détaillé
diagnostic_ssh() {
    print_title "Diagnostic SSH Détaillé"
    
    echo -e "${CYAN}=== Répertoire SSH ===${NC}"
    if [ -d ~/.ssh ]; then
        echo -e "${GREEN}✅ Répertoire ~/.ssh existe${NC}"
        echo -e "${CYAN}Contenu du répertoire SSH:${NC}"
        ls -la ~/.ssh/
    else
        echo -e "${RED}❌ Répertoire ~/.ssh n'existe pas${NC}"
        wait_for_user
        return 1
    fi
    
    echo -e "\n${CYAN}=== Clés SSH ===${NC}"
    local pub_keys=$(find ~/.ssh -name "*.pub" -type f 2>/dev/null)
    if [ -n "$pub_keys" ]; then
        echo -e "${GREEN}✅ Clés publiques trouvées:${NC}"
        echo "$pub_keys" | while read -r key; do
            echo -e "${WHITE}$(basename "$key"):${NC}"
            cat "$key"
            echo ""
        done
    else
        echo -e "${RED}❌ Aucune clé publique trouvée${NC}"
    fi
    
    echo -e "\n${CYAN}=== Test de connexion SSH GitHub ===${NC}"
    local ssh_test_output
    ssh_test_output=$(ssh -T git@github.com 2>&1)
    echo -e "${WHITE}Sortie SSH:${NC} $ssh_test_output"
    
    if echo "$ssh_test_output" | grep -q "successfully authenticated"; then
        echo -e "${GREEN}✅ Connexion SSH GitHub réussie${NC}"
    elif echo "$ssh_test_output" | grep -q "Permission denied"; then
        echo -e "${YELLOW}⚠️ Clés SSH présentes mais non configurées sur GitHub${NC}"
    else
        echo -e "${RED}❌ Problème de connexion SSH${NC}"
    fi
    
    print_success "Diagnostic SSH terminé"
    wait_for_user
}

# Configuration automatique de Git
setup_git_config() {
    print_info "Configuration de Git..."
    
    echo -e "${CYAN}Configuration de votre identité Git:${NC}"
    read -r -p "Nom d'utilisateur: " git_name
    read -r -p "Email: " git_email
    
    if [ -n "$git_name" ] && [ -n "$git_email" ]; then
        git config --global user.name "$git_name"
        git config --global user.email "$git_email"
        git config --global init.defaultBranch main
        git config --global pull.rebase false
        
        print_success "Configuration Git enregistrée"
        GIT_CONFIGURED=true
        return 0
    else
        print_error "Configuration Git incomplète"
        return 1
    fi
}

# Vérification des clés SSH
check_ssh_keys() {
    print_info "Vérification des clés SSH..."
    
    # Vérifier différents types de clés SSH
    local ssh_keys_found=false
    
    # Vérifier les clés RSA
    if [ -f ~/.ssh/id_rsa ] && [ -f ~/.ssh/id_rsa.pub ]; then
        SSH_KEYS_EXIST=true
        print_success "Clés SSH RSA trouvées"
        ssh_keys_found=true
    fi
    
    # Vérifier les clés ED25519
    if [ -f ~/.ssh/id_ed25519 ] && [ -f ~/.ssh/id_ed25519.pub ]; then
        SSH_KEYS_EXIST=true
        print_success "Clés SSH ED25519 trouvées"
        ssh_keys_found=true
    fi
    
    # Vérifier les clés ECDSA
    if [ -f ~/.ssh/id_ecdsa ] && [ -f ~/.ssh/id_ecdsa.pub ]; then
        SSH_KEYS_EXIST=true
        print_success "Clés SSH ECDSA trouvées"
        ssh_keys_found=true
    fi
    
    # Vérifier s'il y a des clés dans le répertoire SSH (plus robuste)
    if [ -d ~/.ssh ]; then
        local pub_keys=$(find ~/.ssh -name "*.pub" -type f 2>/dev/null)
        if [ -n "$pub_keys" ]; then
            SSH_KEYS_EXIST=true
            print_success "Clés SSH trouvées dans ~/.ssh/"
            echo -e "${CYAN}Clés disponibles:${NC}"
            echo "$pub_keys" | while read -r key; do
                echo -e "${WHITE}$(basename "$key"):${NC}"
                cat "$key"
                echo ""
            done
            ssh_keys_found=true
        fi
    fi
    
    if [ "$ssh_keys_found" = false ]; then
        SSH_KEYS_EXIST=false
        print_warning "Aucune clé SSH trouvée"
        return 1
    else
        return 0
    fi
}

# Génération des clés SSH
generate_ssh_keys() {
    print_info "Génération des clés SSH..."
    
    echo -e "${CYAN}Génération d'une nouvelle paire de clés SSH...${NC}"
    read -r -p "Email pour la clé SSH: " ssh_email
    
    if [ -n "$ssh_email" ]; then
        ssh-keygen -t rsa -b 4096 -C "$ssh_email" -f ~/.ssh/id_rsa -N ""
        
        if [ $? -eq 0 ]; then
            print_success "Clés SSH générées avec succès"
            SSH_KEYS_EXIST=true
            
            # Afficher la clé publique
            echo -e "\n${CYAN}Votre clé publique SSH:${NC}"
            echo -e "${YELLOW}Copiez cette clé et ajoutez-la à votre compte GitHub:${NC}"
            echo -e "${WHITE}$(cat ~/.ssh/id_rsa.pub)${NC}"
            
            return 0
        else
            print_error "Erreur lors de la génération des clés SSH"
            return 1
        fi
    else
        print_error "Email requis pour la génération des clés SSH"
        return 1
    fi
}

# Test de connexion GitHub
test_github_connection() {
    print_info "Test de connexion GitHub..."
    
    # Test SSH (plus robuste)
    local ssh_test_output
    ssh_test_output=$(ssh -T git@github.com 2>&1)
    if echo "$ssh_test_output" | grep -q "successfully authenticated"; then
        GITHUB_CONNECTED=true
        print_success "Connexion GitHub SSH réussie"
        return 0
    elif echo "$ssh_test_output" | grep -q "Permission denied"; then
        print_warning "Clés SSH présentes mais non configurées sur GitHub"
    fi
    
    # Test HTTPS avec credential helper
    local helper=$(git config --global credential.helper 2>/dev/null)
    if [ -n "$helper" ]; then
        GITHUB_CONNECTED=true
        print_success "Connexion GitHub HTTPS configurée (credential helper: $helper)"
        return 0
    fi
    
    # Vérifier si on peut accéder à l'API GitHub (test de connectivité)
    if curl -s --max-time 10 https://api.github.com >/dev/null 2>&1; then
        print_success "Connectivité GitHub API disponible"
        print_warning "Authentification GitHub non configurée (utilisez HTTPS ou configurez SSH)"
        return 0
    else
        print_error "Aucune connectivité GitHub détectée"
        return 1
    fi
}

# Assistant de configuration GitHub complet
github_setup_wizard() {
    print_title "Assistant de Configuration GitHub"
    
    # Vérifier la configuration Git
    if ! check_git_config; then
        if ask_confirmation "Voulez-vous configurer Git maintenant ?"; then
            setup_git_config
        fi
    fi
    
    # Vérifier les clés SSH
    if ! check_ssh_keys; then
        echo -e "${CYAN}Options d'authentification GitHub:${NC}"
        echo -e "1. ${YELLOW}Générer une clé SSH (recommandé)${NC}"
        echo -e "2. ${YELLOW}Configurer l'authentification HTTPS${NC}"
        echo -e "3. ${YELLOW}Passer cette étape${NC}"
        
        read -r -p "Choisissez une option (1-3): " auth_choice
        
        case $auth_choice in
            1)
                generate_ssh_keys
                ;;
            2)
                print_info "Configuration de l'authentification HTTPS..."
                git config --global credential.helper store
                print_success "Credential helper configuré pour HTTPS"
                print_info "Lors du prochain push/pull, entrez vos identifiants GitHub"
                ;;
            3)
                print_warning "Étape d'authentification ignorée"
                ;;
            *)
                print_error "Option invalide"
                ;;
        esac
    fi
    
    # Tester la connexion GitHub
    if ! test_github_connection; then
        print_warning "La connexion GitHub nécessite une configuration."
        
        if [ "$SSH_KEYS_EXIST" = true ]; then
            echo -e "${CYAN}Pour configurer SSH avec GitHub:${NC}"
            echo -e "1. ${YELLOW}Allez sur GitHub.com${NC}"
            echo -e "2. ${YELLOW}Cliquez sur votre avatar → Settings${NC}"
            echo -e "3. ${YELLOW}SSH and GPG keys → New SSH key${NC}"
            echo -e "4. ${YELLOW}Copiez votre clé publique:${NC}"
            
            # Afficher la première clé publique trouvée
            local pub_keys=$(find ~/.ssh -name "*.pub" -type f 2>/dev/null)
            if [ -n "$pub_keys" ]; then
                local first_key=$(echo "$pub_keys" | head -1)
                echo -e "${WHITE}$(cat "$first_key")${NC}"
                echo -e "${CYAN}Ou utilisez une autre clé disponible:${NC}"
                echo "$pub_keys" | while read -r key; do
                    echo -e "${WHITE}$(basename "$key")${NC}"
                done
            else
                echo -e "${RED}Aucune clé publique trouvée${NC}"
            fi
            
            echo -e "5. ${YELLOW}Collez la clé et sauvegardez${NC}"
        else
            echo -e "${CYAN}Pour configurer HTTPS avec GitHub:${NC}"
            echo -e "1. ${YELLOW}Utilisez vos identifiants GitHub lors du prochain push/pull${NC}"
            echo -e "2. ${YELLOW}Ou configurez un token d'accès personnel${NC}"
        fi
        
        if ask_confirmation "Voulez-vous tester à nouveau la connexion ?"; then
            test_github_connection
        fi
    fi
    
    # Configuration du credential helper si pas déjà fait
    if [ "$GITHUB_CONNECTED" = true ] && ! git config --global credential.helper >/dev/null 2>&1; then
        print_info "Configuration du credential helper..."
        git config --global credential.helper store
        print_success "Credential helper configuré"
    fi
    
    print_success "Assistant de configuration GitHub terminé"
    wait_for_user
}

# ======================
# Section 5: Menu principal amélioré
# ======================

# Affichage du menu principal
afficher_menu() {
    clear
    echo -e "${CYAN}"
    echo "  ███╗   ███╗██╗   ██╗████████╗ ██████╗  ██████╗ ██╗     ███████╗"
    echo "  ████╗ ████║╚██╗ ██╔╝╚══██╔══╝██╔═══██╗██╔═══██╗██║     ██╔════╝"
    echo "  ██╔████╔██║ ╚████╔╝    ██║   ██║   ██║██║   ██║██║     ███████╗"
    echo "  ██║╚██╔╝██║  ╚██╔╝     ██║   ██║   ██║██║   ██║██║     ╚════██║"
    echo "  ██║ ╚═╝ ██║   ██║      ██║   ╚██████╔╝╚██████╔╝███████╗███████║"
    echo "  ╚═╝     ╚═╝   ╚═╝      ╚═╝    ╚═════╝  ╚═════╝ ╚══════╝╚══════╝"
    echo -e "${NC}"
    echo -e "${WHITE}Version: ${YELLOW}$SCRIPT_VERSION${NC}"
    echo -e "${WHITE}================================================${NC}"
    
    # Affichage du statut système
    echo -e "\n${CYAN}Statut du système:${NC}"
    echo -e "  ${SUDO_AVAILABLE:+${CHECK_MARK}}${SUDO_AVAILABLE:-${CROSS_MARK}} ${WHITE}Sudo${NC}"
    echo -e "  ${GIT_CONFIGURED:+${CHECK_MARK}}${GIT_CONFIGURED:-${CROSS_MARK}} ${WHITE}Git${NC}"
    echo -e "  ${SSH_KEYS_EXIST:+${CHECK_MARK}}${SSH_KEYS_EXIST:-${CROSS_MARK}} ${WHITE}SSH Keys${NC}"
    echo -e "  ${GITHUB_CONNECTED:+${CHECK_MARK}}${GITHUB_CONNECTED:-${CROSS_MARK}} ${WHITE}GitHub${NC}"
    
    echo -e "\n${WHITE}Menu principal:${NC}"
    echo -e "  ${CYAN}1.${NC} ${WHITE}Assistant de configuration GitHub${NC}"
    echo -e "  ${CYAN}2.${NC} ${WHITE}Vérification de la configuration Git${NC}"
    echo -e "  ${CYAN}3.${NC} ${WHITE}Installer MySQL et Redis${NC}"
    echo -e "  ${CYAN}4.${NC} ${WHITE}Démarrer MySQL et Redis${NC}"
    echo -e "  ${CYAN}5.${NC} ${WHITE}Benchmark du système${NC}"
    echo -e "  ${CYAN}6.${NC} ${WHITE}Déployer une application Laravel${NC}"
    echo -e "  ${CYAN}7.${NC} ${WHITE}Diagnostic système complet${NC}"
    echo -e "  ${CYAN}8.${NC} ${WHITE}Diagnostic SSH détaillé${NC}"
    echo -e "  ${CYAN}9.${NC} ${WHITE}Quitter${NC}"
    echo -e "\n${WHITE}================================================${NC}"
}

# ======================
# Section 6: Fonctions existantes améliorées
# ======================

# Vérification Git améliorée
GitHealth() {
    print_title "Vérification de la Configuration Git"
    
    echo -e "${CYAN}Configuration Git globale:${NC}"
    local git_name=$(git config --global user.name 2>/dev/null)
    local git_email=$(git config --global user.email 2>/dev/null)
    
    if [ -n "$git_name" ] && [ -n "$git_email" ]; then
        print_success "Nom: $git_name"
        print_success "Email: $git_email"
    else
        print_warning "Configuration Git manquante"
    fi
    
    echo -e "\n${CYAN}URL distante du dépôt:${NC}"
    if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        git remote -v
    else
        print_warning "Vous n'êtes pas dans un dépôt Git"
    fi
    
    echo -e "\n${CYAN}Test de l'authentification SSH avec GitHub:${NC}"
    if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
        print_success "Authentification SSH réussie"
    else
        print_error "Authentification SSH échouée"
    fi
    
    echo -e "\n${CYAN}Configuration du credential helper:${NC}"
    local credential_helper=$(git config --global credential.helper)
    if [ -n "$credential_helper" ]; then
        print_success "Credential helper: $credential_helper"
        if [ "$credential_helper" = "store" ] && [ -f ~/.git-credentials ]; then
            echo -e "${CYAN}Contenu de ~/.git-credentials:${NC}"
            cat ~/.git-credentials
        fi
    else
        print_warning "Aucun credential helper configuré"
    fi
    
    wait_for_user "Appuyez sur Entrée pour continuer..."
}

# Vérification des dépendances améliorée
DependenceCheck() {
    print_title "Vérification des Dépendances"
    
    # Vérifier MySQL
    print_info "Vérification de MySQL..."
    if sudo systemctl is-active --quiet mysql; then
        print_success "MySQL est en cours d'exécution"
    else
        print_warning "MySQL n'est pas en cours d'exécution"
        if ask_confirmation "Voulez-vous démarrer MySQL ?"; then
            if sudo systemctl start mysql; then
                print_success "MySQL démarré avec succès"
            else
                print_error "Impossible de démarrer MySQL"
            fi
        fi
    fi
    
    # Vérifier Redis
    print_info "Vérification de Redis..."
    if sudo systemctl is-active --quiet redis-server; then
        print_success "Redis est en cours d'exécution"
    else
        print_warning "Redis n'est pas en cours d'exécution"
        if ask_confirmation "Voulez-vous démarrer Redis ?"; then
            if sudo systemctl start redis-server; then
                print_success "Redis démarré avec succès"
            else
                print_error "Impossible de démarrer Redis"
            fi
        fi
    fi
    
    wait_for_user "Appuyez sur Entrée pour continuer..."
}

# Benchmark système amélioré
SysBench() {
    print_title "Benchmark du Système"
    
    # Informations système
    echo -e "${CYAN}Informations système:${NC}"
    uname -a
    
    echo -e "\n${CYAN}CPU:${NC}"
    lscpu | grep -E "Architecture|CPU\(s\)|Model name|Thread\(s\) per core|Core\(s\) per socket|Socket\(s\)|Vendor ID|Hypervisor vendor|Virtualization type|Flags"
    
    echo -e "\n${CYAN}Mémoire:${NC}"
    free -h
    
    echo -e "\n${CYAN}Disque:${NC}"
    df -h
    
    # Test de vitesse du disque
    echo -e "\n${CYAN}Test de vitesse du disque:${NC}"
    if command_exists dd; then
        print_info "Test d'écriture en cours..."
        DISK_SPEED=$(dd if=/dev/zero of=testfile bs=1G count=1 oflag=dsync 2>&1 | grep -o '[0-9.]* MB/s')
        rm -f testfile
        print_success "Vitesse d'écriture: $DISK_SPEED"
    else
        print_warning "dd non disponible pour le test de disque"
    fi
    
    # Test CPU avec sysbench
    echo -e "\n${CYAN}Test CPU:${NC}"
    if command_exists sysbench; then
        print_info "Test CPU en cours..."
        sysbench --test=cpu --cpu-max-prime=20000 run | grep -E "total time:|events per second:|min:|avg:|max:|95th percentile:"
    else
        print_warning "sysbench non installé"
        if ask_confirmation "Voulez-vous installer sysbench ?"; then
            sudo apt update && sudo apt install -y sysbench
            if command_exists sysbench; then
                print_success "sysbench installé"
                sysbench --test=cpu --cpu-max-prime=20000 run | grep -E "total time:|events per second:|min:|avg:|max:|95th percentile:"
            fi
        fi
    fi
    
    # Test réseau
    echo -e "\n${CYAN}Test réseau:${NC}"
    if command_exists speedtest-cli; then
        print_info "Test de vitesse réseau en cours..."
        speedtest-cli --simple
    else
        print_warning "speedtest-cli non installé"
        if ask_confirmation "Voulez-vous installer speedtest-cli ?"; then
            sudo apt update && sudo apt install -y speedtest-cli
            if command_exists speedtest-cli; then
                print_success "speedtest-cli installé"
                speedtest-cli --simple
            fi
        fi
    fi
    
    # Configuration réseau
    echo -e "\n${CYAN}Configuration réseau:${NC}"
    echo -e "${WHITE}IPv4:${NC}"
    ip a | grep "inet " | grep -v "127.0.0.1"
    echo -e "${WHITE}IPv6:${NC}"
    ip a | grep "inet6 " | grep -v "::1"
    
    wait_for_user "Appuyez sur Entrée pour continuer..."
}

# Installation MySQL et Redis améliorée
installer_mysql_redis() {
    print_title "Installation MySQL et Redis"
    
    if [ "$SUDO_AVAILABLE" = false ]; then
        print_error "Droits sudo requis pour cette opération"
        wait_for_user
        return 1
    fi
    
    # Mise à jour des paquets
    print_info "Mise à jour des paquets..."
    sudo apt update
    
    # Installation MySQL
    print_info "Installation de MySQL Server..."
    if sudo apt install -y mysql-server; then
        print_success "MySQL Server installé"
        
        # Configuration MySQL
        print_info "Configuration de MySQL..."
        sudo mysql -e "CREATE USER IF NOT EXISTS '$MYSQL_USER'@'localhost' IDENTIFIED BY '$MYSQL_PASSWORD';"
        sudo mysql -e "GRANT ALL PRIVILEGES ON *.* TO '$MYSQL_USER'@'localhost' WITH GRANT OPTION;"
        sudo mysql -e "FLUSH PRIVILEGES;"
        
        # Test de connexion
        if mysql -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" -e "SELECT 1;" >/dev/null 2>&1; then
            print_success "Utilisateur MySQL créé et testé"
            echo -e "${CYAN}Informations MySQL:${NC}"
            printf "%-20s | %-20s\n" "Utilisateur" "Mot de passe"
            printf "%-20s | %-20s\n" "--------------------" "--------------------"
            printf "%-20s | %-20s\n" "$MYSQL_USER" "$MYSQL_PASSWORD"
        else
            print_error "Erreur lors de la création de l'utilisateur MySQL"
        fi
    else
        print_error "Erreur lors de l'installation de MySQL"
        wait_for_user
        return 1
    fi
    
    # Installation Redis
    print_info "Installation de Redis Server..."
    if sudo apt install -y redis-server; then
        print_success "Redis Server installé"
        
        # Configuration Redis
        sudo systemctl enable redis-server
        sudo systemctl start redis-server
        
        if sudo systemctl is-active --quiet redis-server; then
            print_success "Redis démarré et configuré"
        else
            print_error "Erreur lors du démarrage de Redis"
        fi
    else
        print_error "Erreur lors de l'installation de Redis"
        wait_for_user
        return 1
    fi
    
    print_success "Installation MySQL et Redis terminée"
    wait_for_user
}

# Déploiement Laravel amélioré
InitLaraProject() {
    print_title "Déploiement Application Laravel"
    
    if [ "$GITHUB_CONNECTED" = false ]; then
        print_warning "GitHub non connecté. Utilisation de HTTPS pour le clonage."
    fi
    
    read -r -p "URL du dépôt GitHub: " github_url
    read -r -p "Nom du dossier de destination: " destination_folder
    
    if [ -z "$github_url" ] || [ -z "$destination_folder" ]; then
        print_error "URL et nom de dossier requis"
        wait_for_user
        return 1
    fi
    
    # Vérifier si le dossier existe
    if [ -d "$destination_folder" ]; then
        if ask_confirmation "Le dossier $destination_folder existe. Voulez-vous le supprimer ?"; then
            rm -rf "$destination_folder"
            print_success "Dossier supprimé"
        else
            print_error "Opération annulée"
            wait_for_user
            return 1
        fi
    fi
    
    # Cloner le dépôt
    print_info "Clonage du dépôt..."
    if git clone "$github_url" "$destination_folder"; then
        print_success "Dépôt cloné"
        cd "$destination_folder" || return 1
    else
        print_error "Erreur lors du clonage"
        wait_for_user
        return 1
    fi
    
    # Copier .env
    if [ -f ".env.example" ]; then
        cp .env.example .env
        print_success "Fichier .env créé"
    fi
    
    # Installation Composer
    if [ -f "composer.json" ]; then
        print_info "Installation des dépendances Composer..."
        if composer install --no-interaction; then
            print_success "Dépendances Composer installées"
        else
            print_error "Erreur lors de l'installation Composer"
            wait_for_user
            return 1
        fi
    fi
    
    # Installation npm
    if [ -f "package.json" ]; then
        print_info "Installation des dépendances npm..."
        if npm install; then
            print_success "Dépendances npm installées"
        else
            print_error "Erreur lors de l'installation npm"
            wait_for_user
            return 1
        fi
    fi
    
    # Générer la clé d'application
    if command_exists php; then
        print_info "Génération de la clé d'application..."
        php artisan key:generate
    fi
    
    # Migrations
    print_info "Exécution des migrations..."
    if php artisan migrate; then
        print_success "Migrations exécutées"
    else
        print_warning "Erreur lors des migrations"
    fi
    
    # Optimisation
    print_info "Optimisation de l'application..."
    if php artisan optimize; then
        print_success "Application optimisée"
    fi
    
    print_success "Déploiement Laravel terminé"
    wait_for_user
}

# Diagnostic système complet
diagnostic_systeme() {
    print_title "Diagnostic Système Complet"
    
    echo -e "${CYAN}Informations système:${NC}"
    echo -e "${WHITE}OS:${NC} $(lsb_release -d | cut -f2)"
    echo -e "${WHITE}Kernel:${NC} $(uname -r)"
    echo -e "${WHITE}Architecture:${NC} $(uname -m)"
    echo -e "${WHITE}Uptime:${NC} $(uptime -p)"
    
    echo -e "\n${CYAN}Utilisation des ressources:${NC}"
    echo -e "${WHITE}CPU:${NC}"
    top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1
    echo -e "${WHITE}Mémoire:${NC}"
    free -h | grep "Mem:"
    echo -e "${WHITE}Disque:${NC}"
    df -h / | tail -1
    
    echo -e "\n${CYAN}Services en cours:${NC}"
    local services=("mysql" "redis-server" "nginx" "apache2")
    for service in "${services[@]}"; do
        if sudo systemctl is-active --quiet "$service"; then
            print_success "$service: Actif"
        else
            print_warning "$service: Inactif"
        fi
    done
    
    echo -e "\n${CYAN}Ports ouverts:${NC}"
    if command_exists netstat; then
        netstat -tlnp | grep LISTEN
    elif command_exists ss; then
        ss -tlnp
    fi
    
    wait_for_user "Appuyez sur Entrée pour continuer..."
}

# ======================
# Section 7: Boucle principale
# ======================

# Initialisation
main() {
    # Créer le fichier de log
    touch "$LOG_FILE"
    
    print_title "Initialisation de MyTools"
    
    # Vérifications initiales
    check_sudo_rights
    check_internet_connection
    check_system_requirements
    
    # Vérifications Git/GitHub
    check_git_config
    check_ssh_keys
    test_github_connection
    
    # Boucle principale
    while true; do
        afficher_menu
        read -r -p "Choisissez une option: " choix
        
        case $choix in
            1) github_setup_wizard ;;
            2) GitHealth ;;
            3) installer_mysql_redis ;;
            4) DependenceCheck ;;
            5) SysBench ;;
            6) InitLaraProject ;;
            7) diagnostic_systeme ;;
            8) diagnostic_ssh ;;
            9)
                print_success "Au revoir !"
                exit 0
                ;;
            *)
                print_error "Choix invalide. Veuillez choisir une option valide."
                sleep 2
                ;;
        esac
    done
}

# Exécution du script
main "$@"