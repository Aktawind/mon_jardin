# 🌿 Sève - Notes de version

Ce fichier trace l'historique des évolutions de l'application Sève.

---

## 🔮 À Venir (Roadmap)

### v2.0.0 - "Synchronisation Cloud"

### v1.9.1 - Ajout des photo dans l'encyclopédie



---

## 🚧 En Développement


---

## ✅ Versions publiées

### v1.9.0 - "L'Esprit Tranquille" (Mode Vacances)
Sélecteur de dates de départ et de retour.
Création automatique d'une liste "Avant de partir" et d'une "Fiche Nounou" pour la personne qui vient arroser.

### v1.8.0 - "Docteur Plante" (Aide & Diagnostic)
Assistant de diagnostic interactif simple (Chatbot à choix multiples).
Identifier les problèmes courants (Feuilles jaunes, taches, nuisibles) et proposer des solutions rassurantes.
Pouvoir choisir l'heure des notifications dans les paramètres
Repousser si terre humide en prenant le potentiel retard d'arrosage en compte
Le Bouton "ajouter à mon jardin" se trouvait par dessus la section entretien dans l'encyclopédie

### v1.7.0 - "Sauvegarde et restauration"
Export de toutes vos plantes, historiques, calendriers et albums photos dans un fichier unique sécurisé (`.zip`).
Enregistrez votre sauvegarde sur votre téléphone ou envoyez-la sur votre Drive/Mail.
Changez de téléphone sans perdre une seule feuille ! La restauration remet tout en place à l'identique.

### v1.6.3 - "Correctif"
Correction regression, le pruning_months avait disparu aussi pour les fruitiers

### v1.6.2 - "Interface UI + correctif"
Correction regression, le pruning_months avait disparu
On n'affiche pas de section Calendirer vide

### v1.6.1 - "Interface UI"
Amélioration des CircleAvatar avec des icônes plutôt que des lettres

### v1.6.0 - "Encyclopédie"
**Ajout de l'écran de l'encyclopédie**
Accessible via le Drawer.
Une liste simple de toutes les plantes triée alphabétiquement.
Une barre de recherche en haut pour trouver rapidement.
Des filtres rapides : Intérieur / Extérieur / Potager.

**L'Écran de Détail**
Affichage propre de TOUTES les données du JSON
Sections : Identité, Besoins (Eau/Lumière), Sol & Culture, Calendrier théorique, Bonus (Toxicité, Rusticité...).
Bouton flottant : "Ajouter cette plante".

**Connexions**
Depuis le Drawer -> Ouvre la Liste.
Depuis le Guide d'Achat (résultat) -> Ouvre le Détail Encyclopédie.
Depuis "Ma Plante" (Menu Gestion) -> Ouvre le Détail Encyclopédie correspondant.

### v1.5.0 - "Guide d'achat + Refonte base de données"
**Le Guide d'Achat :**
Un assistant interactif pour trouver la plante idéale selon vos critères (Intérieur/Extérieur, Lumière, Animaux, Facilité...).
Recherche par esthétique (Fleur/Feuillage), forme (Suspendue/Arbre) et type de potager (Légume racine, fruitier...).
Affichage coloré et ajout direct des plantes trouvées.

**Refonte majeure de l'architecture de Données :**
Migration vers une structure à 3 fichiers (`core`, `care`, `tags`) générés depuis des CSV maîtres. Plus robuste et facile à maintenir.
Toutes les données (Lumière, Rusticité, Cycle...) sont maintenant typées pour permettre des filtres précis.
Capacité d'accueil de milliers de plantes avec gestion des synonymes.
Grosse phase de Clean Code pour supprimer tous les warnings

### v1.4.5 - "Refonte du menu principal"
Restructuration de la navigation principale pour accueillir les futures fonctionnalités.

### v1.4.4 - "Corrections de bugs et améliorations"
On peut supprimer une entrée dans l'historique via un appui long
Gestion des fuseaux horaires pour que les dates calculées soient correctes
Amélioration de la visibilité du bouton menu (3 points) sur les photos de couverture (ajout d'un fond contrasté).

### v1.4.3 - "Corrections de bug"
Les widgets calendriers sont en français.
Les plantes qui n'ont pas besoin d'arrosage en hiver (comme les cactus) ne réclament pas d'eau (si l'encyclopédie dit water_winter: 0) et sont marquées en "repos"
Le calendrier n'affiche le rempotage que la bonne année

### v1.4.2 - "Amélioration base de données" 
**Architecture & Données :**
L'encyclopédie n'est plus codée "en dur" mais chargée depuis un fichier `plants.json`. Cela permet d'ajouter des centaines de plantes facilement sans toucher au code.
Les données (Lumière, Humidité, Difficulté) sont maintenant standardisées pour permettre les filtres futurs.
Les fiches détail affichent désormais les critères (Rusticité, Toxicité...) avec des libellés clairs et des emojis, au lieu de codes techniques.

**Améliorations UX :**
L'ajout de plante trouve désormais l'espèce même si on tape son nom commun (ex: "Langue de belle-mère" propose "Sansevieria").
Lors de l'ajout d'une plante, possibilité de saisir la date réelle du dernier arrosage/engrais/rempotage pour caler les cycles immédiatement.
Suppression du bouton "Poubelle" dans l'écran de modification pour éviter les accidents (la suppression reste accessible via le menu de gestion).
Majuscule automatique sur les noms d'espèces et gestion intelligente du surnom vide.

**Correctifs :**
Correction de l'erreur qui fermait l'application après la suppression d'une plante.
Correction du crash au démarrage sur les versions optimisées (ProGuard/R8).
La liste des plantes se met désormais à jour instantanément après une action dans le détail.

### v1.4.1 - "Peaufinage & UX"
L'arrosage rapide (goutte) est validé immédiatement si le suivi est désactivé.
Vue "Semaine" par défaut. Masquage des jours/mois passés.
Changement de "Retard" (Rouge) à "En attente" (Violet) pour réduire l'anxiété.
Majuscule automatique sur les espèces. Gestion du surnom vide.
Possibilité de saisir la date du dernier arrosage/engrais/rempotage à la création pour caler les cycles immédiatement.
Rafraichissement automatique des listes au retour des écrans de détail.

### v1.4.0 - "Potager"
Gestion des stades (Graine -> Semis -> En terre -> Récolte).
Affichage des périodes de Semis, Mise en terre (Repiquage) et Récolte.
Possibilité d'activer/désactiver le suivi (Arrosage, Engrais, Rempotage) par plante.
Désactivation automatique du suivi arrosage pour les plantes d'extérieur.

### v1.3.0 - "Album Photo"
Nouvel onglet/écran pour voir toutes les photos d'une plante.
Ajout de photos illimitées pour suivre la croissance.
Remplacement des boutons épars par un menu clair (Album, Historique, Modifier).

### v1.2.0 - "Prendre Soin"
Remplacement du bouton simple par un grand menu "Prendre soin" (Arroser, Fertiliser, Tailler...).
Option "J'ai tout fait sans noter" pour remettre les compteurs à zéro.
La fiche détail devient une fiche de consultation propre (plus de clics accidentels sur les dates).

### v1.1.0 - "Le Calendrier"
Ajout des vues Semaine (Arrosages) / Mois (Travaux) / Année (Planification).
Calcul intelligent des dates (pas d'engrais en hiver, rempotage au printemps).
Affichage par "Atelier" (Toutes les tailles, tous les arrosages...).

### v1.0.0 - "Naissance"
Base de données SQLite, Notifications locales.
Ajouter, Modifier, Supprimer une plante (Intérieur/Extérieur).
Données de base pour 100 plantes.
Algorithme simple d'ajustement de fréquence (Trop sec / Trop humide).