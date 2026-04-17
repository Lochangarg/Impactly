/* ============================================
   IMPACTLY EXHIBITION WEBSITE — INTERACTIONS
   ============================================ */

document.addEventListener('DOMContentLoaded', () => {

    // ─── NAVBAR SCROLL EFFECT ───────────────────────
    const navbar = document.getElementById('navbar');
    let lastScroll = 0;

    const handleNavScroll = () => {
        const currentScroll = window.scrollY;
        if (currentScroll > 50) {
            navbar.classList.add('scrolled');
        } else {
            navbar.classList.remove('scrolled');
        }
        lastScroll = currentScroll;
    };

    window.addEventListener('scroll', handleNavScroll, { passive: true });

    // ─── MOBILE NAV TOGGLE ──────────────────────────
    const navToggle = document.getElementById('navToggle');
    const navLinks = document.getElementById('navLinks');

    if (navToggle) {
        navToggle.addEventListener('click', () => {
            navLinks.classList.toggle('active');
            // Animate hamburger to X
            const spans = navToggle.querySelectorAll('span');
            if (navLinks.classList.contains('active')) {
                spans[0].style.transform = 'rotate(45deg) translate(5px, 5px)';
                spans[1].style.opacity = '0';
                spans[2].style.transform = 'rotate(-45deg) translate(5px, -5px)';
            } else {
                spans[0].style.transform = 'none';
                spans[1].style.opacity = '1';
                spans[2].style.transform = 'none';
            }
        });

        // Close mobile nav on link click
        navLinks.querySelectorAll('a').forEach(link => {
            link.addEventListener('click', () => {
                navLinks.classList.remove('active');
                const spans = navToggle.querySelectorAll('span');
                spans[0].style.transform = 'none';
                spans[1].style.opacity = '1';
                spans[2].style.transform = 'none';
            });
        });
    }

    // ─── SMOOTH SCROLL FOR NAV LINKS ────────────────
    document.querySelectorAll('a[href^="#"]').forEach(anchor => {
        anchor.addEventListener('click', function (e) {
            e.preventDefault();
            const target = document.querySelector(this.getAttribute('href'));
            if (target) {
                const offset = 80;
                const top = target.getBoundingClientRect().top + window.scrollY - offset;
                window.scrollTo({ top, behavior: 'smooth' });
            }
        });
    });

    // ─── ACTIVE NAV LINK HIGHLIGHTING ───────────────
    const sections = document.querySelectorAll('section[id]');
    const navAnchors = document.querySelectorAll('.nav-links a');

    const highlightNav = () => {
        const scrollY = window.scrollY + 150;

        sections.forEach(section => {
            const top = section.offsetTop;
            const height = section.offsetHeight;
            const id = section.getAttribute('id');

            if (scrollY >= top && scrollY < top + height) {
                navAnchors.forEach(a => {
                    a.style.color = '';
                    if (a.getAttribute('href') === `#${id}`) {
                        a.style.color = '#F1F1F6';
                    }
                });
            }
        });
    };

    window.addEventListener('scroll', highlightNav, { passive: true });

    // ─── ANIMATED COUNTER (HERO STATS) ──────────────
    const counters = document.querySelectorAll('.stat-number[data-target]');
    let counterAnimated = false;

    const animateCounters = () => {
        if (counterAnimated) return;

        counters.forEach(counter => {
            const target = parseInt(counter.getAttribute('data-target'));
            const duration = 1500;
            const startTime = performance.now();

            const updateCounter = (currentTime) => {
                const elapsed = currentTime - startTime;
                const progress = Math.min(elapsed / duration, 1);

                // Ease out cubic
                const ease = 1 - Math.pow(1 - progress, 3);
                const current = Math.round(ease * target);

                counter.textContent = current;

                if (progress < 1) {
                    requestAnimationFrame(updateCounter);
                } else {
                    counter.textContent = target;
                }
            };

            requestAnimationFrame(updateCounter);
        });

        counterAnimated = true;
    };

    // Trigger counter animation when hero is visible
    const heroObserver = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                setTimeout(animateCounters, 600);
                heroObserver.disconnect();
            }
        });
    }, { threshold: 0.3 });

    const heroSection = document.getElementById('hero');
    if (heroSection) {
        heroObserver.observe(heroSection);
    }

    // ─── SCROLL REVEAL ANIMATIONS ───────────────────
    const revealElements = () => {
        // Problem cards
        const problemCards = document.querySelectorAll('.problem-card');
        // Solution cards
        const solutionCards = document.querySelectorAll('.solution-card');
        // USP cards
        const uspCards = document.querySelectorAll('.usp-card');
        // Feature items
        const featureItems = document.querySelectorAll('.feature-item');
        // Screenshot cards
        const screenshotCards = document.querySelectorAll('.screenshot-card');
        // Tech cards
        const techCards = document.querySelectorAll('.tech-card');
        // Roadmap cards
        const roadmapCards = document.querySelectorAll('.roadmap-card');
        // Team cards
        const teamCards = document.querySelectorAll('.team-card');
        // Research cards
        const researchCards = document.querySelectorAll('.research-card');
        // Persona cards
        const personaCards = document.querySelectorAll('.persona-card');
        // Survey bars
        const barFills = document.querySelectorAll('.bar-fill');

        const allAnimatable = [
            ...problemCards,
            ...solutionCards,
            ...uspCards,
            ...featureItems,
            ...screenshotCards,
            ...techCards,
            ...roadmapCards,
            ...teamCards,
            ...researchCards,
            ...personaCards
        ];

        const observer = new IntersectionObserver((entries) => {
            entries.forEach(entry => {
                if (entry.isIntersecting) {
                    const delay = entry.target.dataset.delay || 0;
                    setTimeout(() => {
                        entry.target.classList.add('visible');
                    }, parseInt(delay));
                }
            });
        }, {
            threshold: 0.15,
            rootMargin: '0px 0px -40px 0px'
        });

        allAnimatable.forEach(el => {
            el.style.opacity = '0';
            el.style.transform = 'translateY(30px)';
            el.style.transition = 'opacity 0.7s cubic-bezier(0.16, 1, 0.3, 1), transform 0.7s cubic-bezier(0.16, 1, 0.3, 1)';
            observer.observe(el);
        });

        // Bar fills (survey chart)
        const barObserver = new IntersectionObserver((entries) => {
            entries.forEach(entry => {
                if (entry.isIntersecting) {
                    setTimeout(() => {
                        entry.target.classList.add('visible');
                    }, 200);
                }
            });
        }, { threshold: 0.3 });

        barFills.forEach(bar => {
            barObserver.observe(bar);
        });
    };

    // Apply staggered delays
    const applyStagger = (selector, baseDelay = 0, increment = 80) => {
        document.querySelectorAll(selector).forEach((el, i) => {
            el.dataset.delay = baseDelay + (i * increment);
        });
    };

    applyStagger('.problem-card', 0, 120);
    applyStagger('.solution-card', 0, 80);
    applyStagger('.usp-card', 0, 100);
    applyStagger('.feature-item', 0, 120);
    applyStagger('.screenshot-card', 0, 100);
    applyStagger('.tech-card', 0, 60);
    applyStagger('.roadmap-card', 0, 80);
    applyStagger('.team-card', 0, 150);
    applyStagger('.research-card', 0, 150);
    applyStagger('.persona-card', 0, 150);

    // Override the visible style for animated elements
    const style = document.createElement('style');
    style.textContent = `
        .problem-card.visible,
        .solution-card.visible,
        .usp-card.visible,
        .feature-item.visible,
        .screenshot-card.visible,
        .tech-card.visible,
        .roadmap-card.visible,
        .team-card.visible,
        .research-card.visible,
        .persona-card.visible {
            opacity: 1 !important;
            transform: translateY(0) !important;
        }
    `;
    document.head.appendChild(style);

    revealElements();

    // ─── PARALLAX ORB MOVEMENT ──────────────────────
    let ticking = false;

    const handleMouseMove = (e) => {
        if (ticking) return;
        ticking = true;

        requestAnimationFrame(() => {
            const x = (e.clientX / window.innerWidth - 0.5) * 2;
            const y = (e.clientY / window.innerHeight - 0.5) * 2;

            const orb1 = document.querySelector('.orb-1');
            const orb2 = document.querySelector('.orb-2');
            const orb3 = document.querySelector('.orb-3');

            if (orb1) orb1.style.transform = `translate(${x * 30}px, ${y * 20}px)`;
            if (orb2) orb2.style.transform = `translate(${x * -20}px, ${y * -15}px)`;
            if (orb3) orb3.style.transform = `translate(${x * 15}px, ${y * 25}px)`;

            ticking = false;
        });
    };

    window.addEventListener('mousemove', handleMouseMove, { passive: true });

    // ─── PHONE MOCKUP TILT EFFECT ───────────────────
    const phoneMockup = document.querySelector('.phone-mockup');
    
    if (phoneMockup) {
        const heroVisual = document.querySelector('.hero-visual');

        heroVisual.addEventListener('mousemove', (e) => {
            const rect = heroVisual.getBoundingClientRect();
            const x = (e.clientX - rect.left) / rect.width - 0.5;
            const y = (e.clientY - rect.top) / rect.height - 0.5;

            phoneMockup.style.transform = `
                perspective(1000px)
                rotateY(${x * 10}deg)
                rotateX(${-y * 10}deg)
            `;
        });

        heroVisual.addEventListener('mouseleave', () => {
            phoneMockup.style.transform = 'perspective(1000px) rotateY(0deg) rotateX(0deg)';
            phoneMockup.style.transition = 'transform 0.5s cubic-bezier(0.16, 1, 0.3, 1)';
        });

        heroVisual.addEventListener('mouseenter', () => {
            phoneMockup.style.transition = 'transform 0.1s ease-out';
        });
    }

    // ─── METHOD STEP HOVER CYCLING ──────────────────
    const methodSteps = document.querySelectorAll('.method-step');
    let currentStep = 0;
    let stepInterval;

    const cycleSteps = () => {
        methodSteps.forEach(step => step.classList.remove('active'));
        methodSteps[currentStep].classList.add('active');
        currentStep = (currentStep + 1) % methodSteps.length;
    };

    if (methodSteps.length > 0) {
        // Add active styles
        const methodStyle = document.createElement('style');
        methodStyle.textContent = `
            .method-step.active {
                background: rgba(99, 102, 241, 0.08) !important;
                border-color: rgba(99, 102, 241, 0.2) !important;
                transform: translateX(4px);
            }
            .method-step {
                transition: all 0.4s cubic-bezier(0.16, 1, 0.3, 1) !important;
            }
        `;
        document.head.appendChild(methodStyle);

        stepInterval = setInterval(cycleSteps, 2500);

        // Pause on hover
        const methodContainer = document.querySelector('.methodology-steps');
        if (methodContainer) {
            methodContainer.addEventListener('mouseenter', () => clearInterval(stepInterval));
            methodContainer.addEventListener('mouseleave', () => {
                stepInterval = setInterval(cycleSteps, 2500);
            });

            // Click to activate
            methodSteps.forEach((step, i) => {
                step.addEventListener('click', () => {
                    currentStep = i;
                    cycleSteps();
                });
            });
        }
    }

    // ─── CHIP HOVER ANIMATION ───────────────────────
    const chips = document.querySelectorAll('.chip');
    chips.forEach(chip => {
        chip.addEventListener('mouseenter', () => {
            chip.style.transform = 'scale(1.08)';
        });
        chip.addEventListener('mouseleave', () => {
            chip.style.transform = 'scale(1)';
        });
    });

    // ─── SCREENSHOT AUTO-SCROLL ON MOBILE ───────────
    const screenshotGrid = document.querySelector('.screenshots-carousel');
    if (screenshotGrid && window.innerWidth <= 768) {
        let scrollPos = 0;
        const scrollCards = () => {
            const cards = screenshotGrid.querySelectorAll('.screenshot-card');
            if (cards.length === 0) return;
            
            scrollPos++;
            if (scrollPos >= cards.length) scrollPos = 0;
            
            cards[scrollPos].scrollIntoView({
                behavior: 'smooth',
                block: 'nearest',
                inline: 'start'
            });
        };
        // Auto scroll every 4 seconds on mobile
        setInterval(scrollCards, 4000);
    }

    // ─── EASTER EGG: KONAMI CODE ────────────────────
    const konamiCode = [38, 38, 40, 40, 37, 39, 37, 39, 66, 65];
    let konamiIndex = 0;

    document.addEventListener('keydown', (e) => {
        if (e.keyCode === konamiCode[konamiIndex]) {
            konamiIndex++;
            if (konamiIndex === konamiCode.length) {
                document.body.style.animation = 'none';
                document.querySelectorAll('.orb').forEach(orb => {
                    orb.style.opacity = '0.4';
                    orb.style.filter = 'blur(80px)';
                });
                konamiIndex = 0;

                // Create fireworks effect
                for (let i = 0; i < 30; i++) {
                    const particle = document.createElement('div');
                    particle.style.cssText = `
                        position: fixed;
                        width: 8px;
                        height: 8px;
                        border-radius: 50%;
                        background: hsl(${Math.random() * 360}, 80%, 60%);
                        top: 50%;
                        left: 50%;
                        z-index: 10000;
                        pointer-events: none;
                        animation: firework 1.5s ease-out forwards;
                        --tx: ${(Math.random() - 0.5) * 600}px;
                        --ty: ${(Math.random() - 0.5) * 600}px;
                    `;
                    document.body.appendChild(particle);
                    setTimeout(() => particle.remove(), 1500);
                }

                const fwStyle = document.createElement('style');
                fwStyle.textContent = `
                    @keyframes firework {
                        0% { transform: translate(0, 0) scale(1); opacity: 1; }
                        100% { transform: translate(var(--tx), var(--ty)) scale(0); opacity: 0; }
                    }
                `;
                document.head.appendChild(fwStyle);
            }
        } else {
            konamiIndex = 0;
        }
    });

    // ─── PRELOADER → FADE IN ────────────────────────
    document.body.style.opacity = '0';
    document.body.style.transition = 'opacity 0.6s ease-out';
    
    requestAnimationFrame(() => {
        requestAnimationFrame(() => {
            document.body.style.opacity = '1';
        });
    });

    console.log('%c🌍 Impactly Exhibition Website', 'font-size: 20px; font-weight: bold; color: #6366F1;');
    console.log('%cBuilt with ❤️ by Parikshit Kurel & Lochan Garg', 'font-size: 12px; color: #9CA3AF;');
});
