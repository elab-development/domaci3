#!/bin/bash

PREFIX=$1

if [ -z "$PREFIX" ]; then
  echo "Upotreba: sudo ./cleanupdom3.sh <studentski-prefiks>"
  echo "Primer: sudo ./cleanupdom3.sh pg20220043"
  exit 1
fi

PROJECT_NAME="${PREFIX}-app"

BACK_CONT="${PREFIX}-back"
FRONT_CONT="${PREFIX}-front"
DB_CONT="${PREFIX}-db"

BACK_IMG="${PREFIX}-img1"
FRONT_IMG="${PREFIX}-img2"

NETWORK="${PREFIX}-network"
VOLUME="${PREFIX}-mysql-data"

ZIP_FILE="dokazi-domaci3-${PREFIX}.zip"

echo "======================================"
echo "CLEANUP DOMAĆI 3 ZA: $PREFIX"
echo "======================================"
echo ""

# --------------------------------------
# Provera da li postoji ZIP arhiva
# --------------------------------------

if [ ! -f "$ZIP_FILE" ]; then
  echo "[STOP] ZIP arhiva ne postoji: $ZIP_FILE"
  echo "Cleanup nije pokrenut da se ne bi obrisali dokazi pre provere."
  exit 1
fi

echo "[OK] Pronađena ZIP arhiva: $ZIP_FILE"
echo ""

# --------------------------------------
# Docker Compose down
# --------------------------------------

echo "1. ZAUSTAVLJANJE COMPOSE APLIKACIJE"
echo "--------------------------------------"

if [ -f "compose.yaml" ]; then
  sudo docker compose down
  echo "[OK] Izvršeno: docker compose down"
else
  echo "[UPOZORENJE] compose.yaml nije pronađen. Preskačem docker compose down."
fi

echo ""

# --------------------------------------
# Brisanje kontejnera
# --------------------------------------

echo "2. BRISANJE KONTEJNERA"
echo "--------------------------------------"

for CONT in "$BACK_CONT" "$FRONT_CONT" "$DB_CONT"; do
  if sudo docker container inspect "$CONT" > /dev/null 2>&1; then
    sudo docker rm -f "$CONT" > /dev/null 2>&1
    echo "[OK] Obrisан kontejner: $CONT"
  else
    echo "[INFO] Kontejner ne postoji: $CONT"
  fi
done

echo ""

# --------------------------------------
# Brisanje image-a
# --------------------------------------

echo "3. BRISANJE IMAGE-A"
echo "--------------------------------------"

for IMG in "$BACK_IMG" "$FRONT_IMG"; do
  if sudo docker image inspect "$IMG" > /dev/null 2>&1; then
    sudo docker rmi -f "$IMG" > /dev/null 2>&1
    echo "[OK] Obrisан image: $IMG"
  else
    echo "[INFO] Image ne postoji: $IMG"
  fi
done

echo ""

# --------------------------------------
# Brisanje mreže
# --------------------------------------

echo "4. BRISANJE MREŽE"
echo "--------------------------------------"

if sudo docker network inspect "$NETWORK" > /dev/null 2>&1; then
  sudo docker network rm "$NETWORK" > /dev/null 2>&1
  echo "[OK] Obrisana mreža: $NETWORK"
else
  echo "[INFO] Mreža ne postoji: $NETWORK"
fi

echo ""

# --------------------------------------
# Brisanje volume-a
# --------------------------------------

echo "5. BRISANJE VOLUME-A"
echo "--------------------------------------"

if sudo docker volume inspect "$VOLUME" > /dev/null 2>&1; then
  sudo docker volume rm "$VOLUME" > /dev/null 2>&1
  echo "[OK] Obrisan volume: $VOLUME"
else
  echo "[INFO] Volume ne postoji: $VOLUME"
fi

echo ""

# --------------------------------------
# Završna provera
# --------------------------------------

echo "6. ZAVRŠNA PROVERA"
echo "--------------------------------------"

echo "Preostali relevantni kontejneri:"
sudo docker ps -a --filter "name=${PREFIX}" --format "table {{.Names}}\t{{.Status}}"

echo ""
echo "Preostali relevantni image-i:"
sudo docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.ID}}" | grep "$PREFIX" || echo "[INFO] Nema image-a za $PREFIX"

echo ""
echo "Preostale relevantne mreže:"
sudo docker network ls --format "table {{.Name}}\t{{.Driver}}" | grep "$PREFIX" || echo "[INFO] Nema mreža za $PREFIX"

echo ""
echo "Preostali relevantni volume-i:"
sudo docker volume ls --format "table {{.Name}}" | grep "$PREFIX" || echo "[INFO] Nema volume-a za $PREFIX"

echo ""
echo "======================================"
echo "CLEANUP ZAVRŠEN ZA: $PREFIX"
echo "======================================"