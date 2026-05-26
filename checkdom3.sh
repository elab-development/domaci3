#!/bin/bash

PREFIX=$1

if [ -z "$PREFIX" ]; then
  echo "Upotreba: sudo ./checkdom3.sh <studentski-prefiks>"
  echo "Primer: sudo ./checkdom3.sh pg20220043"
  exit 1
fi

PROJECT_NAME="${PREFIX}-app"

BACK_CONT="${PREFIX}-back"
FRONT_CONT="${PREFIX}-front"
DB_CONT="${PREFIX}-db"

BACK_IMG="${PREFIX}-img1"
FRONT_IMG="${PREFIX}-img2"

# Logički nazivi iz compose.yaml fajla
NETWORK_KEY="${PREFIX}-network"
VOLUME_KEY="mysql-data"

# Stvarni nazivi koje Docker Compose najčešće kreira ako nije eksplicitno naveden name:
COMPOSE_NETWORK="${PROJECT_NAME}_${NETWORK_KEY}"
COMPOSE_VOLUME="${PROJECT_NAME}_${VOLUME_KEY}"

# Stvarni nazivi ako je student eksplicitno definisao name:
EXPLICIT_NETWORK="${PREFIX}-network"
EXPLICIT_VOLUME="${PREFIX}-mysql-data"

COMPOSE_FILE="compose.yaml"

REPORT="provera-domaci3-${PREFIX}.txt"
SUMMARY_FILE="sumarna-provera-domaci3-${PREFIX}.txt"

OK_COUNT=0
TOTAL_REQUIREMENTS=9

echo "PROVERA DOMAĆEG 3 ZA: $PREFIX" > "$REPORT"
echo "======================================" >> "$REPORT"
echo "" >> "$REPORT"

echo "SUMARNA PROVERA DOMAĆEG 3 ZA: $PREFIX" > "$SUMMARY_FILE"
echo "======================================" >> "$SUMMARY_FILE"
echo "" >> "$SUMMARY_FILE"

print_result() {
  local REQ=$1
  local STATUS=$2
  local MESSAGE=$3

  if [ "$STATUS" = "OK" ]; then
    OK_COUNT=$((OK_COUNT + 1))
  fi

  echo "Zahtev $REQ: [$STATUS] $MESSAGE"
  echo "Zahtev $REQ: [$STATUS] $MESSAGE" >> "$REPORT"
  echo "Zahtev $REQ: [$STATUS] $MESSAGE" >> "$SUMMARY_FILE"
}

section() {
  echo ""
  echo "$1"
  echo "$1" >> "$REPORT"
  echo "--------------------------------------" >> "$REPORT"
}

container_exists() {
  sudo docker container inspect "$1" > /dev/null 2>&1
}

container_running() {
  [ "$(sudo docker inspect -f '{{.State.Running}}' "$1" 2>/dev/null)" = "true" ]
}

image_exists() {
  sudo docker image inspect "$1" > /dev/null 2>&1
}

network_exists() {
  sudo docker network inspect "$1" > /dev/null 2>&1
}

volume_exists() {
  sudo docker volume inspect "$1" > /dev/null 2>&1
}

container_in_network() {
  local CONTAINER=$1
  local NETWORK_NAME=$2

  sudo docker network inspect "$NETWORK_NAME" 2>/dev/null | grep -q "\"Name\": \"$CONTAINER\""
}

port_available() {
  local PORT=$1
  curl -s --max-time 5 "http://localhost:$PORT" > /dev/null 2>&1
}

get_existing_network() {
  if sudo docker network inspect "$COMPOSE_NETWORK" > /dev/null 2>&1; then
    echo "$COMPOSE_NETWORK"
  elif sudo docker network inspect "$EXPLICIT_NETWORK" > /dev/null 2>&1; then
    echo "$EXPLICIT_NETWORK"
  else
    echo ""
  fi
}

get_existing_volume() {
  if sudo docker volume inspect "$COMPOSE_VOLUME" > /dev/null 2>&1; then
    echo "$COMPOSE_VOLUME"
  elif sudo docker volume inspect "$EXPLICIT_VOLUME" > /dev/null 2>&1; then
    echo "$EXPLICIT_VOLUME"
  else
    echo ""
  fi
}

compose_has_service() {
  local SERVICE=$1
  grep -Eq "^[[:space:]]{2}${SERVICE}:" "$COMPOSE_FILE" 2>/dev/null
}

compose_contains() {
  local PATTERN=$1
  grep -q "$PATTERN" "$COMPOSE_FILE" 2>/dev/null
}

# --------------------------------------
# 0. Osnovna provera
# --------------------------------------

section "0. OSNOVNA PROVERA"

if [ -f "$COMPOSE_FILE" ]; then
  echo "[OK] compose.yaml postoji."
  echo "[OK] compose.yaml postoji." >> "$REPORT"
else
  echo "[GREŠKA] compose.yaml ne postoji. Dalje provere će verovatno pasti."
  echo "[GREŠKA] compose.yaml ne postoji." >> "$REPORT"
fi

# --------------------------------------
# Zahtev 1
# compose.yaml postoji + name projekta
# --------------------------------------

section "1. PROVERA COMPOSE FAJLA I NAZIVA PROJEKTA"

if [ -f "$COMPOSE_FILE" ] && grep -Eq "^[[:space:]]*name:[[:space:]]*[\"']?${PROJECT_NAME}[\"']?" "$COMPOSE_FILE"; then
  print_result "1" "OK" "compose.yaml postoji i naziv projekta je $PROJECT_NAME."
else
  print_result "1" "NIJE OK" "Nedostaje compose.yaml ili naziv projekta nije $PROJECT_NAME."
fi

# --------------------------------------
# Zahtev 2
# servisi backend, frontend, database
# --------------------------------------

section "2. PROVERA DEFINISANIH SERVISA"

if [ -f "$COMPOSE_FILE" ] \
  && compose_has_service "backend" \
  && compose_has_service "frontend" \
  && compose_has_service "database"; then
  print_result "2" "OK" "Definisani su servisi backend, frontend i database."
else
  print_result "2" "NIJE OK" "Nisu pronađena sva tri servisa: backend, frontend i database."
fi

# --------------------------------------
# Zahtev 3
# image/build, container_name, env_file, mreža, DB host
# --------------------------------------

section "3. PROVERA SERVISA, IMAGE-A, KONTEJNERA, ENV I DB_HOST"

BACKEND_ENV_OK=false
BACKEND_APP_OK=false

if [ -f "env/backend.env" ] && grep -q "$DB_CONT" "env/backend.env"; then
  BACKEND_ENV_OK=true
fi

if [ -f "backend/app.js" ] && grep -q "$DB_CONT" "backend/app.js"; then
  BACKEND_APP_OK=true
fi

if [ -f "$COMPOSE_FILE" ] \
  && grep -q "container_name: $BACK_CONT" "$COMPOSE_FILE" \
  && grep -q "container_name: $FRONT_CONT" "$COMPOSE_FILE" \
  && grep -q "container_name: $DB_CONT" "$COMPOSE_FILE" \
  && grep -q "image: mysql:latest" "$COMPOSE_FILE" \
  && grep -q "image: $BACK_IMG" "$COMPOSE_FILE" \
  && grep -q "image: $FRONT_IMG" "$COMPOSE_FILE" \
  && grep -q "context: ./backend" "$COMPOSE_FILE" \
  && grep -q "context: ./frontend" "$COMPOSE_FILE" \
  && grep -q "env_file:" "$COMPOSE_FILE" \
  && grep -q "$NETWORK_KEY" "$COMPOSE_FILE" \
  && [ "$BACKEND_ENV_OK" = true ] \
  && [ "$BACKEND_APP_OK" = true ]; then
  print_result "3" "OK" "Servisi imaju odgovarajuće build/image vrednosti, nazive kontejnera, env podešavanja, mrežu i DB host."
else
  print_result "3" "NIJE OK" "Nedostaju očekivane build/image/container/env/network vrednosti ili DB host nije izmenjen u backend/app.js i env/backend.env."
fi

# --------------------------------------
# Zahtev 4
# volumes za backend, frontend i database
# --------------------------------------

section "4. PROVERA VOLUMENA U COMPOSE FAJLU"

if [ -f "$COMPOSE_FILE" ] \
  && grep -q "./backend:/app" "$COMPOSE_FILE" \
  && grep -q "./frontend:/app" "$COMPOSE_FILE" \
  && grep -q "/app/node_modules" "$COMPOSE_FILE" \
  && grep -q "mysql-data:/var/lib/mysql" "$COMPOSE_FILE" \
  && grep -q "./db/init.sql:/docker-entrypoint-initdb.d/init.sql" "$COMPOSE_FILE" \
  && grep -q "./db/my.cnf:/etc/mysql/conf.d/my-custom.cnf:ro" "$COMPOSE_FILE"; then
  print_result "4" "OK" "Definisani su očekivani volume-i za backend, frontend i database."
else
  print_result "4" "NIJE OK" "Nedostaje neki od očekivanih volume-a."
fi

# --------------------------------------
# Zahtev 5
# portovi i depends_on
# --------------------------------------

section "5. PROVERA PORTOVA I ZAVISNOSTI"

if [ -f "$COMPOSE_FILE" ] \
  && grep -q "\"3000:3000\"" "$COMPOSE_FILE" \
  && grep -q "\"5000:3000\"" "$COMPOSE_FILE" \
  && grep -q "depends_on:" "$COMPOSE_FILE" \
  && grep -q "condition: service_healthy" "$COMPOSE_FILE"; then
  print_result "5" "OK" "Frontend i backend imaju portove i zavisnosti sa uslovom service_healthy."
else
  print_result "5" "NIJE OK" "Nedostaju portovi 3000/5000 ili depends_on uslovi."
fi

# --------------------------------------
# Zahtev 6
# healthcheck za database
# --------------------------------------

section "6. PROVERA HEALTHCHECK-A BAZE"

if [ -f "$COMPOSE_FILE" ] \
  && grep -q "healthcheck:" "$COMPOSE_FILE" \
  && grep -q "mysqladmin" "$COMPOSE_FILE" \
  && grep -q "ping" "$COMPOSE_FILE" \
  && grep -q "student" "$COMPOSE_FILE" \
  && grep -q "interval: 10s" "$COMPOSE_FILE" \
  && grep -q "timeout: 10s" "$COMPOSE_FILE" \
  && grep -q "retries: 6" "$COMPOSE_FILE"; then
  print_result "6" "OK" "Database servis ima definisan očekivani healthcheck."
else
  print_result "6" "NIJE OK" "Healthcheck za database nije definisan u očekivanom obliku."
fi

# --------------------------------------
# Zahtev 7
# network definisan i kreiran
# --------------------------------------

section "7. PROVERA MREŽE"

REAL_NETWORK=$(get_existing_network)

if [ -f "$COMPOSE_FILE" ] \
  && grep -q "networks:" "$COMPOSE_FILE" \
  && grep -q "$NETWORK_KEY" "$COMPOSE_FILE" \
  && [ -n "$REAL_NETWORK" ]; then
  print_result "7" "OK" "Mreža je definisana u compose.yaml i kreirana kao Docker mreža: $REAL_NETWORK."
else
  print_result "7" "NIJE OK" "Mreža nije definisana ili nije kreirana. Očekivano: $COMPOSE_NETWORK ili $EXPLICIT_NETWORK."
fi

# --------------------------------------
# Zahtev 8
# volume definisan i kreiran
# --------------------------------------

section "8. PROVERA VOLUMENA"

REAL_VOLUME=$(get_existing_volume)

if [ -f "$COMPOSE_FILE" ] \
  && grep -q "volumes:" "$COMPOSE_FILE" \
  && grep -q "$VOLUME_KEY" "$COMPOSE_FILE" \
  && [ -n "$REAL_VOLUME" ]; then
  print_result "8" "OK" "Volume je definisan u compose.yaml i kreiran kao Docker volume: $REAL_VOLUME."
else
  print_result "8" "NIJE OK" "Volume nije definisan ili nije kreiran. Očekivano: $COMPOSE_VOLUME ili $EXPLICIT_VOLUME."
fi

# --------------------------------------
# Zahtev 9
# aplikacija pokrenuta, kontejneri rade, frontend/backend dostupni
# --------------------------------------

section "9. PROVERA POKRENUTE APLIKACIJE"

REAL_NETWORK=$(get_existing_network)
DB_HEALTH=$(sudo docker inspect -f '{{.State.Health.Status}}' "$DB_CONT" 2>/dev/null)

if container_exists "$BACK_CONT" \
  && container_exists "$FRONT_CONT" \
  && container_exists "$DB_CONT" \
  && container_running "$BACK_CONT" \
  && container_running "$FRONT_CONT" \
  && container_running "$DB_CONT" \
  && image_exists "$BACK_IMG" \
  && image_exists "$FRONT_IMG" \
  && [ -n "$REAL_NETWORK" ] \
  && container_in_network "$BACK_CONT" "$REAL_NETWORK" \
  && container_in_network "$FRONT_CONT" "$REAL_NETWORK" \
  && container_in_network "$DB_CONT" "$REAL_NETWORK" \
  && port_available "3000" \
  && port_available "5000" \
  && [ "$DB_HEALTH" = "healthy" ]; then
  print_result "9" "OK" "Sva tri kontejnera su pokrenuta, image-i postoje, mreža je povezana ($REAL_NETWORK), baza je healthy i aplikacija je dostupna na portovima 3000 i 5000."
else
  print_result "9" "NIJE OK" "Aplikacija nije kompletno pokrenuta: proveriti kontejnere, image-e, mrežu, health baze i portove 3000/5000. Detektovana mreža: ${REAL_NETWORK:-nije pronađena}, health baze: ${DB_HEALTH:-nije dostupan}."
fi

# --------------------------------------
# Dodatni izveštaji
# --------------------------------------

echo "" >> "$REPORT"
echo "======================================" >> "$REPORT"
echo "DODATNI DOCKER STATUS" >> "$REPORT"
echo "======================================" >> "$REPORT"

echo "" >> "$REPORT"
echo "docker compose ps:" >> "$REPORT"
sudo docker compose ps >> "$REPORT" 2>&1

echo "" >> "$REPORT"
echo "docker ps -a:" >> "$REPORT"
sudo docker ps -a >> "$REPORT" 2>&1

echo "" >> "$REPORT"
echo "docker images:" >> "$REPORT"
sudo docker images >> "$REPORT" 2>&1

echo "" >> "$REPORT"
echo "docker volume ls:" >> "$REPORT"
sudo docker volume ls >> "$REPORT" 2>&1

echo "" >> "$REPORT"
echo "docker network ls:" >> "$REPORT"
sudo docker network ls >> "$REPORT" 2>&1

if [ -n "$REAL_NETWORK" ]; then
  echo "" >> "$REPORT"
  echo "docker network inspect $REAL_NETWORK:" >> "$REPORT"
  sudo docker network inspect "$REAL_NETWORK" >> "$REPORT" 2>&1
fi

if [ -n "$REAL_VOLUME" ]; then
  echo "" >> "$REPORT"
  echo "docker volume inspect $REAL_VOLUME:" >> "$REPORT"
  sudo docker volume inspect "$REAL_VOLUME" >> "$REPORT" 2>&1
fi

# --------------------------------------
# Ukupan rezultat
# --------------------------------------

echo ""
echo "======================================"
echo "UKUPNO USPEŠNO ISPUNJENIH ZAHTEVA: $OK_COUNT/$TOTAL_REQUIREMENTS"
echo "======================================"

echo "" >> "$REPORT"
echo "======================================" >> "$REPORT"
echo "UKUPNO USPEŠNO ISPUNJENIH ZAHTEVA: $OK_COUNT/$TOTAL_REQUIREMENTS" >> "$REPORT"
echo "======================================" >> "$REPORT"

echo "" >> "$SUMMARY_FILE"
echo "======================================" >> "$SUMMARY_FILE"
echo "UKUPNO USPEŠNO ISPUNJENIH ZAHTEVA: $OK_COUNT/$TOTAL_REQUIREMENTS" >> "$SUMMARY_FILE"
echo "======================================" >> "$SUMMARY_FILE"

echo ""
echo "Glavni izveštaj: $REPORT"
echo "Sumarna provera: $SUMMARY_FILE"

# --------------------------------------
# ZIP arhiva
# --------------------------------------

ARCHIVE_DIR="dokazi-domaci3-${PREFIX}"
ZIP_FILE="dokazi-domaci3-${PREFIX}.zip"

rm -rf "$ARCHIVE_DIR"
mkdir -p "$ARCHIVE_DIR"

if [ -f "$COMPOSE_FILE" ]; then
  cp "$COMPOSE_FILE" "$ARCHIVE_DIR/"
fi

if [ -f "$REPORT" ]; then
  cp "$REPORT" "$ARCHIVE_DIR/"
fi

if [ -f "$SUMMARY_FILE" ]; then
  cp "$SUMMARY_FILE" "$ARCHIVE_DIR/"
fi

if [ -f "backend/app.js" ]; then
  mkdir -p "$ARCHIVE_DIR/backend"
  cp "backend/app.js" "$ARCHIVE_DIR/backend/"
fi

if [ -f "env/backend.env" ]; then
  mkdir -p "$ARCHIVE_DIR/env"
  cp "env/backend.env" "$ARCHIVE_DIR/env/"
fi

if [ -f "db/init.sql" ]; then
  mkdir -p "$ARCHIVE_DIR/db"
  cp "db/init.sql" "$ARCHIVE_DIR/db/"
fi

if command -v zip > /dev/null 2>&1; then
  zip -r "$ZIP_FILE" "$ARCHIVE_DIR" > /dev/null
  echo "[OK] Kreirana ZIP arhiva: $ZIP_FILE"
  echo "[OK] Kreirana ZIP arhiva: $ZIP_FILE" >> "$REPORT"
else
  echo "[UPOZORENJE] Komanda zip nije instalirana. Instaliraj je komandom: sudo apt install zip"
  echo "[UPOZORENJE] Komanda zip nije instalirana. Instaliraj je komandom: sudo apt install zip" >> "$REPORT"
fi

echo ""
echo "ZIP arhiva: $ZIP_FILE"
echo "Folder sa dokazima: $ARCHIVE_DIR"