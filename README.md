<h1 align="center" >Config Utils</h1>
Certaine commande nécessite  des accès en mode **sudo**  

Exécuter le Script : 
```sh
./myTools.sh
```

Modifier les ligne 18 et 19 pour la création de l'utilisateur MySQL personnaliser : 

```bash
# Définition des variables pour le nom d'utilisateur et le mot de passe MySQL
MYSQL_USER="user"

MYSQL_PASSWORD="MyUserPassword"
```

Fonctionnalité  : 
- [/] Vérifier Configuration Git
- [/] Installer MySQL et redis-server
- [/] Démarrer MySQL et redis
- [/] Benchmark du système (problème test latence réseaux, le reste fonctionne )
- 🚧 Cloner et optimiser une application Laravel  (quelque correctif a modifier )
