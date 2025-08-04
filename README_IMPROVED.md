# 🚀 MyTools - Version Améliorée

Un outil complet de configuration et déploiement pour serveurs Linux avec une interface utilisateur moderne et des fonctionnalités avancées.

## ✨ Nouvelles Fonctionnalités

### 🔧 Assistant de Configuration GitHub
- **Configuration automatique de Git** : Nom d'utilisateur, email, branche par défaut
- **Génération de clés SSH** : Création automatique de clés RSA 4096 bits
- **Test de connexion GitHub** : Vérification de l'authentification SSH
- **Guide interactif** : Instructions étape par étape pour configurer GitHub
- **Credential helper** : Configuration automatique du stockage des identifiants

### 🛡️ Vérifications de Sécurité
- **Droits sudo** : Vérification et demande automatique des privilèges
- **Connectivité internet** : Test de la connexion réseau
- **Prérequis système** : Installation automatique des paquets manquants
- **État des services** : Monitoring en temps réel

### 📊 Interface Utilisateur Améliorée
- **Interface colorée** : Utilisation de couleurs et emojis pour une meilleure lisibilité
- **Statut en temps réel** : Affichage de l'état du système (Sudo, Git, SSH, GitHub)
- **Logs détaillés** : Enregistrement de toutes les opérations dans `/tmp/mytools.log`
- **Messages contextuels** : Informations adaptées à l'état du système

### 🔍 Diagnostic Système Complet
- **Informations système** : OS, kernel, architecture, uptime
- **Utilisation des ressources** : CPU, mémoire, disque
- **Services actifs** : MySQL, Redis, Nginx, Apache
- **Ports ouverts** : Liste des ports en écoute

## 🚀 Installation

```bash
# Rendre le script exécutable
chmod +x myTools_improved.sh

# Lancer le script
./myTools_improved.sh
```

## 📋 Prérequis

Le script vérifie et installe automatiquement :
- `curl` - Téléchargement de fichiers
- `wget` - Téléchargement de fichiers
- `git` - Gestion de version
- `openssh-client` - Connexions SSH

## 🎯 Fonctionnalités Principales

### 1. Assistant de Configuration GitHub
Guide complet pour configurer Git et GitHub :
- Configuration de l'identité Git
- Génération de clés SSH
- Test de connexion GitHub
- Configuration du credential helper

### 2. Vérification de Configuration Git
- Configuration Git globale
- URL des dépôts distants
- Test d'authentification SSH
- Configuration du credential helper

### 3. Installation MySQL et Redis
- Installation automatique des serveurs
- Configuration des utilisateurs MySQL
- Démarrage et activation des services
- Test de connexion

### 4. Gestion des Services
- Vérification du statut des services
- Démarrage automatique si nécessaire
- Monitoring en temps réel

### 5. Benchmark Système
- Informations CPU détaillées
- Test de vitesse du disque
- Benchmark CPU avec sysbench
- Test de vitesse réseau
- Configuration réseau IPv4/IPv6

### 6. Déploiement Laravel
- Clonage de dépôts GitHub
- Installation des dépendances (Composer/npm)
- Configuration de l'environnement
- Exécution des migrations
- Optimisation de l'application

### 7. Diagnostic Système
- Informations système complètes
- Utilisation des ressources
- État des services
- Ports ouverts

## ⚙️ Configuration

### Variables MySQL
Modifiez les lignes 35-36 dans le script :
```bash
MYSQL_USER="user"
MYSQL_PASSWORD="MyUserPassword"
```

### Fichier de Log
Les logs sont sauvegardés dans `/tmp/mytools.log` par défaut.
Modifiez la variable `LOG_FILE` pour changer l'emplacement.

## 🔧 Utilisation

### Premier Lancement
1. Lancez le script : `./myTools_improved.sh`
2. Le script vérifie automatiquement les prérequis
3. Utilisez l'option 1 pour configurer GitHub
4. Suivez les instructions pour ajouter votre clé SSH à GitHub

### Configuration GitHub
1. Choisissez l'option 1 : "Assistant de configuration GitHub"
2. Entrez votre nom d'utilisateur et email Git
3. Générez une clé SSH si nécessaire
4. Copiez la clé publique affichée
5. Ajoutez-la à votre compte GitHub (Settings → SSH and GPG keys)
6. Testez la connexion

### Déploiement Laravel
1. Assurez-vous que GitHub est configuré
2. Choisissez l'option 6 : "Déployer une application Laravel"
3. Entrez l'URL du dépôt GitHub
4. Spécifiez le dossier de destination
5. Le script clone et configure automatiquement l'application

## 🐛 Dépannage

### Problèmes de Connexion GitHub
```bash
# Vérifier les clés SSH
ls -la ~/.ssh/

# Tester la connexion manuellement
ssh -T git@github.com

# Régénérer les clés si nécessaire
rm ~/.ssh/id_rsa*
ssh-keygen -t rsa -b 4096 -C "votre-email@example.com"
```

### Problèmes MySQL
```bash
# Vérifier le statut du service
sudo systemctl status mysql

# Redémarrer le service
sudo systemctl restart mysql

# Vérifier les logs
sudo journalctl -u mysql
```

### Problèmes Redis
```bash
# Vérifier le statut du service
sudo systemctl status redis-server

# Redémarrer le service
sudo systemctl restart redis-server

# Vérifier les logs
sudo journalctl -u redis-server
```

## 📝 Logs

Toutes les opérations sont enregistrées dans `/tmp/mytools.log` avec :
- Horodatage
- Niveau de log (SUCCESS, ERROR, WARNING, INFO)
- Message détaillé

## 🔒 Sécurité

- Vérification des droits sudo avant les opérations sensibles
- Utilisation de clés SSH pour l'authentification GitHub
- Stockage sécurisé des identifiants Git
- Validation des entrées utilisateur

## 🤝 Contribution

Pour améliorer le script :
1. Fork le projet
2. Créez une branche pour votre fonctionnalité
3. Committez vos changements
4. Poussez vers la branche
5. Ouvrez une Pull Request

## 📄 Licence

Ce projet est sous licence MIT. Voir le fichier `LICENSE` pour plus de détails.

## 🆘 Support

En cas de problème :
1. Vérifiez les logs dans `/tmp/mytools.log`
2. Consultez la section dépannage
3. Vérifiez que tous les prérequis sont installés
4. Assurez-vous d'avoir les droits sudo

---

**Version :** 2.0.0  
**Dernière mise à jour :** $(date)  
**Auteur :** Assistant IA