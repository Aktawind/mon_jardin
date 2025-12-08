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
**Architecture & Navigation :**
- **Menu Latéral (Drawer) 🍔 :** Restructuration de la navigation principale pour accueillir les futures fonctionnalités.
- **Accès Paramètres :** Ajout d'un accès rapide depuis le Calendrier et le Drawer.
- **UI Fix :** Amélioration de la visibilité du bouton menu (3 points) sur les photos de couverture (ajout d'un fond contrasté).

**Données (Refactoring) :**
- **Enums 🧱 :** Structuration stricte des données pour la Lumière (`low`, `medium`, `high`) et l'Humidité. Préparation pour le filtrage.

**Fonctionnalités :**
- **Guide d'Achat (Match-Making) 💘 :** Formulaire interactif "Quelle plante est faite pour moi ?" (Critères : Lieu, Lumière, Fréquence d'arrosage). Proposition de plantes adaptées depuis l'encyclopédie.

---

## ✅ Versions publiées

### v1.4.1 - "Peaufinage & UX"
- **Correction UX :** L'arrosage rapide (goutte) est validé immédiatement si le suivi est désactivé.
- **Calendrier :** Vue "Semaine" par défaut. Masquage des jours/mois passés.
- **Alertes :** Changement de "Retard" (Rouge) à "En attente" (Violet) pour réduire l'anxiété.
- **Saisie intelligente :** Majuscule automatique sur les espèces. Gestion du surnom vide.
- **Historique initial :** Possibilité de saisir la date du dernier arrosage/engrais/rempotage à la création pour caler les cycles immédiatement.
- **Correction Bug :** Rafraichissement automatique des listes au retour des écrans de détail.

### v1.4.0 - "Le Potager" 🥕
- **Cycle de vie :** Gestion des stades (Graine -> Semis -> En terre -> Récolte).
- **Calendrier Potager :** Affichage des périodes de Semis, Mise en terre (Repiquage) et Récolte.
- **Suivi personnalisé :** Possibilité d'activer/désactiver le suivi (Arrosage, Engrais, Rempotage) par plante.
- **Valeurs par défaut :** Désactivation automatique du suivi arrosage pour les plantes d'extérieur.

### v1.3.0 - "Album Photo" 📸
- **Galerie :** Nouvel onglet/écran pour voir toutes les photos d'une plante.
- **Journal :** Ajout de photos illimitées pour suivre la croissance.
- **Menu Gestion :** Remplacement des boutons épars par un menu clair (Album, Historique, Modifier).

### v1.2.0 - "Prendre Soin" 🛋️
- **Menu Actions :** Remplacement du bouton simple par un grand menu "Prendre soin" (Arroser, Fertiliser, Tailler...).
- **Anti-Culpabilité :** Option "J'ai tout fait sans noter" pour remettre les compteurs à zéro.
- **Lecture seule :** La fiche détail devient une fiche de consultation propre (plus de clics accidentels sur les dates).

### v1.1.0 - "Le Temps" 📅
- **Calendrier :** Ajout des vues Semaine (Arrosages) / Mois (Travaux) / Année (Planification).
- **Logique Saisonnière :** Calcul intelligent des dates (pas d'engrais en hiver, rempotage au printemps).
- **Vues groupées :** Affichage par "Atelier" (Toutes les tailles, tous les arrosages...).

### v1.0.0 - "Naissance" 🌱
- **Socle technique :** Base de données SQLite, Notifications locales.
- **Gestion :** Ajouter, Modifier, Supprimer une plante (Intérieur/Extérieur).
- **Encyclopédie V1 :** Données de base pour 100 plantes.
- **Smart Watering :** Algorithme simple d'ajustement de fréquence (Trop sec / Trop humide).