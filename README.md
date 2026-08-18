# 🔥 Pterodactyl Panel - Tema Infernal Minecraft

Instalador automático para **Pterodactyl Panel + Wings** con tema visual **Infernal Minecraft** (estilo Nether/fuego/lava).

## 📋 Requisitos

- **Debian 11 o 12** (Bullseye / Bookworm)
- Acceso **root** (sudo)
- Mínimo **2GB RAM** (recomendado 4GB+)
- Puerto 80/443 libres para el panel

## 🚀 Instalación rápida

```bash
# 1. Subir el script al servidor
scp install.sh root@tu-servidor:/root/

# 2. Dar permisos de ejecución
chmod +x install.sh

# 3. Ejecutar
sudo ./install.sh
```

El script te pedirá:
- **Dominio o IP** del panel (ej: `panel.miservidor.com`)
- **Contraseña de BD** (puedes dejar vacío para auto-generar)

## ✨ Qué instala el script

| Componente | Descripción |
|---|---|
| **Dependencias** | curl, wget, git, jq, htop, etc. |
| **PHP 8.1** | Con todas las extensiones requeridas |
| **MariaDB** | Base de datos del panel |
| **Redis** | Cache y colas |
| **Composer** | Gestor de dependencias PHP |
| **Pterodactyl Panel** | Panel web v1.11.x |
| **Nginx** | Servidor web con configuración optimizada |
| **Certbot/SSL** | Para HTTPS (requiere ejecución manual) |
| **Servicio pteroq** | Worker de colas del panel |
| **Cron** | Tareas programadas del panel |
| **Docker** | Para Wings |
| **Wings** | Daemon de servidores de juego |
| **Tema Infernal** | CSS + JS con efectos de fuego |

## 🔄 Idempotencia

El script **detecta lo ya instalado** y lo omite:

- Si PHP 8.1+ ya está instalado → solo instala extensiones faltantes
- Si MariaDB ya está → solo configura la BD si no existe
- Si Redis ya está → lo omite
- Si Composer ya está → lo omite
- Si el Panel ya está en `/var/www/pterodactyl` → lo omite
- Si la BD ya tiene tablas → omite migraciones
- Si Nginx ya tiene config de Pterodactyl → la omite
- Si los certificados SSL ya existen → los omite
- Si el servicio `pteroq` ya existe → lo omite
- Si el cron ya está configurado → lo omite
- Si Docker ya está → lo omite
- Si Wings ya está descargado → lo omite
- Si el tema Infernal ya está → lo actualiza

**Puedes ejecutar el script las veces que quieras sin romper nada.**

## 🎨 Tema Infernal Minecraft

El tema incluye:

- **Fondo oscuro** con gradientes de lava (rojo/naranja)
- **Brasas flotantes** animadas con CSS
- **Partículas de fuego** con canvas JavaScript
- **Botones con gradiente** de fuego y efecto glow
- **Cards/paneles** semi-transparentes con blur
- **Scrollbar personalizada** en colores de fuego
- **Consola de servidores** con texto naranja brillante
- **Animación de pulso** en elementos importantes
- **Login con icono de fuego** 🔥

### Instalación manual del tema (sin script)

Si ya tienes Pterodactyl instalado y solo quieres el tema:

```bash
# Copiar CSS
cp infernal.css /var/www/pterodactyl/public/themes/pterodactyl/css/infernal.css

# Copiar JS
cp infernal.js /var/www/pterodactyl/public/themes/pterodactyl/js/infernal.js

# Permisos
chown -R www-data:www-data /var/www/pterodactyl/public/themes/pterodactyl/css/
chown -R www-data:www-data /var/www/pterodactyl/public/themes/pterodactyl/js/

# Añadir a las plantillas blade (antes de </head>):
# <link rel="stylesheet" href="/themes/pterodactyl/css/infernal.css">
#
# Y antes de </body>:
# <script src="/themes/pterodactyl/js/infernal.js"></script>

# Limpiar caché
cd /var/www/pterodactyl
php artisan view:clear
php artisan config:clear
```

## 📝 Pasos manuales después de la instalación

1. **Crear usuario administrador:**
   ```bash
   cd /var/www/pterodactyl
   php artisan p:user:make
   ```

2. **Obtener certificados SSL:**
   ```bash
   certbot --nginx -d panel.miservidor.com
   ```

3. **Configurar Wings:**
   - Ve al Panel → Nodes → Create Node
   - Descarga el `config.yml`
   - Cópiarlo a `/etc/pterodactyl/config.yml`
   - Iniciar: `systemctl start wings`

4. **Verificar servicios:**
   ```bash
   systemctl status nginx
   systemctl status php8.1-fpm
   systemctl status pteroq
   systemctl status mariadb
   systemctl status redis-server
   systemctl status wings
   ```

## 📂 Estructura del proyecto

```
pterodactyl-infernal/
├── install.sh       # Script de instalación automática
├── infernal.css     # Tema CSS standalone
├── infernal.js      # Efectos JS standalone
└── README.md        # Este archivo
```

## ⚠️ Notas

- El script está diseñado para **Debian 11/12** exclusivamente
- La versión del Panel por defecto es **1.11.11** (editable en el script)
- Las contraseñas de BD se auto-generan si no se proporcionan
- El script guarda la contraseña de BD en el resumen final
- Para producción, cambia siempre las contraseñas auto-generadas
