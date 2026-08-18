// ============================================================
//  TEMA INFERNAL MINECRAFT - Efectos de partículas de fuego
//  Archivo standalone para instalación manual
//
//  Instalación manual:
//  1. Copia este archivo a: /var/www/pterodactyl/public/themes/pterodactyl/js/infernal.js
//  2. Añade antes de </body> en tus plantillas blade:
//     <script src="/themes/pterodactyl/js/infernal.js"></script>
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
