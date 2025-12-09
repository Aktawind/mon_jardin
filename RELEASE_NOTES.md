# 🌿 Sève - Notes de version

Ce fichier trace l'historique des évolutions de l'application Sève.

---

## 🔮 À Venir (Roadmap)

### v1.7.0 - "L'Esprit Tranquille" (Mode Vacances)
- **Mode Vacances 🏖️ :** Sélecteur de dates de départ et de retour.
- **Générateur d'instructions :** Création automatique d'une liste "Avant de partir" (Baigner, déplacer à l'ombre...) et d'une "Fiche Nounou" pour la personne qui vient arroser.

### v1.6.0 - "Docteur Plante" (Aide & Diagnostic)
- **SOS Plante 🚑 :** Assistant de diagnostic interactif simple (Chatbot à choix multiples).
- **Arbre de décision :** Identifier les problèmes courants (Feuilles jaunes, taches, nuisibles) et proposer des solutions rassurantes.

### v1.5.1 - "Souvenirs" (Esthétique)
- **Filtres Photo 📸 :** Application automatique d'un filtre "Éclat" (Vignettage + Saturation douce) lors de l'ajout d'une photo.
- **Style Polaroid :** Affichage des photos dans le journal avec un cadre blanc et la date manuscrite.

---

## 🚧 En Développement

### v1.5.0 - "Le Conseiller"
- Formulaire interactif "Quelle plante est faite pour moi ?" (Critères : Lieu, Lumière, Fréquence d'arrosage). Proposition de plantes adaptées depuis l'encyclopédie.
- Grosse phase de Clean Code pour supprimer tous les warnings
- Refonte complète de la base de données pour séparer les données en trois groupes
- Création de fichiers csv pour maintenir la base de données plus simplement
- Ajout de scripts pour convertir les csv en json et inversement

---

## ✅ Versions publiées

### v1.4.5 - "Refonte du menu principal"
- Restructuration de la navigation principale pour accueillir les futures fonctionnalités.

### v1.4.4 - "Corrections de bugs et améliorations"
- On peut supprimer une entrée dans l'historique via un appui long
- Gestion des fuseaux horaires pour que les dates calculées soient correctes
- Amélioration de la visibilité du bouton menu (3 points) sur les photos de couverture (ajout d'un fond contrasté).

### v1.4.3 - "Corrections de bug"
- Les widgets calendriers sont en français.
- Les plantes qui n'ont pas besoin d'arrosage en hiver (comme les cactus) ne réclament pas d'eau (si l'encyclopédie dit water_winter: 0) et sont marquées en "repos"
- Le calendrier n'affiche le rempotage que la bonne année

### v1.4.2 - "L'Encyclopédie" 
**Architecture & Données :**
- **Migration JSON :** L'encyclopédie n'est plus codée "en dur" mais chargée depuis un fichier `plants.json`. Cela permet d'ajouter des centaines de plantes facilement sans toucher au code.
- **Enums & Standards :** Les données (Lumière, Humidité, Difficulté) sont maintenant standardisées pour permettre les filtres futurs.
- **Affichage enrichi :** Les fiches détail affichent désormais les critères (Rusticité, Toxicité...) avec des libellés clairs et des emojis, au lieu de codes techniques.

**Améliorations UX (Expérience Utilisateur) :**
- **Recherche par Synonymes :** L'ajout de plante trouve désormais l'espèce même si on tape son nom commun (ex: "Langue de belle-mère" propose "Sansevieria").
- **Historique Rétroactif :** Lors de l'ajout d'une plante, possibilité de saisir la date réelle du dernier arrosage/engrais/rempotage pour caler les cycles immédiatement.
- **Sécurité :** Suppression du bouton "Poubelle" dans l'écran de modification pour éviter les accidents (la suppression reste accessible via le menu de gestion).
- **Saisie propre :** Majuscule automatique sur les noms d'espèces et gestion intelligente du surnom vide.

**Correctifs (Bug Fixes) :**
- **Crash Suppression :** Correction de l'erreur qui fermait l'application après la suppression d'une plante.
- **Android Release :** Correction du crash au démarrage sur les versions optimisées (ProGuard/R8).
- **Rafraîchissement :** La liste des plantes se met désormais à jour instantanément après une action dans le détail.

### v1.4.1 - "Peaufinage & UX"
- **Correction UX :** L'arrosage rapide (goutte) est validé immédiatement si le suivi est désactivé.
- **Calendrier :** Vue "Semaine" par défaut. Masquage des jours/mois passés.
- **Alertes :** Changement de "Retard" (Rouge) à "En attente" (Violet) pour réduire l'anxiété.
- **Saisie intelligente :** Majuscule automatique sur les espèces. Gestion du surnom vide.
- **Historique initial :** Possibilité de saisir la date du dernier arrosage/engrais/rempotage à la création pour caler les cycles immédiatement.
- **Correction Bug :** Rafraichissement automatique des listes au retour des écrans de détail.

### v1.4.0 - "Le Potager"
- **Cycle de vie :** Gestion des stades (Graine -> Semis -> En terre -> Récolte).
- **Calendrier Potager :** Affichage des périodes de Semis, Mise en terre (Repiquage) et Récolte.
- **Suivi personnalisé :** Possibilité d'activer/désactiver le suivi (Arrosage, Engrais, Rempotage) par plante.
- **Valeurs par défaut :** Désactivation automatique du suivi arrosage pour les plantes d'extérieur.

### v1.3.0 - "Album Photo"
- **Galerie :** Nouvel onglet/écran pour voir toutes les photos d'une plante.
- **Journal :** Ajout de photos illimitées pour suivre la croissance.
- **Menu Gestion :** Remplacement des boutons épars par un menu clair (Album, Historique, Modifier).

### v1.2.0 - "Prendre Soin"
- **Menu Actions :** Remplacement du bouton simple par un grand menu "Prendre soin" (Arroser, Fertiliser, Tailler...).
- **Anti-Culpabilité :** Option "J'ai tout fait sans noter" pour remettre les compteurs à zéro.
- **Lecture seule :** La fiche détail devient une fiche de consultation propre (plus de clics accidentels sur les dates).

### v1.1.0 - "Le Temps"
- **Calendrier :** Ajout des vues Semaine (Arrosages) / Mois (Travaux) / Année (Planification).
- **Logique Saisonnière :** Calcul intelligent des dates (pas d'engrais en hiver, rempotage au printemps).
- **Vues groupées :** Affichage par "Atelier" (Toutes les tailles, tous les arrosages...).

### v1.0.0 - "Naissance"
- **Socle technique :** Base de données SQLite, Notifications locales.
- **Gestion :** Ajouter, Modifier, Supprimer une plante (Intérieur/Extérieur).
- **Encyclopédie V1 :** Données de base pour 100 plantes.
- **Smart Watering :** Algorithme simple d'ajustement de fréquence (Trop sec / Trop humide).