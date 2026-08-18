#!/bin/bash
#
# ============================================================
#  Pterodactyl Panel + Wings - Instalador Automático
#  Tema: Infernal Minecraft
#  SO: Debian 11/12
#  Idempotente: No reinstala lo ya configurado
# ============================================================
#

set -e

# ======================= CONFIGURACIÓN =======================
PTERO_VERSION="1.11.11"
PANEL_DIR="/var/www/pterodactyl"
PANEL_USER="www-data"
PANEL_SERVICE="pteroq"
WINGS_DIR="/etc/pterodactyl"
WINGS_SERVICE="wings"
DB_NAME="pterodactyl"
DB_USER="pterodactyl"
DB_PASS=""
DB_ROOT_PASS=""
REDIS_PASS=""
FQDN="45.126.210.74"
SERVER_IP="45.126.210.74"

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
ORANGE='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# ======================= FUNCIONES ============================

print_banner() {
    echo -e "${RED}"
    echo '  ██████╗ ███████╗████████╗██████╗  ██████╗ ███╗  ██╗███████╗███████╗███████╗███████╗'
    echo '  ██╔══██╗██╔════╝╚══██╔══╝██╔══██╗██╔═══██╗████╗ ██║██╔════╝██╔════╝██╔════╝██╔════╝'
    echo '  ██████╔╝█████╗     ██║   ██████╔╝██║   ██║██╔██╗██║█████╗  ███████╗███████╗█████╗  '
    echo '  ██╔═══╗ ██╔══╝     ██║   ██╔══██╗██║   ██║██║╚███║██╔══╝  ╚════██║╚════██║██╔══╝  '
    echo '  ██║   ╚╗███████╗   ██║   ██║  ██║╚██████╔╝██║╚████║███████╗███████║███████║███████╗'
    echo '  ╚═╝    ╚╝╚══════╝   ╚═╝   ╚═╝  ╚═╝ ╚═════╝ ╚═╝ ╚═══╝╚══════╝╚══════╝╚══════╝╚══════╝'
    echo -e "${NC}"
    echo -e "${ORANGE}              🔥 INSTALADOR AUTOMÁTICO - TEMA INFERNAL 🔥${NC}"
    echo ""
}

log_info()    { echo -e "${CYAN}[INFO]${NC}  $1"; }
log_ok()      { echo -e "${GREEN}[OK]${NC}    $1"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC}  $1"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $1"; }
log_step()    { echo -e "\n${ORANGE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"; echo -e "${ORANGE}  ⚡ $1${NC}"; echo -e "${ORANGE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"; }

check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "Este script debe ejecutarse como root (usa sudo)."
        exit 1
    fi
}

check_debian() {
    if [ -f /etc/debian_version ]; then
        DEBIAN_VERSION=$(cat /etc/debian_version | grep -oP '^\d+')
        log_ok "Debian $DEBIAN_VERSION detectado."
    else
        log_error "Este script solo es compatible con Debian."
        exit 1
    fi
}

# Generar contraseñas aleatorias
gen_password() {
    tr -dc 'a-zA-Z0-9!@#%^&*' < /dev/urandom | head -c 24
}

# ======================= PASO 1: DEPENDENCIAS =======================

install_dependencies() {
    log_step "PASO 1: Verificando dependencias del sistema"

    export DEBIAN_FRONTEND=noninteractive

    # Lista de paquetes requeridos
    local packages=(
        "curl" "wget" "gnupg" "ca-certificates" "lsb-release" "apt-transport-https"
        "software-properties-common" "git" "tar" "unzip" "jq" "htop" "nano"
    )

    local need_install=()
    for pkg in "${packages[@]}"; do
        if ! dpkg -s "$pkg" >/dev/null 2>&1; then
            need_install+=("$pkg")
        fi
    done

    if [ ${#need_install[@]} -eq 0 ]; then
        log_ok "Todas las dependencias ya están instaladas."
    else
        log_info "Instalando: ${need_install[*]}"
        apt-get update -y
        apt-get install -y "${need_install[@]}"
        log_ok "Dependencias instaladas."
    fi
}

# ======================= PASO 2: PHP 8.1 =======================

install_php() {
    log_step "PASO 2: Verificando PHP 8.1+"

    # Verificar si PHP 8.1+ ya está instalado
    if command -v php >/dev/null 2>&1; then
        PHP_VERSION=$(php -v 2>/dev/null | head -1 | grep -oP 'PHP \K[0-9]+\.[0-9]+')
        PHP_MAJOR=$(echo "$PHP_VERSION" | cut -d. -f1)
        PHP_MINOR=$(echo "$PHP_VERSION" | cut -d. -f2)

        if [ "$PHP_MAJOR" -gt 8 ] || ([ "$PHP_MAJOR" -eq 8 ] && [ "$PHP_MINOR" -ge 1 ]); then
            log_ok "PHP $PHP_VERSION ya está instalado."

            # Verificar extensiones requeridas
            local php_extensions=(
                "php$PHP_VERSION-cli" "php$PHP_VERSION-gd" "php$PHP_VERSION-mysql"
                "php$PHP_VERSION-pdo" "php$PHP_VERSION-mbstring" "php$PHP_VERSION-tokenizer"
                "php$PHP_VERSION-bcmath" "php$PHP_VERSION-xml" "php$PHP_VERSION-curl"
                "php$PHP_VERSION-zip" "php$PHP_VERSION-intl" "php$PHP_VERSION-fpm"
                "php$PHP_VERSION-redis" "php$PHP_VERSION-gd"
            )

            local need_php=()
            for ext in "${php_extensions[@]}"; do
                if ! dpkg -s "$ext" >/dev/null 2>&1; then
                    need_php+=("$ext")
                fi
            done

            if [ ${#need_php[@]} -gt 0 ]; then
                log_info "Instalando extensiones PHP faltantes: ${need_php[*]}"
                apt-get install -y "${need_php[@]}"
                log_ok "Extensiones PHP instaladas."
            else
                log_ok "Todas las extensiones PHP ya están instaladas."
            fi
            return
        fi
    fi

    log_info "PHP 8.1+ no encontrado. Instalando..."

    # Añadir repositorio Sury
    if ! grep -r "sury" /etc/apt/sources.list.d/ >/dev/null 2>&1; then
        curl -sSL https://packages.sury.org/php/apt.gpg | gpg --dearmor -o /usr/share/keyrings/deb.sury.org-php.gpg
        echo "deb [signed-by=/usr/share/keyrings/deb.sury.org-php.gpg] https://packages.sury.org/php $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list
        apt-get update -y
    fi

    apt-get install -y php8.1-cli php8.1-gd php8.1-mysql php8.1-pdo \
        php8.1-mbstring php8.1-tokenizer php8.1-bcmath php8.1-xml \
        php8.1-curl php8.1-zip php8.1-intl php8.1-fpm php8.1-redis

    log_ok "PHP 8.1 instalado."
}

# ======================= PASO 3: MARIADB / MYSQL =======================

install_database() {
    log_step "PASO 3: Verificando base de datos (MariaDB/MySQL)"

    if command -v mariadb >/dev/null 2>&1 || command -v mysql >/dev/null 2>&1; then
        log_ok "MariaDB/MySQL ya está instalado."
    else
        log_info "Instalando MariaDB..."
        apt-get install -y mariadb-server mariadb-client
        systemctl enable mariadb
        systemctl start mariadb
        log_ok "MariaDB instalado."
    fi

    # Asegurar que está corriendo
    systemctl start mariadb 2>/dev/null || systemctl start mysql 2>/dev/null || true
}

configure_database() {
    log_step "PASO 3.1: Configurando base de datos para Pterodactyl"

    # Generar contraseñas si no se proporcionaron
    if [ -z "$DB_PASS" ]; then
        DB_PASS=$(gen_password)
    fi

    # Verificar si la base de datos ya existe
    if mysql -u root -e "USE $DB_NAME;" 2>/dev/null; then
        log_warn "La base de datos '$DB_NAME' ya existe. Omitiendo creación."
    else
        log_info "Creando base de datos '$DB_NAME' y usuario '$DB_USER'..."
        mysql -u root <<EOF
CREATE DATABASE $DB_NAME;
CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';
GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';
FLUSH PRIVILEGES;
EOF
        log_ok "Base de datos y usuario creados."
    fi
}

# ======================= PASO 4: REDIS =======================

install_redis() {
    log_step "PASO 4: Verificando Redis"

    if command -v redis-server >/dev/null 2>&1; then
        log_ok "Redis ya está instalado."
    else
        log_info "Instalando Redis..."
        apt-get install -y redis-server
        systemctl enable redis-server
        systemctl start redis-server
        log_ok "Redis instalado."
    fi

    # Asegurar que está corriendo
    systemctl start redis-server 2>/dev/null || true
}

# ======================= PASO 5: COMPOSER =======================

install_composer() {
    log_step "PASO 5: Verificando Composer"

    if command -v composer >/dev/null 2>&1; then
        log_ok "Composer ya está instalado."
    else
        log_info "Instalando Composer..."
        curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
        log_ok "Composer instalado."
    fi
}

# ======================= PASO 6: PTERODACTYL PANEL =======================

install_panel() {
    log_step "PASO 6: Verificando Panel de Pterodactyl"

    if [ -d "$PANEL_DIR" ] && [ -f "$PANEL_DIR/artisan" ]; then
        log_warn "El Panel ya está instalado en $PANEL_DIR. Omitiendo instalación."
        return
    fi

    log_info "Descargando Pterodactyl Panel v$PTERO_VERSION..."
    mkdir -p /var/www
    cd /var/www

    curl -Lo panel.tar.gz "https://github.com/pterodactyl/panel/releases/download/v$PTERO_VERSION/panel.tar.gz"
    tar -xzvf panel.tar.gz -C /var/www
    rm panel.tar.gz

    mv /var/www/pterodactyl "$PANEL_DIR" 2>/dev/null || true

    # Permisos
    chown -R $PANEL_USER:$PANEL_USER "$PANEL_DIR"
    chmod -R 755 "$PANEL_DIR"
    chown -R $PANEL_USER:$PANEL_USER "$PANEL_DIR/storage" "$PANEL_DIR/bootstrap/cache"

    # Composer install
    log_info "Instalando dependencias de Composer..."
    cd "$PANEL_DIR"
    composer install --no-dev --optimize-autoloader

    # Copiar entorno
    if [ ! -f "$PANEL_DIR/.env" ]; then
        cp "$PANEL_DIR/.env.example" "$PANEL_DIR/.env"
        cd "$PANEL_DIR"
        php artisan key:generate --force
    fi

    log_ok "Panel descargado y dependencias instaladas."
}

configure_panel() {
    log_step "PASO 6.1: Configurando el Panel"

    cd "$PANEL_DIR"

    # Configurar .env solo si no se ha configurado antes
    if grep -q "APP_URL=http://localhost" "$PANEL_DIR/.env" 2>/dev/null || [ ! -z "$USE_SSL" ]; then
        log_info "Configurando archivo .env..."

        local app_scheme="https"
        if [[ "$USE_SSL" == "n" || "$USE_SSL" == "N" ]]; then
            app_scheme="http"
        fi

        # Si ya existe .env, actualizar la URL
        if [ -f "$PANEL_DIR/.env" ]; then
            sed -i "s|APP_URL=.*|APP_URL=$app_scheme://$FQDN|g" "$PANEL_DIR/.env"
            sed -i "s|DB_DATABASE=.*|DB_DATABASE=$DB_NAME|g" "$PANEL_DIR/.env"
            sed -i "s|DB_USERNAME=.*|DB_USERNAME=$DB_USER|g" "$PANEL_DIR/.env"
            sed -i "s|DB_PASSWORD=.*|DB_PASSWORD=$DB_PASS|g" "$PANEL_DIR/.env"
            
            # Configurar cola y cache con Redis
            sed -i "s|QUEUE_CONNECTION=.*|QUEUE_CONNECTION=redis|g" "$PANEL_DIR/.env"
            sed -i "s|CACHE_STORE=.*|CACHE_STORE=redis|g" "$PANEL_DIR/.env" 2>/dev/null || \
            sed -i "s|CACHE_DRIVER=.*|CACHE_DRIVER=redis|g" "$PANEL_DIR/.env"
            sed -i "s|SESSION_DRIVER=.*|SESSION_DRIVER=redis|g" "$PANEL_DIR/.env"
        fi

        log_ok "Archivo .env configurado con APP_URL=$app_scheme://$FQDN"
    else
        log_warn "El archivo .env ya parece estar configurado. Omitiendo."
    fi

    # Migrar base de datos solo si no se ha migrado ya
    if ! mysql -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -e "SHOW TABLES LIKE 'users';" 2>/dev/null | grep -q "users"; then
        log_info "Ejecutando migraciones de base de datos..."
        php artisan migrate --force --seed
        log_ok "Migraciones completadas."
    else
        log_warn "La base de datos ya tiene tablas. Omitiendo migraciones."
    fi

    # Permisos finales
    chown -R $PANEL_USER:$PANEL_USER "$PANEL_DIR/storage" "$PANEL_DIR/bootstrap/cache"

    # Crear usuario admin si no existe
    log_info "Para crear un usuario administrador, ejecuta:"
    echo -e "  ${CYAN}cd $PANEL_DIR && php artisan p:user:make${NC}"
}

# ======================= PASO 7: NGINX =======================

install_nginx() {
    log_step "PASO 7: Verificando Nginx"

    # Detener Apache2 si está instalado y activo (causa común de fallo de puerto 80 en Debian)
    if systemctl is-active --quiet apache2 2>/dev/null; then
        log_info "Apache2 detectado activo en el puerto 80. Deteniendo y desactivando Apache2..."
        systemctl stop apache2 2>/dev/null || true
        systemctl disable apache2 2>/dev/null || true
    fi

    if command -v nginx >/dev/null 2>&1; then
        log_ok "Nginx ya está instalado."
    else
        log_info "Instalando Nginx..."
        apt-get install -y nginx
        systemctl enable nginx
        log_ok "Nginx instalado."
    fi

    systemctl start nginx 2>/dev/null || true
}

configure_nginx() {
    log_step "PASO 7.1: Configurando Nginx para Pterodactyl"

    local nginx_conf="/etc/nginx/sites-available/pterodactyl.conf"
    local nginx_enabled="/etc/nginx/sites-enabled/pterodactyl.conf"

    # Si el usuario quiere forzar cambios (cambiar entre IP y SSL), eliminamos el conf antiguo
    if [ -f "$nginx_conf" ]; then
        log_warn "Configuración de Nginx existente detectada. Re-configurando para aplicar los cambios de SSL/IP..."
        rm -f "$nginx_conf" "$nginx_enabled"
    fi

    if [[ "$USE_SSL" == "n" || "$USE_SSL" == "N" ]]; then
        # PLANTILLA SOLO POR IP (Sin SSL - Puerto 80 Directo)
        log_info "Generando plantilla Nginx para acceso directo por IP (Puerto 80)..."
        cat > "$nginx_conf" <<EOF
server {
    listen 80;
    listen [::]:80;
    server_name $FQDN;

    root $PANEL_DIR/public;
    index index.php index.html;

    client_max_body_size 100M;
    client_body_timeout 120s;

    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;

    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    gzip on;
    gzip_comp_level 5;
    gzip_min_length 256;
    gzip_proxied any;
    gzip_vary on;
    gzip_types
        application/atom+xml
        application/javascript
        application/json
        application/ld+json
        application/manifest+json
        application/rss+xml
        application/vnd.geo+json
        application/vnd.ms-fontobject
        application/x-font-ttf
        application/x-web-app-manifest+json
        application/xhtml+xml
        application/xml
        font/opentype
        image/bmp
        image/svg+xml
        image/x-icon
        text/cache-manifest
        text/css
        text/plain
        text/vcard
        text/vnd.rim.location.xloc
        text/vtt
        text/x-component
        text/x-cross-domain-policy;

    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header X-Robots-Tag none;
    add_header X-Download-Options noopen;
    add_header X-Permitted-Cross-Domain-Policies none;
    add_header Referrer-Policy no-referrer;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)\$;
        fastcgi_pass unix:/run/php/php8.1-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_buffer_size 16k;
        fastcgi_buffers 4 16k;
        fastcgi_read_timeout 300;
    }

    location ~ /\.ht {
        deny all;
    }

    location ~ /\.(?!well-known).* {
        deny all;
    }

    location ~* \.(?:css|js|jpg|jpeg|gif|png|ico|gz|svg|svgz|ttf|otf|woff|woff2|eot)\$ {
        expires 30d;
        access_log off;
        add_header Cache-Control "public";
    }
}
EOF
    else
        # PLANTILLA CON SSL / REDIRECCIÓN
        log_info "Generando plantilla Nginx estándar para Dominio con SSL..."
        cat > "$nginx_conf" <<EOF
server {
    listen 80;
    listen [::]:80;
    server_name $FQDN;
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name $FQDN;

    root $PANEL_DIR/public;
    index index.php index.html;

    # SSL (descomentar tras obtener certificados con certbot)
    # ssl_certificate /etc/letsencrypt/live/$FQDN/fullchain.pem;
    # ssl_certificate_key /etc/letsencrypt/live/$FQDN/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!eNULL:!EXPORT:!CAMELLIA:!DES:!MD5:!PSK:!RC4;
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 1d;

    client_max_body_size 100M;
    client_body_timeout 120s;

    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;

    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    gzip on;
    gzip_comp_level 5;
    gzip_min_length 256;
    gzip_proxied any;
    gzip_vary on;
    gzip_types
        application/atom+xml
        application/javascript
        application/json
        application/ld+json
        application/manifest+json
        application/rss+xml
        application/vnd.geo+json
        application/vnd.ms-fontobject
        application/x-font-ttf
        application/x-web-app-manifest+json
        application/xhtml+xml
        application/xml
        font/opentype
        image/bmp
        image/svg+xml
        image/x-icon
        text/cache-manifest
        text/css
        text/plain
        text/vcard
        text/vnd.rim.location.xloc
        text/vtt
        text/x-component
        text/x-cross-domain-policy;

    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header X-Robots-Tag none;
    add_header X-Download-Options noopen;
    add_header X-Permitted-Cross-Domain-Policies none;
    add_header Referrer-Policy no-referrer;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)\$;
        fastcgi_pass unix:/run/php/php8.1-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_buffer_size 16k;
        fastcgi_buffers 4 16k;
        fastcgi_read_timeout 300;
    }

    location ~ /\.ht {
        deny all;
    }

    location ~ /\.(?!well-known).* {
        deny all;
    }

    location ~* \.(?:css|js|jpg|jpeg|gif|png|ico|gz|svg|svgz|ttf|otf|woff|woff2|eot)\$ {
        expires 30d;
        access_log off;
        add_header Cache-Control "public";
    }
}
EOF
    fi

    ln -sf "$nginx_conf" "$nginx_enabled"

    # Eliminar sitio por defecto si existe
    rm -f /etc/nginx/sites-enabled/default

    # Test de configuración
    if nginx -t 2>/dev/null; then
        # Si Nginx está corriendo, recargar; de lo contrario, iniciar o reiniciar
        if systemctl is-active --quiet nginx; then
            systemctl reload nginx 2>/dev/null || systemctl restart nginx
        else
            systemctl start nginx
        fi
        log_ok "Nginx configurado y activo para $FQDN"
    else
        log_error "La configuración de Nginx tiene errores de sintaxis. Forzando reinicio para diagnóstico..."
        systemctl restart nginx
    fi
}

# ======================= PASO 8: SSL (Certbot) =======================

install_ssl() {
    log_step "PASO 8: Verificando SSL (Certbot)"

    if [ -d "/etc/letsencrypt/live/$FQDN" ]; then
        log_ok "Certificados SSL ya existen para $FQDN."
        return
    fi

    if ! command -v certbot >/dev/null 2>&1; then
        log_info "Instalando Certbot..."
        apt-get install -y certbot python3-certbot-nginx
        log_ok "Certbot instalado."
    fi

    log_warn "Para obtener certificados SSL, ejecuta manualmente:"
    echo -e "  ${CYAN}certbot --nginx -d $FQDN --non-interactive --agree-tos -m admin@$FQDN${NC}"
}

# ======================= PASO 9: SERVICIO PANEL =======================

setup_panel_service() {
    log_step "PASO 9: Configurando servicio del Panel (pteroq)"

    local service_file="/etc/systemd/system/${PANEL_SERVICE}.service"

    if [ -f "$service_file" ]; then
        log_warn "Servicio $PANEL_SERVICE ya existe. Omitiendo."
        return
    fi

    cat > "$service_file" <<EOF
[Unit]
Description=Pterodactyl Queue Worker
After=network.target

[Service]
User=$PANEL_USER
Group=$PANEL_USER
Restart=always
ExecStart=/usr/bin/php $PANEL_DIR/artisan queue:work --queue=high,standard,low --tries=3

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable $PANEL_SERVICE
    systemctl start $PANEL_SERVICE
    log_ok "Servicio $PANEL_SERVICE configurado e iniciado."
}

# ======================= PASO 10: CRON =======================

setup_cron() {
    log_step "PASO 10: Verificando cron de Pterodactyl"

    local cron_entry="* * * * * php $PANEL_DIR/artisan schedule:run >> /dev/null 2>&1"

    if crontab -u $PANEL_USER -l 2>/dev/null | grep -q "artisan schedule:run"; then
        log_warn "Cron de Pterodactyl ya configurado. Omitiendo."
        return
    fi

    (crontab -u $PANEL_USER -l 2>/dev/null; echo "$cron_entry") | crontab -u $PANEL_USER -
    log_ok "Cron configurado."
}

# ======================= PASO 11: WINGS (DAEMON) =======================

install_docker() {
    log_step "PASO 11: Verificando Docker"

    if command -v docker >/dev/null 2>&1; then
        log_ok "Docker ya está instalado."
    else
        log_info "Instalando Docker..."
        curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
        sh /tmp/get-docker.sh
        systemctl enable docker
        systemctl start docker
        log_ok "Docker instalado."
    fi

    systemctl start docker 2>/dev/null || true
}

install_wings() {
    log_step "PASO 12: Verificando Wings (Daemon)"

    if [ -f "/usr/local/bin/wings" ]; then
        log_warn "Wings ya está instalado. Omitiendo descarga."
    else
        log_info "Descargando Wings..."
        curl -Lo /usr/local/bin/wings "https://github.com/pterodactyl/wings/releases/latest/download/wings_linux_amd64"
        chmod +x /usr/local/bin/wings
        log_ok "Wings descargado."
    fi

    mkdir -p "$WINGS_DIR"

    # Servicio systemd para Wings
    local wings_service="/etc/systemd/system/${WINGS_SERVICE}.service"

    if [ -f "$wings_service" ]; then
        log_warn "Servicio $WINGS_SERVICE ya existe. Omitiendo."
    else
        cat > "$wings_service" <<EOF
[Unit]
Description=Pterodactyl Wings Daemon
After=docker.service
Requires=docker.service
PartOf=docker.service

[Service]
WorkingDirectory=$WINGS_DIR
ExecStart=/usr/local/bin/wings
Restart=on-failure
StartLimitInterval=300
StartLimitBurst=3
User=root

[Install]
WantedBy=multi-user.target
EOF
        systemctl daemon-reload
        systemctl enable $WINGS_SERVICE
        log_ok "Servicio $WINGS_SERVICE creado."
    fi

    log_warn "Recuerda obtener el archivo de configuración de Wings desde el Panel:"
    echo -e "  ${CYAN}1. Ve al Panel > Nodes > Create Node${NC}"
    echo -e "  ${CYAN}2. Descarga el config.yml y colócalo en $WINGS_DIR/config.yml${NC}"
    echo -e "  ${CYAN}3. Ejecuta: systemctl start wings${NC}"
}

# ======================= PASO 13: TEMA INFERNAL =======================

install_infernal_theme() {
    log_step "PASO 13: Instalando Tema Infernal Minecraft"

    local css_dir="$PANEL_DIR/public/themes/pterodactyl/css"
    local custom_css="$css_dir/infernal.css"
    local custom_js_dir="$PANEL_DIR/public/themes/pterodactyl/js"

    mkdir -p "$css_dir" "$custom_js_dir"

    # CSS del tema infernal
    if [ -f "$custom_css" ]; then
        log_warn "Tema Infernal ya instalado. Actualizando..."
    fi

    cat > "$custom_css" <<'CSSEOF'
/* ============================================================
   TEMA INFERNAL MINECRAFT - Pterodactyl Panel
   Estilo: Fuego, lava, nether, oscuro con detalles rojos
   ============================================================ */

@import url('https://fonts.googleapis.com/css2?family=Press+Start+2P&display=swap');

:root {
    --infernal-bg: #0a0000;
    --infernal-dark: #1a0500;
    --infernal-red: #ff3300;
    --infernal-orange: #ff6600;
    --infernal-yellow: #ffaa00;
    --infernal-lava: #cc2200;
    --infernal-ember: #ff4400;
    --infernal-text: #ffcc88;
    --infernal-glow: rgba(255, 68, 0, 0.6);
    --infernal-border: rgba(255, 102, 0, 0.3);
    --infernal-card: rgba(20, 5, 0, 0.92);
    --infernal-header: rgba(10, 0, 0, 0.97);
}

/* === FONDO ANIMADO DE LAVA === */
body {
    background: var(--infernal-bg) !important;
    background-image:
        radial-gradient(ellipse at 20% 80%, rgba(204, 34, 0, 0.15) 0%, transparent 50%),
        radial-gradient(ellipse at 80% 20%, rgba(255, 68, 0, 0.12) 0%, transparent 50%),
        radial-gradient(ellipse at 50% 50%, rgba(255, 102, 0, 0.08) 0%, transparent 60%),
        linear-gradient(180deg, #0a0000 0%, #1a0500 50%, #0a0000 100%) !important;
    background-attachment: fixed !important;
    background-size: 100% 100% !important;
    color: var(--infernal-text) !important;
    font-family: 'Segoe UI', Tahoma, sans-serif !important;
}

/* Efecto de brasas flotantes */
body::before {
    content: '';
    position: fixed;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    background-image:
        radial-gradient(2px 2px at 10% 20%, rgba(255, 100, 0, 0.8), transparent),
        radial-gradient(1px 1px at 30% 40%, rgba(255, 170, 0, 0.6), transparent),
        radial-gradient(2px 2px at 50% 70%, rgba(255, 68, 0, 0.7), transparent),
        radial-gradient(1px 1px at 70% 30%, rgba(255, 120, 0, 0.5), transparent),
        radial-gradient(2px 2px at 85% 60%, rgba(255, 80, 0, 0.6), transparent),
        radial-gradient(1px 1px at 15% 80%, rgba(255, 200, 0, 0.4), transparent),
        radial-gradient(2px 2px at 60% 10%, rgba(255, 50, 0, 0.7), transparent),
        radial-gradient(1px 1px at 90% 90%, rgba(255, 150, 0, 0.5), transparent);
    background-size: 200% 200%;
    animation: infernal-embers 20s linear infinite;
    pointer-events: none;
    z-index: 0;
    opacity: 0.6;
}

@keyframes infernal-embers {
    0% { background-position: 0% 0%; }
    100% { background-position: 0% -200%; }
}

/* === HEADER / NAVBAR === */
.navbar, .header, .main-header {
    background: var(--infernal-header) !important;
    border-bottom: 2px solid var(--infernal-red) !important;
    box-shadow: 0 0 20px rgba(255, 51, 0, 0.3) !important;
}

.navbar-brand, .logo-text, .header .logo {
    color: var(--infernal-orange) !important;
    text-shadow: 0 0 10px var(--infernal-glow) !important;
    font-weight: bold !important;
}

.navbar-nav > li > a, .nav-link {
    color: var(--infernal-text) !important;
    transition: all 0.3s ease !important;
}

.navbar-nav > li > a:hover, .nav-link:hover {
    color: var(--infernal-yellow) !important;
    text-shadow: 0 0 8px var(--infernal-glow) !important;
}

/* === CARDS / CONTENEDORES === */
.card, .panel, .box, .well {
    background: var(--infernal-card) !important;
    border: 1px solid var(--infernal-border) !important;
    border-radius: 8px !important;
    box-shadow: 0 4px 15px rgba(0, 0, 0, 0.5), 0 0 10px rgba(255, 68, 0, 0.1) !important;
    backdrop-filter: blur(5px) !important;
    transition: all 0.3s ease !important;
}

.card:hover, .panel:hover {
    border-color: var(--infernal-orange) !important;
    box-shadow: 0 4px 20px rgba(0, 0, 0, 0.6), 0 0 20px rgba(255, 68, 0, 0.2) !important;
}

.card-header, .panel-heading, .box-header {
    background: linear-gradient(135deg, rgba(255, 51, 0, 0.15), rgba(255, 102, 0, 0.05)) !important;
    border-bottom: 1px solid var(--infernal-border) !important;
    color: var(--infernal-orange) !important;
    text-shadow: 0 0 5px var(--infernal-glow) !important;
}

.card-title, .panel-title {
    color: var(--infernal-yellow) !important;
}

/* === BOTONES === */
.btn-primary, .btn-success {
    background: linear-gradient(135deg, var(--infernal-red), var(--infernal-orange)) !important;
    border: 1px solid var(--infernal-orange) !important;
    color: #fff !important;
    text-shadow: 0 1px 2px rgba(0, 0, 0, 0.5) !important;
    box-shadow: 0 0 10px rgba(255, 68, 0, 0.3) !important;
    transition: all 0.3s ease !important;
}

.btn-primary:hover, .btn-success:hover {
    background: linear-gradient(135deg, var(--infernal-orange), var(--infernal-yellow)) !important;
    box-shadow: 0 0 20px rgba(255, 102, 0, 0.5) !important;
    transform: translateY(-1px) !important;
}

.btn-default, .btn-secondary {
    background: rgba(20, 5, 0, 0.8) !important;
    border: 1px solid var(--infernal-border) !important;
    color: var(--infernal-text) !important;
}

.btn-default:hover, .btn-secondary:hover {
    background: rgba(40, 10, 0, 0.9) !important;
    border-color: var(--infernal-orange) !important;
    color: var(--infernal-yellow) !important;
}

.btn-danger {
    background: linear-gradient(135deg, #cc0000, #ff0000) !important;
    border: 1px solid #ff3333 !important;
    box-shadow: 0 0 10px rgba(204, 0, 0, 0.4) !important;
}

/* === TABLAS === */
.table, .table-striped {
    color: var(--infernal-text) !important;
}

.table > thead > tr > th, .table-striped > thead > tr > th {
    background: rgba(255, 51, 0, 0.1) !important;
    border-bottom: 2px solid var(--infernal-red) !important;
    color: var(--infernal-orange) !important;
}

.table-striped > tbody > tr:nth-of-type(odd) {
    background: rgba(20, 5, 0, 0.5) !important;
}

.table-striped > tbody > tr:nth-of-type(even) {
    background: rgba(10, 0, 0, 0.3) !important;
}

.table > tbody > tr > td {
    border-top: 1px solid var(--infernal-border) !important;
}

.table-hover > tbody > tr:hover {
    background: rgba(255, 68, 0, 0.1) !important;
}

/* === FORMULARIOS === */
input[type="text"], input[type="email"], input[type="password"],
input[type="search"], input[type="number"], textarea, select,
.form-control {
    background: rgba(10, 0, 0, 0.7) !important;
    border: 1px solid var(--infernal-border) !important;
    color: var(--infernal-text) !important;
    border-radius: 4px !important;
    transition: all 0.3s ease !important;
}

input:focus, textarea:focus, select:focus, .form-control:focus {
    border-color: var(--infernal-orange) !important;
    box-shadow: 0 0 10px rgba(255, 102, 0, 0.3) !important;
    background: rgba(20, 5, 0, 0.8) !important;
}

input::placeholder, textarea::placeholder {
    color: rgba(255, 204, 136, 0.4) !important;
}

/* === BADGES / ETIQUETAS === */
.badge, .label {
    background: var(--infernal-red) !important;
    color: #fff !important;
    text-shadow: 0 1px 1px rgba(0, 0, 0, 0.5) !important;
}

.badge-success, .label-success {
    background: linear-gradient(135deg, #ff6600, #ffaa00) !important;
}

.badge-danger, .label-danger {
    background: linear-gradient(135deg, #cc0000, #ff0000) !important;
}

/* === ALERTAS === */
.alert {
    border-radius: 6px !important;
    backdrop-filter: blur(5px) !important;
}

.alert-info {
    background: rgba(255, 102, 0, 0.15) !important;
    border: 1px solid var(--infernal-orange) !important;
    color: var(--infernal-yellow) !important;
}

.alert-success {
    background: rgba(0, 200, 0, 0.1) !important;
    border: 1px solid #00cc44 !important;
    color: #66ff99 !important;
}

.alert-danger, .alert-error {
    background: rgba(204, 0, 0, 0.15) !important;
    border: 1px solid #ff0000 !important;
    color: #ff6666 !important;
}

/* === SIDEBAR === */
.sidebar, .main-sidebar {
    background: var(--infernal-dark) !important;
    border-right: 1px solid var(--infernal-border) !important;
}

.sidebar-menu > li > a, .sidebar a {
    color: var(--infernal-text) !important;
    transition: all 0.3s ease !important;
}

.sidebar-menu > li > a:hover, .sidebar a:hover {
    background: rgba(255, 68, 0, 0.15) !important;
    color: var(--infernal-yellow) !important;
    border-left: 3px solid var(--infernal-orange) !important;
}

.sidebar-menu > li.active > a, .sidebar .active a {
    background: rgba(255, 51, 0, 0.2) !important;
    color: var(--infernal-orange) !important;
    border-left: 3px solid var(--infernal-red) !important;
}

/* === FOOTER === */
footer, .main-footer {
    background: var(--infernal-header) !important;
    border-top: 2px solid var(--infernal-red) !important;
    color: var(--infernal-text) !important;
}

/* === SCROLLBAR === */
::-webkit-scrollbar {
    width: 10px;
    height: 10px;
}

::-webkit-scrollbar-track {
    background: var(--infernal-dark) !important;
}

::-webkit-scrollbar-thumb {
    background: linear-gradient(180deg, var(--infernal-red), var(--infernal-orange)) !important;
    border-radius: 5px !important;
}

::-webkit-scrollbar-thumb:hover {
    background: linear-gradient(180deg, var(--infernal-orange), var(--infernal-yellow)) !important;
}

/* === MODAL === */
.modal-content, .modal-dialog .modal-content {
    background: var(--infernal-card) !important;
    border: 1px solid var(--infernal-orange) !important;
    box-shadow: 0 0 30px rgba(255, 68, 0, 0.3) !important;
}

.modal-header {
    border-bottom: 1px solid var(--infernal-border) !important;
}

.modal-title {
    color: var(--infernal-orange) !important;
}

.modal-footer {
    border-top: 1px solid var(--infernal-border) !important;
}

/* === LOGIN === */
.login-box, .register-box {
    background: var(--infernal-card) !important;
    border: 1px solid var(--infernal-orange) !important;
    border-radius: 12px !important;
    box-shadow: 0 0 40px rgba(255, 68, 0, 0.2) !important;
    backdrop-filter: blur(10px) !important;
}

.login-logo a, .register-logo a {
    color: var(--infernal-orange) !important;
    text-shadow: 0 0 15px var(--infernal-glow) !important;
    font-size: 28px !important;
}

/* === PROGRESS BAR === */
.progress {
    background: var(--infernal-dark) !important;
    border: 1px solid var(--infernal-border) !important;
    border-radius: 4px !important;
}

.progress-bar {
    background: linear-gradient(90deg, var(--infernal-red), var(--infernal-orange), var(--infernal-yellow)) !important;
    box-shadow: 0 0 10px var(--infernal-glow) !important;
}

/* === DROPDOWN === */
.dropdown-menu {
    background: var(--infernal-dark) !important;
    border: 1px solid var(--infernal-border) !important;
    box-shadow: 0 4px 20px rgba(0, 0, 0, 0.6) !important;
}

.dropdown-menu > li > a, .dropdown-item {
    color: var(--infernal-text) !important;
}

.dropdown-menu > li > a:hover, .dropdown-item:hover {
    background: rgba(255, 68, 0, 0.15) !important;
    color: var(--infernal-yellow) !important;
}

/* === TABS / PILLS === */
.nav-tabs > li > a, .nav-pills > li > a {
    color: var(--infernal-text) !important;
    border: 1px solid transparent !important;
}

.nav-tabs > li.active > a, .nav-pills > li.active > a {
    background: var(--infernal-card) !important;
    border: 1px solid var(--infernal-orange) !important;
    color: var(--infernal-orange) !important;
}

/* === PAGINATION === */
.pagination > li > a, .pagination > li > span {
    background: var(--infernal-dark) !important;
    border: 1px solid var(--infernal-border) !important;
    color: var(--infernal-text) !important;
}

.pagination > li > a:hover {
    background: rgba(255, 68, 0, 0.15) !important;
    border-color: var(--infernal-orange) !important;
    color: var(--infernal-yellow) !important;
}

.pagination > .active > a {
    background: linear-gradient(135deg, var(--infernal-red), var(--infernal-orange)) !important;
    border-color: var(--infernal-orange) !important;
}

/* === TEXTOS === */
h1, h2, h3, h4, h5, h6 {
    color: var(--infernal-orange) !important;
    text-shadow: 0 0 5px rgba(255, 68, 0, 0.2) !important;
}

a {
    color: var(--infernal-orange) !important;
    transition: all 0.3s ease !important;
}

a:hover {
    color: var(--infernal-yellow) !important;
    text-shadow: 0 0 8px var(--infernal-glow) !important;
}

.text-muted {
    color: rgba(255, 204, 136, 0.5) !important;
}

/* === CONSOLE TERMINAL === */
.console-output, .terminal-output, pre {
    background: #000 !important;
    color: var(--infernal-orange) !important;
    border: 1px solid var(--infernal-border) !important;
    font-family: 'Consolas', 'Courier New', monospace !important;
    text-shadow: 0 0 5px rgba(255, 102, 0, 0.3) !important;
}

/* === SERVER CARDS === */
.server-card, .server-box {
    border: 1px solid var(--infernal-border) !important;
    background: var(--infernal-card) !important;
    transition: all 0.3s ease !important;
}

.server-card:hover {
    border-color: var(--infernal-red) !important;
    box-shadow: 0 0 25px rgba(255, 51, 0, 0.3) !important;
    transform: translateY(-2px) !important;
}

/* === EMOJI FIRE ICON === */
.login-logo a::before {
    content: "🔥 ";
}

/* === ANIMACIÓN PULSO PARA ELEMENTOS IMPORTANTES === */
@keyframes infernal-pulse {
    0%, 100% { box-shadow: 0 0 10px rgba(255, 68, 0, 0.3); }
    50% { box-shadow: 0 0 20px rgba(255, 68, 0, 0.6); }
}

.btn-primary, .login-box {
    animation: infernal-pulse 3s ease-in-out infinite;
}

/* === RESPONSIVE === */
@media (max-width: 768px) {
    .login-box, .register-box {
        margin: 20px !important;
    }
}
CSSEOF

    chown -R $PANEL_USER:$PANEL_USER "$css_dir"

    # Inyectar el CSS en las plantillas blade
    inject_css_into_templates

    # Crear JS para efectos adicionales (partículas de fuego)
    cat > "$custom_js_dir/infernal.js" <<'JSEOF'
// ============================================================
//  TEMA INFERNAL - Efectos de partículas de fuego
// ============================================================
(function() {
    'use strict';

    // Crear canvas para partículas de fuego
    const canvas = document.createElement('canvas');
    canvas.id = 'infernal-canvas';
    canvas.style.cssText = 'position:fixed;top:0;left:0;width:100%;height:100%;pointer-events:none;z-index:1;opacity:0.4;';
    document.body.appendChild(canvas);

    const ctx = canvas.getContext('2d');
    let particles = [];

    function resizeCanvas() {
        canvas.width = window.innerWidth;
        canvas.height = window.innerHeight;
    }
    resizeCanvas();
    window.addEventListener('resize', resizeCanvas);

    // Clase de partícula de fuego
    class FireParticle {
        constructor() {
            this.reset();
        }

        reset() {
            this.x = Math.random() * canvas.width;
            this.y = canvas.height + Math.random() * 50;
            this.vx = (Math.random() - 0.5) * 0.5;
            this.vy = -Math.random() * 2 - 0.5;
            this.size = Math.random() * 3 + 1;
            this.life = 1;
            this.decay = Math.random() * 0.005 + 0.002;
            const colors = ['#ff3300', '#ff6600', '#ffaa00', '#ff4400', '#cc2200'];
            this.color = colors[Math.floor(Math.random() * colors.length)];
        }

        update() {
            this.x += this.vx;
            this.y += this.vy;
            this.vy -= 0.01;
            this.life -= this.decay;
            if (this.life <= 0 || this.y < -10) {
                this.reset();
            }
        }

        draw() {
            ctx.save();
            ctx.globalAlpha = this.life;
            ctx.fillStyle = this.color;
            ctx.shadowBlur = 10;
            ctx.shadowColor = this.color;
            ctx.beginPath();
            ctx.arc(this.x, this.y, this.size, 0, Math.PI * 2);
            ctx.fill();
            ctx.restore();
        }
    }

    // Crear partículas
    const particleCount = 60;
    for (let i = 0; i < particleCount; i++) {
        particles.push(new FireParticle());
    }

    // Animar
    function animate() {
        ctx.clearRect(0, 0, canvas.width, canvas.height);
        particles.forEach(p => {
            p.update();
            p.draw();
        });
        requestAnimationFrame(animate);
    }
    animate();

    // Cambiar el título de la pestaña
    document.title = document.title.replace(/Pterodactyl/g, '🔥 Pterodactyl');

    // Efecto de hover en cards - brillo de fuego
    document.querySelectorAll('.card, .panel, .server-card').forEach(el => {
        el.addEventListener('mouseenter', function() {
            this.style.borderColor = '#ff6600';
        });
        el.addEventListener('mouseleave', function() {
            this.style.borderColor = '';
        });
    });

    console.log('%c🔥 TEMA INFERNAL MINECRAFT ACTIVADO 🔥', 'color: #ff6600; font-size: 16px; font-weight: bold; text-shadow: 0 0 10px #ff4400;');
})();
JSEOF

    chown -R $PANEL_USER:$PANEL_USER "$custom_js_dir"

    log_ok "Tema Infernal instalado en $custom_css"
}

inject_css_into_templates() {
    log_info "Inyectando CSS y JS en las plantillas Blade..."

    # Buscar el layout principal y añadir el CSS/JS (incluye el wrapper de React v1.x y auth)
    local layouts=(
        "$PANEL_DIR/resources/views/layouts/admin.blade.php"
        "$PANEL_DIR/resources/views/layouts/base.blade.php"
        "$PANEL_DIR/resources/views/layouts/app.blade.php"
        "$PANEL_DIR/resources/views/templates/wrapper.blade.php"
        "$PANEL_DIR/resources/views/templates/auth.blade.php"
    )

    for layout in "${layouts[@]}"; do
        if [ -f "$layout" ] && ! grep -q "infernal.css" "$layout"; then
            # Insertar CSS antes de </head>
            sed -i '/<\/head>/i \
    <link rel="stylesheet" href="/themes/pterodactyl/css/infernal.css">' "$layout"

            # Insertar JS antes de </body>
            sed -i '/<\/body>/i \
    <script src="/themes/pterodactyl/js/infernal.js"></script>' "$layout"

            log_ok "Inyectado en $layout"
        fi
    done

    # Limpiar caché de vistas
    cd "$PANEL_DIR"
    php artisan view:clear 2>/dev/null || true
    php artisan config:clear 2>/dev/null || true
}

# ======================= PASO 14: PERMISOS Y OPTIMIZACIÓN =======================

final_optimization() {
    log_step "PASO 14: Optimización final"

    cd "$PANEL_DIR"

    # Permisos
    chown -R $PANEL_USER:$PANEL_USER "$PANEL_DIR/storage" "$PANEL_DIR/bootstrap/cache"
    find "$PANEL_DIR/storage" -type d -exec chmod 755 {} \; 2>/dev/null || true
    find "$PANEL_DIR/storage" -type f -exec chmod 644 {} \; 2>/dev/null || true

    # Optimizar
    php artisan config:cache 2>/dev/null || true
    php artisan route:cache 2>/dev/null || true
    php artisan view:cache 2>/dev/null || true

    # Reiniciar servicios
    systemctl restart php8.1-fpm 2>/dev/null || true
    systemctl restart nginx 2>/dev/null || true
    systemctl restart $PANEL_SERVICE 2>/dev/null || true

    log_ok "Optimización completada."
}

# ======================= RESUMEN FINAL =======================

print_summary() {
    local app_scheme="https"
    if [[ "$USE_SSL" == "n" || "$USE_SSL" == "N" ]]; then
        app_scheme="http"
    fi

    echo ""
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${ORANGE}  🔥 INSTALACIÓN COMPLETADA - TEMA INFERNAL 🔥${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "  ${CYAN}Panel:${NC}        $app_scheme://$FQDN"
    echo -e "  ${CYAN}Directorio:${NC}   $PANEL_DIR"
    echo -e "  ${CYAN}Base de datos:${NC} $DB_NAME (usuario: $DB_USER)"
    echo -e "  ${CYAN}DB Password:${NC}  $DB_PASS"
    echo ""
    echo -e "  ${YELLOW}Pasos pendientes manuales:${NC}"
    echo -e "  1. Crear usuario admin: ${CYAN}cd $PANEL_DIR && php artisan p:user:make${NC}"
    if [[ "$USE_SSL" != "n" && "$USE_SSL" != "N" ]]; then
        echo -e "  2. Obtener SSL:         ${CYAN}certbot --nginx -d $FQDN${NC}"
    else
        echo -e "  2. Obtener SSL:         ${YELLOW}[OMITIDO - Modo Solo IP sin SSL]${NC}"
    fi
    echo -e "  3. Configurar Wings:    Copiar config.yml a $WINGS_DIR/"
    echo -e "  4. Iniciar Wings:       ${CYAN}systemctl start wings${NC}"
    echo ""
    echo -e "  ${GREEN}Tema Infernal Minecraft aplicado automáticamente.${NC}"
    echo ""
}

# ======================= MENÚ INTERACTIVO =======================

show_menu() {
    echo -e "${ORANGE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${ORANGE}  🔥 SELECCIONA UNA OPCIÓN 🔥${NC}"
    echo -e "${ORANGE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "  ${RED}1)${NC} ${CYAN}Instalación COMPLETA${NC} (Pterodactyl + Wings + Tema Infernal)"
    echo -e "     Instala todo desde cero con el tema aplicado"
    echo ""
    echo -e "  ${RED}2)${NC} ${CYAN}Solo Tema Infernal${NC} (fondo + efectos de fuego)"
    echo -e "     Aplica solo el tema sobre un panel ya instalado"
    echo ""
    echo -e "  ${RED}3)${NC} ${CYAN}Solo Pterodactyl${NC} (sin tema infernal)"
    echo -e "     Instala el panel + wings sin el tema visual"
    echo ""
    echo -e "  ${RED}4)${NC} ${CYAN}Configurar panel existente${NC} (Nginx + SSL + servicios)"
    echo -e "     Configura servicios para un panel ya descargado"
    echo ""
    echo -e "  ${RED}5)${NC} ${YELLOW}Salir${NC}"
    echo ""
    echo -e "${ORANGE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    read -p "  Selecciona una opción [1-5]: " menu_option
    echo ""
}

# ======================= RECOLECCIÓN DE DATOS =======================

collect_info() {
    echo -e "${ORANGE}Configuración inicial:${NC}"
    echo ""

    read -p "Dominio o IP del panel (por defecto: $FQDN): " input_fqdn
    FQDN="${input_fqdn:-$FQDN}"

    read -p "¿Deseas usar Dominio con SSL? (s/n, s = SSL, n = Solo IP sin SSL, por defecto s): " input_ssl
    USE_SSL="${input_ssl:-s}"

    read -p "Contraseña BD (vacío = auto-generar): " input_dbpass
    DB_PASS="$input_dbpass"

    local app_scheme="https"
    if [[ "$USE_SSL" == "n" || "$USE_SSL" == "N" ]]; then
        app_scheme="http"
    fi

    echo ""
    log_info "URL del panel: $app_scheme://$FQDN"
    log_info "BD: $DB_NAME / Usuario: $DB_USER"
    echo ""
    read -p "¿Continuar con la instalación? (s/n): " confirm
    if [[ "$confirm" != "s" && "$confirm" != "S" ]]; then
        log_error "Instalación cancelada."
        exit 0
    fi
}

collect_info_theme_only() {
    echo -e "${ORANGE}Configuración del tema:${NC}"
    echo ""

    # Detectar automáticamente el directorio del panel
    if [ -d "/var/www/pterodactyl" ] && [ -f "/var/www/pterodactyl/artisan" ]; then
        PANEL_DIR="/var/www/pterodactyl"
        log_ok "Panel detectado en: $PANEL_DIR"
    else
        read -p "Ruta del panel Pterodactyl (por defecto: /var/www/pterodactyl): " input_dir
        PANEL_DIR="${input_dir:-/var/www/pterodactyl}"

        if [ ! -f "$PANEL_DIR/artisan" ]; then
            log_error "No se encontró el panel en $PANEL_DIR. ¿Está instalado Pterodactyl?"
            exit 1
        fi
    fi

    echo ""
    echo -e "  ${CYAN}El tema Infernal incluye:${NC}"
    echo -e "  - Fondo oscuro con gradientes de lava"
    echo -e "  - Brasas flotantes animadas (CSS)"
    echo -e "  - Partículas de fuego (Canvas JS)"
    echo -e "  - Botones, cards y UI con estilo infernal"
    echo -e "  - Scrollbar personalizada"
    echo -e "  - Consola con texto naranja brillante"
    echo ""
    read -p "¿Aplicar tema completo (CSS + JS)? (s/n, por defecto s): " theme_full
    APPLY_JS="${theme_full:-s}"
    echo ""
    read -p "¿Continuar con la aplicación del tema? (s/n): " confirm
    if [[ "$confirm" != "s" && "$confirm" != "S" ]]; then
        log_error "Operación cancelada."
        exit 0
    fi
}

# ======================= FLUJOS DE INSTALACIÓN =======================

run_full_install() {
    log_step "INSTALACIÓN COMPLETA: Pterodactyl + Wings + Tema Infernal"
    collect_info

    install_dependencies
    install_php
    install_database
    configure_database
    install_redis
    install_composer
    install_panel
    configure_panel
    install_nginx
    configure_nginx
    install_ssl
    setup_panel_service
    setup_cron
    install_docker
    install_wings
    install_infernal_theme
    final_optimization

    print_summary
}

run_theme_only() {
    log_step "SOLO TEMA INFERNAL: Aplicando fondo y efectos"
    collect_info_theme_only

    # Verificar dependencias mínimas para inyectar CSS/JS
    if ! command -v php >/dev/null 2>&1; then
        log_warn "PHP no detectado. Instalando PHP mínimo para limpiar caché..."
        install_dependencies
        install_php
    fi

    install_infernal_theme
    final_optimization

    echo ""
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${ORANGE}  🔥 TEMA INFERNAL APLICADO CORRECTAMENTE 🔥${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "  ${CYAN}Panel:${NC}      $PANEL_DIR"
    echo -e "  ${CYAN}CSS:${NC}        $PANEL_DIR/public/themes/pterodactyl/css/infernal.css"
    echo -e "  ${CYAN}JS:${NC}         $PANEL_DIR/public/themes/pterodactyl/js/infernal.js"
    echo ""
    echo -e "  ${GREEN}Recarga tu panel en el navegador para ver el tema.${NC}"
    echo ""
}

run_panel_only() {
    log_step "SOLO PTERODACTYL: Panel + Wings (sin tema)"
    collect_info

    install_dependencies
    install_php
    install_database
    configure_database
    install_redis
    install_composer
    install_panel
    configure_panel
    install_nginx
    configure_nginx
    install_ssl
    setup_panel_service
    setup_cron
    install_docker
    install_wings
    final_optimization

    print_summary
}

run_configure_only() {
    log_step "CONFIGURAR PANEL EXISTENTE: Nginx + SSL + Servicios"
    collect_info

    if [ ! -d "$PANEL_DIR" ] || [ ! -f "$PANEL_DIR/artisan" ]; then
        log_error "No se encontró el panel en $PANEL_DIR. Instala el panel primero."
        exit 1
    fi

    install_nginx
    configure_nginx
    install_ssl
    setup_panel_service
    setup_cron
    final_optimization

    print_summary
}

# ======================= MAIN =======================

main() {
    print_banner
    check_root
    check_debian
    show_menu

    case "$menu_option" in
        1)
            run_full_install
            ;;
        2)
            run_theme_only
            ;;
        3)
            run_panel_only
            ;;
        4)
            run_configure_only
            ;;
        5)
            log_info "Saliendo... ¡Hasta pronto! 🔥"
            exit 0
            ;;
        *)
            log_error "Opción no válida. Selecciona 1-5."
            exit 1
            ;;
    esac
}

main "$@"
