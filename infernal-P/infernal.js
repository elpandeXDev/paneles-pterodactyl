// ============================================================
//  TEMA INFERNAL MINECRAFT - Animación de Volcanes y Erupciones
//  Compatible con React y Blade, inyectado de fondo
// ============================================================
(function() {
    'use strict';

    // Verificar si ya existe el canvas
    if (document.getElementById('infernal-canvas')) return;

    // Crear canvas para partículas y volcanes
    const canvas = document.createElement('canvas');
    canvas.id = 'infernal-canvas';
    // Colocarlo bien atrás (z-index: -1) y que deje pasar clics (pointer-events: none)
    canvas.style.cssText = 'position:fixed;top:0;left:0;width:100%;height:100%;pointer-events:none;z-index:-1;opacity:0.65;';
    document.body.appendChild(canvas);

    const ctx = canvas.getContext('2d');
    let particles = [];
    let volcanoes = [];

    function resizeCanvas() {
        canvas.width = window.innerWidth;
        canvas.height = window.innerHeight;
        initVolcanoes(); // Recalcular volcanes al redimensionar
    }

    // Estructura de volcán
    class Volcano {
        constructor(x, width, height, type) {
            this.x = x;
            this.width = width;
            this.height = height;
            this.type = type; // 'active' o 'background'
            this.lastEruption = Date.now();
            this.eruptionInterval = type === 'active' ? Math.random() * 4000 + 3000 : 999999;
        }

        draw() {
            ctx.save();
            
            // Gradiente para el volcán (roca del nether / magma fría)
            const grad = ctx.createLinearGradient(this.x, canvas.height - this.height, this.x, canvas.height);
            if (this.type === 'active') {
                grad.addColorStop(0, '#3a0c02'); // Cráter rojo
                grad.addColorStop(0.3, '#1c0500');
                grad.addColorStop(1, '#0c0000');
            } else {
                grad.addColorStop(0, '#1c0500'); // Volcán de fondo
                grad.addColorStop(1, '#050000');
            }

            ctx.fillStyle = grad;
            ctx.beginPath();
            
            // Dibujar volcán estilizado estilo Minecraft (siluetas poligonales escalonadas)
            ctx.moveTo(this.x - this.width / 2, canvas.height);
            ctx.lineTo(this.x - this.width * 0.15, canvas.height - this.height * 0.9);
            ctx.lineTo(this.x - this.width * 0.08, canvas.height - this.height); // Cráter izquierdo
            ctx.lineTo(this.x + this.width * 0.08, canvas.height - this.height); // Cráter derecho
            ctx.lineTo(this.x + this.width * 0.15, canvas.height - this.height * 0.9);
            ctx.lineTo(this.x + this.width / 2, canvas.height);
            ctx.closePath();
            ctx.fill();

            // Dibujar magma brillando en el cráter de los volcanes activos
            if (this.type === 'active') {
                ctx.fillStyle = '#ff3300';
                ctx.shadowBlur = 15;
                ctx.shadowColor = '#ff6600';
                ctx.beginPath();
                ctx.moveTo(this.x - this.width * 0.07, canvas.height - this.height + 1);
                ctx.lineTo(this.x + this.width * 0.07, canvas.height - this.height + 1);
                ctx.lineTo(this.x + this.width * 0.04, canvas.height - this.height + 6);
                ctx.lineTo(this.x - this.width * 0.04, canvas.height - this.height + 6);
                ctx.closePath();
                ctx.fill();

                // Detalle de lava bajando (río de lava)
                ctx.fillStyle = '#ff6600';
                ctx.beginPath();
                ctx.moveTo(this.x - this.width * 0.02, canvas.height - this.height + 5);
                ctx.lineTo(this.x + this.width * 0.02, canvas.height - this.height + 5);
                ctx.lineTo(this.x + this.width * 0.04, canvas.height - this.height * 0.5);
                ctx.lineTo(this.x - this.width * 0.01, canvas.height - this.height * 0.3);
                ctx.closePath();
                ctx.fill();
            }

            ctx.restore();
        }

        update() {
            // Erupciones en volcanes activos
            if (this.type === 'active' && Date.now() - this.lastEruption > this.eruptionInterval) {
                this.erupt();
                this.lastEruption = Date.now();
                this.eruptionInterval = Math.random() * 4000 + 3000;
            }
        }

        erupt() {
            // Disparar ráfaga de partículas hacia arriba
            const count = Math.floor(Math.random() * 15) + 15;
            for (let i = 0; i < count; i++) {
                particles.push(new LavaParticle(this.x, canvas.height - this.height + 2));
            }
        }
    }

    // Partícula de lava/magma de erupción
    class LavaParticle {
        constructor(x, y) {
            this.x = x + (Math.random() - 0.5) * 10;
            this.y = y;
            // Velocidad inicial fuerte hacia arriba
            this.vx = (Math.random() - 0.5) * 2;
            this.vy = -Math.random() * 6 - 4;
            this.size = Math.random() * 4 + 2;
            this.life = 1.0;
            this.decay = Math.random() * 0.012 + 0.008;
            
            const colors = ['#ff3300', '#ff5500', '#ffaa00', '#ffdd00', '#cc1100'];
            this.color = colors[Math.floor(Math.random() * colors.length)];
        }

        update() {
            this.x += this.vx;
            this.y += this.vy;
            this.vy += 0.12; // Gravedad: la partícula caerá de nuevo
            this.life -= this.decay;
        }

        draw() {
            if (this.life <= 0) return;
            ctx.save();
            ctx.globalAlpha = this.life;
            ctx.fillStyle = this.color;
            ctx.shadowBlur = this.size * 2;
            ctx.shadowColor = this.color;
            ctx.beginPath();
            // Partícula cuadrada estilo pixel art Minecraft
            ctx.rect(this.x - this.size / 2, this.y - this.size / 2, this.size, this.size);
            ctx.fill();
            ctx.restore();
        }
    }

    // Partícula de brasa flotante ambiental
    class EmberParticle {
        constructor() {
            this.reset(true);
        }

        reset(randomY = false) {
            this.x = Math.random() * canvas.width;
            this.y = randomY ? Math.random() * canvas.height : canvas.height + 20;
            this.vx = (Math.random() - 0.5) * 0.6;
            this.vy = -Math.random() * 1.5 - 0.5;
            this.size = Math.random() * 2 + 1;
            this.life = Math.random() * 0.5 + 0.5;
            this.decay = Math.random() * 0.003 + 0.001;
            
            const colors = ['#ff3300', '#ff6600', '#ff9900', '#ffaa00'];
            this.color = colors[Math.floor(Math.random() * colors.length)];
        }

        update() {
            this.x += this.vx;
            this.y += this.vy;
            this.life -= this.decay;
            if (this.life <= 0 || this.y < -10) {
                this.reset(false);
            }
        }

        draw() {
            ctx.save();
            ctx.globalAlpha = this.life;
            ctx.fillStyle = this.color;
            ctx.shadowBlur = 6;
            ctx.shadowColor = this.color;
            ctx.beginPath();
            ctx.rect(this.x - this.size / 2, this.y - this.size / 2, this.size, this.size);
            ctx.fill();
            ctx.restore();
        }
    }

    // Inicializar volcanes
    function initVolcanoes() {
        volcanoes = [];
        
        // Volcanes lejanos / de fondo
        volcanoes.push(new Volcano(canvas.width * 0.15, canvas.width * 0.3, canvas.height * 0.25, 'background'));
        volcanoes.push(new Volcano(canvas.width * 0.85, canvas.width * 0.4, canvas.height * 0.22, 'background'));
        
        // Volcanes activos principales
        volcanoes.push(new Volcano(canvas.width * 0.35, canvas.width * 0.22, canvas.height * 0.3, 'active'));
        volcanoes.push(new Volcano(canvas.width * 0.65, canvas.width * 0.25, canvas.height * 0.28, 'active'));
    }

    // Inicializar partículas ambientales
    const emberCount = 50;
    for (let i = 0; i < emberCount; i++) {
        particles.push(new EmberParticle());
    }

    resizeCanvas();
    window.addEventListener('resize', resizeCanvas);

    // Bucle de Animación Principal
    function animate() {
        ctx.clearRect(0, 0, canvas.width, canvas.height);
        
        // 1. Dibujar volcanes primero (atrás)
        volcanoes.forEach(v => {
            v.update();
            v.draw();
        });

        // 2. Dibujar y actualizar todas las partículas
        particles.forEach((p, idx) => {
            p.update();
            p.draw();
            
            // Eliminar partículas de lava agotadas
            if (p instanceof LavaParticle && p.life <= 0) {
                particles.splice(idx, 1);
            }
        });

        requestAnimationFrame(animate);
    }
    animate();

    // Modificar título e inyectar detalles dinámicos
    document.title = document.title.replace(/Pterodactyl/g, '🔥 Pterodactyl');

    console.log('%c🔥 NETHER VOLCANOES ACTIVADOS 🔥', 'color: #ff3300; font-size: 16px; font-weight: bold; text-shadow: 0 0 10px #ff6600;');
})();
