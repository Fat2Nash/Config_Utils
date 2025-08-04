#!/bin/bash

# Test de la fonction wait_for_user
CYAN='\033[0;36m'
NC='\033[0m'

# Fonction pour attendre l'utilisateur
wait_for_user() {
    local message=${1:-"Appuyez sur Entrée pour revenir au menu principal..."}
    echo -e "\n${CYAN}$message${NC}"
    read -r
}

echo "Test de la fonction wait_for_user"
echo "Cette fonction attend que vous appuyiez sur Entrée avant de continuer"

wait_for_user "Appuyez sur Entrée pour continuer le test..."

echo "Test réussi ! La fonction fonctionne correctement."
wait_for_user