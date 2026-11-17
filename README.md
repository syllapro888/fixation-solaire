# Fixation Solaire

Application Android pour calculer les **corners (cornières) de 6 m**, les **rails** et les **clamps** nécessaires
aux supports de panneaux solaires, avec simulation 3D et plan de coupe.

## Fonctionnalités

- Système : corner seulement, rail + clamp (sur toit), ou mixte corner + rail
  (barre du haut et/ou du bas en rail).
- Nombre de panneaux, puis choix des rangées (1 rangée de 8, 4+4, 3+3+2…) avec
  le nombre de corners pour chaque choix.
- Réglage de chaque cadre un par un : panneaux, pieds devant / derrière
  (nombre et hauteur), supports du milieu, crochets.
- Vue 3D (tourner avec le doigt), vue de côté avec l'inclinaison.
- Liste des pièces, plan de coupe optimisé, soudures de raccord pour les
  pièces de plus de 6 m, prix total.
- Coûts : prix de chaque article (modifiable), anti-rouille et diluant,
  points de soudure et baguettes (paquet, demi-paquet, pièce), disques,
  main-d’œuvre, transport, remise.
- Ticket d’installation numéroté, en PDF à partager sur WhatsApp, avec historique.
- Copier la liste ou l’envoyer sur WhatsApp.
- Mise à jour intégrée : l'application vérifie la dernière version publiée
  dans **Releases** et propose de l'installer.

Réglages par défaut : panneau 115 × 230 cm, pieds devant 55 cm, derrière 85 cm,
semelles 15 cm, crochets 10 cm (2 par panneau).

## Construire l'application

Chaque envoi sur la branche `main` lance GitHub Actions (onglet **Actions**) :
tests, construction de l'APK, vérification de la clé de signature, puis
publication dans **Releases**.

L'APK est toujours signé avec **la même clé** (`.ci/signing-key.b64`, ou le
secret `ANDROID_KEYSTORE_B64` s'il existe) : chaque nouvelle version s'installe
par-dessus l'ancienne sans désinstaller.

## Installer sur Android

Ouvrir la page **Releases** depuis le téléphone, télécharger le fichier `.apk`
et l'installer (autoriser l'installation depuis le navigateur si demandé).

## Structure

```
assets/app/index.html   calculateur (calculs, 3D, plan de coupe)
lib/main.dart           application Android (affiche le calculateur)
lib/updater.dart        mises à jour depuis GitHub Releases
tool/prepare_android.sh prépare le dossier android/
```
