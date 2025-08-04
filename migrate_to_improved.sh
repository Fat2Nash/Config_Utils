#!/bin/bash

# ======================
# Script de Migration vers MyTools Amélioré
# ======================

# Couleurs
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Migration vers MyTools Amélioré v2.0${NC}"
echo -e "${BLUE}========================================${NC}"

# Vérifier si l'ancien script existe
if [ ! -f "myTools.sh" ]; then
    echo -e "${RED}❌ Fichier myTools.sh non trouvé${NC}"
    echo -e "${YELLOW}Assurez-vous d'être dans le bon répertoire${NC}"
    exit 1
fi

# Sauvegarder l'ancien script
echo -e "${BLUE}📦 Sauvegarde de l'ancien script...${NC}"
cp myTools.sh myTools_backup_$(date +%Y%m%d_%H%M%S).sh
echo -e "${GREEN}✅ Sauvegarde créée${NC}"

# Vérifier si le nouveau script existe
if [ ! -f "myTools_improved.sh" ]; then
    echo -e "${RED}❌ Fichier myTools_improved.sh non trouvé${NC}"
    echo -e "${YELLOW}Assurez-vous que le script amélioré est présent${NC}"
    exit 1
fi

# Rendre le nouveau script exécutable
echo -e "${BLUE}🔧 Configuration des permissions...${NC}"
chmod +x myTools_improved.sh
echo -e "${GREEN}✅ Permissions configurées${NC}"

# Créer un lien symbolique pour la compatibilité
echo -e "${BLUE}🔗 Création d'un lien symbolique...${NC}"
if [ -L "myTools.sh" ]; then
    rm myTools.sh
fi
ln -sf myTools_improved.sh myTools.sh
echo -e "${GREEN}✅ Lien symbolique créé${NC}"

# Afficher les différences principales
echo -e "\n${BLUE}📋 Nouvelles fonctionnalités disponibles:${NC}"
echo -e "${GREEN}✅ Assistant de configuration GitHub${NC}"
echo -e "${GREEN}✅ Vérification automatique des droits sudo${NC}"
echo -e "${GREEN}✅ Interface utilisateur améliorée avec couleurs${NC}"
echo -e "${GREEN}✅ Logs détaillés dans /tmp/mytools.log${NC}"
echo -e "${GREEN}✅ Diagnostic système complet${NC}"
echo -e "${GREEN}✅ Gestion d'erreurs robuste${NC}"
echo -e "${GREEN}✅ Vérifications de sécurité${NC}"

echo -e "\n${BLUE}🚀 Migration terminée !${NC}"
echo -e "${YELLOW}Vous pouvez maintenant utiliser:${NC}"
echo -e "  ${GREEN}./myTools.sh${NC} (lien vers la version améliorée)"
echo -e "  ${GREEN}./myTools_improved.sh${NC} (version améliorée directe)"
echo -e "\n${BLUE}📖 Consultez README_IMPROVED.md pour plus d'informations${NC}"