#!/bin/bash

# ======================
# Section 1: Configuration & Menu principal
# ======================

# Définir des couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
CHECK_MARK="✅"
CROSS_MARK="❌"
WARNING_MARK="⚠️"

# Définition des variables pour le nom d'utilisateur et le mot de passe MySQL
MYSQL_USER="user"
MYSQL_PASSWORD="MyUserPassword"

# Fonction pour afficher le menu
afficher_menu() {
    clear
    echo "  ______                 ___  _           _     _        _  _       
 / _____)               / __)(_)         | |   | | _    (_)| |      
| /        ___   ____  | |__  _   ____   | |   | || |_   _ | |  ___ 
| |       / _ \ |  _ \ |  __)| | / _  |  | |   | ||  _) | || | /___)
| \_____ | |_| || | | || |   | |( ( | |  | |___| || |__ | || ||___ |
 \______) \___/ |_| |_||_|   |_| \_|| |   \______| \___)|_||_|(___/ 
                                (_____|                             "

    echo "Menu"
    echo "1. Verification de la configuration Git"
    echo "2. Installer MySQL et Redis"
    echo "3. Démarrer MySQL et Redis"
    echo "4. Benchmark du système"
    echo "5. Deployer une application Laravel 11"
    echo "6. Quitter"
}

function OptionIvalid() {
    echo -e "${CROSS_MARK} ${RED}Choix invalide.${NC} Veuillez choisir une option valide."
    afficher_menu
}

# ======================
# Section 2: Fonction GitHealth
# description: Vérifie la configuration Git globale, l'URL distante du dépôt, l'authentification SSH avec GitHub et le credential.helper.
# ======================

GitHealth() {
    clear
    echo "=== Vérification de la configuration Git globale ==="
    git config --global --list | grep 'user.name\|user.email'

    # Vérifier si nous sommes dans un dépôt Git
    if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        echo "=== URL distante configurée pour le dépôt ==="
        git remote -v
    else
        echo "=== Vous n'êtes pas dans un dépôt Git ==="
    fi

    echo "=== Test de l'authentification SSH avec GitHub ==="
    ssh -T git@github.com

    echo "=== Configuration du credential.helper ==="
    git config --global credential.helper

    if [[ $(git config --global credential.helper) == "store" ]]; then
        echo "=== Contenu de ~/.git-credentials ==="
        cat ~/.git-credentials
    elif [[ $(git config --global credential.helper) == "cache" ]]; then
        echo "Credential helper is set to cache. No file to display."
    else
        echo -e " ${CROSS_MARK} ${RED}No credential helper set.${NC}"
    fi
    read -r -p "Appuyez sur Entrée pour continuer..."
}

# ======================
# Section 3: DépendenceCheck
# description: Verifie si MySQL et Redis sont en cours d'exécution et les démarre si ce n'est pas le cas.
# ======================

DependenceCheck() {
    clear

    # Vérifier si MySQL est en cours d'exécution
    if sudo /etc/init.d/mysql status >/dev/null; then
        echo -e " ⚙️ ${GREEN}MySQL est déjà en cours d'exécution.${NC}"
    else
        echo -e "${WARNING_MARK}MySQL n'est pas en cours d'exécution. Tentative de démarrage...${NC}"
        if ! sudo /etc/init.d/mysql start >/dev/null; then
            echo -e " ${CROSS_MARK} ${RED}Impossible de démarrer MySQL.${NC} Veuillez vérifier les journaux pour plus d'informations."
        else
            echo -e "${CHECK_MARK} ${BLUE}MySQL${NC} a été démarré avec succès."
        fi
    fi

    # Vérifier si Redis est en cours d'exécution
    if sudo /etc/init.d/redis-server status >/dev/null; then
        echo -e " ⚙️ ${GREEN}Redis est déjà en cours d'exécution.${NC}"
    else
        echo -e "${WARNING_MARK} Redis n'est pas en cours d'exécution. Tentative de démarrage..."
        if ! sudo /etc/init.d/redis-server start >/dev/null; then
            echo -e " ${CROSS_MARK} ${RED}Impossible de démarrer Redis.${NC} Veuillez vérifier les journaux pour plus d'informations."
        else
            echo -e " ${CHECK_MARK} ${BLUE}Redis${NC} a été démarré avec succès."
        fi
    fi

    read -r -p "Appuyez sur Entrée pour continuer..."
}

# ======================
# Section 4: SysBench
# description: Vérifie les informations système, les performances CPU, la vitesse du disque, la vitesse du réseau et la configuration du réseau.
# ======================

SysBench() {
    clear
    # Fonction pour afficher une section avec un titre
    print_section() {
        echo
        echo "=== $1 ==="
        echo "-----------------------------------"
    }

    # Vérifier les informations du système
    print_section "Informations sur le système"
    uname -a

    # Vérifier les informations CPU
    print_section "Informations CPU"
    lscpu | grep -E "Architecture|CPU\(s\)|Model name|Thread\(s\) per core|Core\(s\) per socket|Socket\(s\)|Vendor ID|Hypervisor vendor|Virtualization type|Flags"

    # Vérifier la mémoire
    print_section "Informations sur la mémoire"
    free -h

    # Vérifier l'utilisation du disque
    print_section "Utilisation du disque"
    df -h

    # Tester la vitesse du disque
    print_section "Benchmark du disque"
    DISK_SPEED=$(dd if=/dev/zero of=testfile bs=1G count=1 oflag=dsync 2>&1 | grep -o '[0-9.]* MB/s')
    rm testfile
    echo "Vitesse d'écriture : $DISK_SPEED"

    # Tester les performances CPU avec sysbench
    print_section "Benchmark CPU"
    if ! command -v sysbench &>/dev/null; then
        echo "sysbench n'est pas installé. Installation de sysbench..."
        sudo apt-get update
        sudo apt-get install -y sysbench
    fi
    sysbench --test=cpu --cpu-max-prime=20000 run | grep -E "total time:|events per second:|min:|avg:|max:|95th percentile:"

    # Tester la vitesse du réseau
    print_section "Benchmark de la vitesse du réseau"
    if ! command -v speedtest-cli &>/dev/null; then
        echo "speedtest-cli n'est pas installé. Installation de speedtest-cli..."
        sudo apt-get update
        sudo apt-get install -y speedtest-cli
    fi
    speedtest-cli --simple

    # Configuration du réseau ipv4 et ipv6
    print_section "Configuration du réseau"
    ip a | grep "inet "  # Afficher l'adresse IP de l'interface réseau ipv4
    ip a | grep "inet6 " # Afficher l'adresse IP de l'interface réseau ipv6

    print_section "Benchmark terminé"
    read -r -p "Appuyez sur Entrée pour continuer..."
}

# ======================
# Section 5: InitLaraProject
# description: Clone un dépôt GitHub d'une application Laravel, installe les dépendances Composer et npm, exécute les migrations de la base de données et optimise l'application Laravel.
# ======================

InitLaraProject() {
    clear
    read -r -p "Entrez l'URL du dépôt GitHub de l'application Laravel : " github_url
    read -r -p "Entrez le nom du dossier de destination pour l'application : " destination_folder

    # Vérifier si le dossier de destination existe déjà
    if [ -d "$destination_folder" ]; then
        echo -e "${WARNING_MARK} ${YELLOW}Le dossier de destination $destination_folder existe déjà. Voulez-vous le supprimer ? (o/n)${NC}"
        read -r -p "Votre choix : " choice
        if [ "$choice" = "o" ] || [ "$choice" = "O" ]; then
            rm -rf "$destination_folder"
            if [ $? -eq 0 ]; then
                echo -e "${CHECK_MARK} ${GREEN}Le dossier $destination_folder a été supprimé avec succès.${NC}"
            else
                echo -e "${CROSS_MARK} ${RED}Impossible de supprimer le dossier $destination_folder.${NC}"
                read -r -p "Appuyez sur Entrée pour revenir au menu principal..."
                menu_principal
                return
            fi
        else
            echo -e "${CROSS_MARK} ${RED}Opération annulée.${NC}"
            read -r -p "Appuyez sur Entrée pour revenir au menu principal..."
            menu_principal
            return
        fi
    fi

    # Cloner le dépôt GitHub dans le dossier de destination
    git clone "$github_url" "$destination_folder"

    # Vérifier si le clonage s'est bien passé
    if [ $? -eq 0 ]; then
        echo -e "${CHECK_MARK} ${GREEN}L'application Laravel a été clonée avec succès depuis $github_url dans le dossier $destination_folder.${NC}"
    else
        echo -e "${CROSS_MARK} ${RED}Une erreur s'est produite lors du clonage de l'application Laravel depuis $github_url.${NC}"
        read -r -p "Appuyez sur Entrée pour revenir au menu principal..."
        menu_principal
        return
    fi

    # Se déplacer dans le dossier de destination
    cd "$destination_folder" || {
        echo -e "${CROSS_MARK} ${RED}Impossible de se déplacer dans le dossier $destination_folder.${NC}"
        read -r -p "Appuyez sur Entrée pour revenir au menu principal..."
        menu_principal
        return
    }

    # Copie du fichier .env.example
    cp .env.example .env

    # Installation des dépendances avec Composer
    if [ -f "composer.json" ]; then
        echo -e "${BLUE}Installation des dépendances Composer...${NC}"
        composer update
        composer install
        if [ $? -eq 0 ]; then
            echo -e "${CHECK_MARK} ${GREEN}Dépendances Composer installées avec succès.${NC}"
        else
            echo -e "${CROSS_MARK} ${RED}Une erreur s'est produite lors de l'installation des dépendances Composer.${NC}"
            read -r -p "Appuyez sur Entrée pour revenir au menu principal..."
            menu_principal
            return
        fi
    else
        echo -e "${WARNING_MARK} ${YELLOW}Fichier composer.json non trouvé.${NC}"
    fi

    # Installation des dépendances avec npm
    if [ -f "package.json" ]; then
        echo -e "${BLUE}Installation des dépendances npm...${NC}"
        npm install
        if [ $? -eq 0 ]; then
            echo -e "${CHECK_MARK} ${GREEN}Dépendances npm installées avec succès.${NC}"
        else
            echo -e "${CROSS_MARK} ${RED}Une erreur s'est produite lors de l'installation des dépendances npm.${NC}"
            read -r -p "Appuyez sur Entrée pour revenir au menu principal..."
            menu_principal
            return
        fi
    else
        echo -e "${WARNING_MARK} ${YELLOW}Fichier package.json non trouvé.${NC}"
    fi

    # Exécution des migrations de la base de données
    echo -e "${BLUE}Exécution des migrations de la base de données...${NC}"
    php artisan migrate
    if [ $? -eq 0 ]; then
        echo -e "${CHECK_MARK} ${GREEN}Migrations exécutées avec succès.${NC}"
    else
        echo -e "${CROSS_MARK} ${RED}Une erreur s'est produite lors de l'exécution des migrations.${NC}"
        read -r -p "Appuyez sur Entrée pour revenir au menu principal..."
        menu_principal
        return
    fi

    # Optimisation de l'application Laravel
    echo -e "${BLUE}Optimisation de l'application Laravel...${NC}"
    php artisan optimize
    if [ $? -eq 0 ]; then
        echo -e "${CHECK_MARK} ${GREEN}Application Laravel optimisée avec succès.${NC}"
    else
        echo -e "${CROSS_MARK} ${RED}Une erreur s'est produite lors de l'optimisation de l'application Laravel.${NC}"
        read -r -p "Appuyez sur Entrée pour revenir au menu principal..."
        menu_principal
        return
    fi

    read -r -p "Appuyez sur Entrée pour revenir au menu principal..."
    menu_principal
}

# ======================
# Section 6: Fonction installer_mysql_redis
# description: Installe MySQL Server et Redis Server, configure MySQL et teste la connexion à MySQL.
# ======================

installer_mysql_redis() {
    clear


    # Mise à jour des paquets et installation de MySQL Server
    echo "Mise à jour des paquets..."
    sudo apt update
    echo "Installation de MySQL Server..."
    sudo apt install -y mysql-server

    # Vérification de l'installation de MySQL
    if mysql --version >/dev/null 2>&1; then
        echo -e "${CHECK_MARK} ${GREEN}MySQL Server a été installé avec succès.${NC}"
        read -r -p "Appuyez sur Entrée pour revenir au menu principal..."
    else
        echo -e "${CROSS_MARK} ${RED}Une erreur s'est produite lors de l'installation de MySQL Server.${NC}"
        read -r -p "Appuyez sur Entrée pour revenir au menu principal..."
        return
    fi

    # Vérification des permissions du répertoire et du fichier de socket MySQL
    echo "Vérification des permissions du répertoire et du fichier de socket MySQL..."
    sudo chown mysql:mysql /var/run/mysqld
    sudo chmod 755 /var/run/mysqld
    sudo chown mysql:mysql /var/run/mysqld/mysqld.sock
    sudo chmod 660 /var/run/mysqld/mysqld.sock
    sudo service mysql restart >/dev/null 2>&1
    echo -e "${CHECK_MARK} ${GREEN}Vérification des permissions effectuée avec succès.${NC}"
    read -r -p "Appuyez sur Entrée pour continuer..."

    # Configuration de MySQL Server
    echo "Configuration de MySQL Server..."
    sudo mysql -e "CREATE USER IF NOT EXISTS '$MYSQL_USER'@'localhost' IDENTIFIED BY '$MYSQL_PASSWORD';"
    sudo mysql -e "GRANT ALL PRIVILEGES ON *.* TO '$MYSQL_USER'@'localhost' WITH GRANT OPTION;"
    sudo mysql -e "FLUSH PRIVILEGES;"

    # Vérification de la création de l'utilisateur MySQL
    if sudo mysql -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" -e "exit"; then
        echo -e "${CHECK_MARK} ${GREEN}Utilisateur MySQL '$MYSQL_USER' créé avec succès.${NC}"

        # Affichage des informations sous forme de tableau
        printf "\n%-20s | %-20s\n" "Nom d'utilisateur" "Mot de passe"
        printf "%-20s | %-20s\n" "--------------------" "--------------------"
        printf "%-20s | %-20s\n" "$MYSQL_USER" "$MYSQL_PASSWORD"

        read -r -p "Appuyez sur Entrée pour continuer..."

        echo "Test de connexion à MySQL avec l'utilisateur $MYSQL_USER..."
        # if mysql -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" -e "exit"; then
        #     echo -e "${CHECK_MARK} ${GREEN}Connexion réussie à MySQL.${NC}"
        if mysql -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" -e "exit"; then
            echo -e "${CHECK_MARK} ${GREEN}Connexion réussie à MySQL.${NC}"
            read -r -p "Appuyez sur Entrée pour revenir au menu principal..."
        else
            echo -e "${CROSS_MARK} ${RED}Impossible de se connecter à MySQL.${NC}"
            read -r -p "Appuyez sur Entrée pour revenir au menu principal..."
            return
        fi
    else
        echo -e "${CROSS_MARK} ${RED}Une erreur s'est produite lors de la création de l'utilisateur MySQL.${NC}"
        read -r -p "Appuyez sur Entrée pour continuer..."
        return
    fi

    # Installation de Redis Server
    echo "Installation de Redis Server..."
    sudo apt install -y redis-server

    # Vérification de l'installation de Redis
    if redis-server --version >/dev/null 2>&1; then
        echo -e "${CHECK_MARK} ${GREEN}Redis Server a été installé avec succès.${NC}"
        read -r -p "Appuyez sur Entrée pour continuer..."
    else
        echo -e "${CROSS_MARK} ${RED}Une erreur s'est produite lors de l'installation de Redis Server.${NC}"
        read -r -p "Appuyez sur Entrée pour continuer..."
        return
    fi

    # Configuration de Redis Server (ajoutez ici vos commandes de configuration spécifiques à Redis si nécessaire)
    # Exemple de configuration Redis :
    # sudo sed -i 's/supervised no/supervised systemd/' /etc/redis/redis.conf

    # Redémarrage des services MySQL et Redis
    echo "Redémarrage des services MySQL et Redis..."
    sudo service mysql restart >/dev/null 2>&1
    echo -e "${CHECK_MARK} ${GREEN}Mysql restart avec succés ! ${NC}"
    sudo service redis-server restart >/dev/null 2>&1
    echo -e "${CHECK_MARK} ${GREEN}Redis-server Restart avec Succés ! ${NC}"

    echo -e "${CHECK_MARK} ${GREEN}Installation et configuration de MySQL et Redis terminées.${NC}"
    read -r -p "Appuyez sur Entrée pour revenir au menu principal..."
}

# Boucle principale du script
while true; do
    afficher_menu
    read -r -p "Choisissez une option : " choix
    case $choix in
    1) GitHealth ;;
    2) installer_mysql_redis ;;
    3) DependenceCheck ;;
    4) SysBench ;;
    5) InitLaraProject ;;
    6)
        echo "Au revoir !"
        exit
        ;;
    *) OptionIvalid ;;
    esac
done
