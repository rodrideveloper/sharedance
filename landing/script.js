// Mobile Navigation
const hamburger = document.querySelector('.hamburger');
const navMenu = document.querySelector('.nav-menu');
const navbar = document.querySelector('.navbar');

// Toggle mobile menu
hamburger.addEventListener('click', () => {
    navMenu.classList.toggle('active');
    hamburger.classList.toggle('active');
});

// Close mobile menu when clicking on a link
document.querySelectorAll('.nav-link').forEach(link => {
    link.addEventListener('click', () => {
        navMenu.classList.remove('active');
        hamburger.classList.remove('active');
    });
});

// Navbar scroll effect
window.addEventListener('scroll', () => {
    if (window.scrollY > 100) {
        navbar.classList.add('scrolled');
    } else {
        navbar.classList.remove('scrolled');
    }
});

// Smooth scrolling for navigation links
document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', function (e) {
        e.preventDefault();
        const target = document.querySelector(this.getAttribute('href'));
        if (target) {
            const offsetTop = target.offsetTop - 70; // Account for fixed navbar
            window.scrollTo({
                top: offsetTop,
                behavior: 'smooth'
            });
        }
    });
});

// Intersection Observer for animations
const observerOptions = {
    threshold: 0.1,
    rootMargin: '0px 0px -50px 0px'
};

const observer = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
        if (entry.isIntersecting) {
            entry.target.classList.add('animate');
        }
    });
}, observerOptions);

// Observe elements for animation
document.querySelectorAll('.feature-card, .step, .pricing-card').forEach(el => {
    observer.observe(el);
});

// Counter animation for hero stats
function animateCounter(element, target, duration = 2000) {
    let start = 0;
    const increment = target / (duration / 16);

    const timer = setInterval(() => {
        start += increment;
        if (start >= target) {
            element.textContent = target + (element.dataset.suffix || '');
            clearInterval(timer);
        } else {
            element.textContent = Math.floor(start) + (element.dataset.suffix || '');
        }
    }, 16);
}

// Animate counters when hero section is visible
const heroObserver = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
        if (entry.isIntersecting) {
            const counters = entry.target.querySelectorAll('.stat-number');
            counters.forEach(counter => {
                const target = parseInt(counter.dataset.count);
                animateCounter(counter, target);
            });
            heroObserver.unobserve(entry.target);
        }
    });
});

const heroStats = document.querySelector('.hero-stats');
if (heroStats) {
    heroObserver.observe(heroStats);
}

// Download button interactions
document.querySelectorAll('.download-btn').forEach(btn => {
    btn.addEventListener('click', function (e) {
        e.preventDefault();

        // Add click effect
        this.style.transform = 'scale(0.95)';
        setTimeout(() => {
            this.style.transform = '';
        }, 150);

        // Track download attempt
        const platform = this.querySelector('strong').textContent;
        console.log(`Download attempted for: ${platform}`);

        // Simulate download or redirect to app store
        if (platform.includes('Google Play')) {
            // Replace with actual Google Play Store URL
            window.open('https://play.google.com/store/apps/details?id=com.sharedance.app', '_blank');
        } else if (platform.includes('App Store')) {
            // Replace with actual App Store URL when available
            alert('La aplicación estará disponible en App Store pronto!');
        }
    });
});

// Pricing card interactions
document.querySelectorAll('.plan-button').forEach(btn => {
    btn.addEventListener('click', function () {
        const planName = this.closest('.pricing-card').querySelector('h3').textContent;

        // Add click effect
        this.style.transform = 'scale(0.95)';
        setTimeout(() => {
            this.style.transform = '';
        }, 150);

        // Handle plan selection
        console.log(`Plan selected: ${planName}`);

        // You can replace this with actual payment/signup logic
        alert(`¡Perfecto! Has seleccionado el plan ${planName}. Te contactaremos pronto para completar el registro.`);
    });
});

// Form validation (if you add a contact form later)
function validateEmail(email) {
    const re = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return re.test(email);
}

// Parallax effect for floating shapes
window.addEventListener('scroll', () => {
    const scrolled = window.pageYOffset;
    const shapes = document.querySelectorAll('.shape');

    shapes.forEach((shape, index) => {
        const speed = 0.5 + (index * 0.1);
        const yPos = -(scrolled * speed);
        shape.style.transform = `translate3d(0, ${yPos}px, 0)`;
    });
});

// Phone mockup interaction
document.querySelectorAll('.phone').forEach(phone => {
    phone.addEventListener('mouseenter', () => {
        phone.style.transform += ' scale(1.05)';
    });

    phone.addEventListener('mouseleave', () => {
        const isFirst = phone.classList.contains('phone-1');
        const rotation = isFirst ? 'rotate(-5deg)' : 'rotate(5deg)';
        phone.style.transform = rotation;
    });
});

// Add CSS animation classes
const style = document.createElement('style');
style.textContent = `
    .feature-card,
    .step,
    .pricing-card {
        opacity: 0;
        transform: translateY(30px);
        transition: all 0.6s ease;
    }
    
    .feature-card.animate,
    .step.animate,
    .pricing-card.animate {
        opacity: 1;
        transform: translateY(0);
    }
    
    .hamburger.active span:nth-child(1) {
        transform: rotate(45deg) translate(5px, 5px);
    }
    
    .hamburger.active span:nth-child(2) {
        opacity: 0;
    }
    
    .hamburger.active span:nth-child(3) {
        transform: rotate(-45deg) translate(7px, -6px);
    }
    
    @media (max-width: 768px) {
        .nav-menu {
            transform: translateX(-100%);
            transition: transform 0.3s ease;
        }
        
        .nav-menu.active {
            transform: translateX(0);
        }
    }
`;
document.head.appendChild(style);

// Lazy loading for images (when you add them)
function lazyLoadImages() {
    const images = document.querySelectorAll('img[data-src]');
    const imageObserver = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                const img = entry.target;
                img.src = img.dataset.src;
                img.removeAttribute('data-src');
                imageObserver.unobserve(img);
            }
        });
    });

    images.forEach(img => imageObserver.observe(img));
}

// Initialize lazy loading
lazyLoadImages();

// Performance optimization: Throttle scroll events
function throttle(func, wait) {
    let timeout;
    return function executedFunction(...args) {
        const later = () => {
            clearTimeout(timeout);
            func(...args);
        };
        clearTimeout(timeout);
        timeout = setTimeout(later, wait);
    };
}

// Replace direct scroll listeners with throttled versions
const throttledParallax = throttle(() => {
    const scrolled = window.pageYOffset;
    const shapes = document.querySelectorAll('.shape');

    shapes.forEach((shape, index) => {
        const speed = 0.5 + (index * 0.1);
        const yPos = -(scrolled * speed);
        shape.style.transform = `translate3d(0, ${yPos}px, 0)`;
    });
}, 16);

const throttledNavbar = throttle(() => {
    if (window.scrollY > 100) {
        navbar.classList.add('scrolled');
    } else {
        navbar.classList.remove('scrolled');
    }
}, 16);

window.addEventListener('scroll', throttledParallax);
window.addEventListener('scroll', throttledNavbar);

// Add data attributes for counter animation
document.addEventListener('DOMContentLoaded', () => {
    // Set counter data
    const statNumbers = document.querySelectorAll('.stat-number');
    const counterValues = ['500', '50', '98'];
    const suffixes = ['+', '+', '%'];

    statNumbers.forEach((stat, index) => {
        if (counterValues[index]) {
            stat.dataset.count = counterValues[index].replace(/[^0-9]/g, '');
            stat.dataset.suffix = suffixes[index] || '';
            stat.textContent = '0' + suffixes[index];
        }
    });

    // Add loading animation
    document.body.classList.add('loaded');
});

// Add loading styles
const loadingStyle = document.createElement('style');
loadingStyle.textContent = `
    body {
        opacity: 0;
        transition: opacity 0.5s ease;
    }
    
    body.loaded {
        opacity: 1;
    }
    
    .hero-content > * {
        opacity: 0;
        animation: slideInLeft 1s ease-out forwards;
    }
    
    .hero-content > *:nth-child(1) { animation-delay: 0.2s; }
    .hero-content > *:nth-child(2) { animation-delay: 0.4s; }
    .hero-content > *:nth-child(3) { animation-delay: 0.6s; }
    .hero-content > *:nth-child(4) { animation-delay: 0.8s; }
    
    .hero-phone {
        opacity: 0;
        animation: slideInRight 1s ease-out 0.5s forwards;
    }
`;
document.head.appendChild(loadingStyle);

// Social sharing functionality (for future use)
function shareApp(platform) {
    const url = window.location.href;
    const text = 'Descubre ShareDance - La app de gestión de clases de baile más innovadora';

    switch (platform) {
        case 'facebook':
            window.open(`https://www.facebook.com/sharer/sharer.php?u=${encodeURIComponent(url)}`);
            break;
        case 'twitter':
            window.open(`https://twitter.com/intent/tweet?text=${encodeURIComponent(text)}&url=${encodeURIComponent(url)}`);
            break;
        case 'whatsapp':
            window.open(`https://wa.me/?text=${encodeURIComponent(text + ' ' + url)}`);
            break;
        case 'linkedin':
            window.open(`https://www.linkedin.com/sharing/share-offsite/?url=${encodeURIComponent(url)}`);
            break;
    }
}

// Add share functionality to social links
document.querySelectorAll('.social-links a').forEach(link => {
    link.addEventListener('click', (e) => {
        e.preventDefault();
        const platform = link.getAttribute('href').replace('#', '');
        shareApp(platform);
    });
});

// Error handling for missing elements
function safeQuerySelector(selector, callback) {
    const element = document.querySelector(selector);
    if (element && typeof callback === 'function') {
        callback(element);
    }
}

// Initialize everything safely
document.addEventListener('DOMContentLoaded', () => {
    // Safe initialization of components
    safeQuerySelector('.hamburger', (el) => {
        console.log('Mobile navigation initialized');
    });

    safeQuerySelector('.hero-stats', (el) => {
        console.log('Hero stats animation ready');
    });

    console.log('ShareDance landing page loaded successfully!');
});
