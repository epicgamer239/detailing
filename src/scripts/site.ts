
function initHeader() {
  const header = document.getElementById('site-header');
  const burger = document.getElementById('burger');
  const menu = document.getElementById('mobile-menu');
  if (!header || !burger || !menu) return;

  const onScroll = () => {
    header.classList.toggle('scrolled', window.scrollY > 24);
  };
  onScroll();
  window.addEventListener('scroll', onScroll, { passive: true });

  const setOpen = (open: boolean) => {
    burger.classList.toggle('active', open);
    menu.classList.toggle('active', open);
    burger.setAttribute('aria-expanded', String(open));
    menu.setAttribute('aria-hidden', String(!open));
    document.body.classList.toggle('menu-open', open);
  };

  burger.addEventListener('click', () => setOpen(!menu.classList.contains('active')));
  menu.querySelectorAll('a').forEach((a) => a.addEventListener('click', () => setOpen(false)));
}

function initCounters() {
  const els = document.querySelectorAll<HTMLElement>('[data-counter]');
  if (!els.length) return;
  const animate = (el: HTMLElement) => {
    const target = Number(el.dataset.counter || 0);
    const start = performance.now();
    const dur = 1400;
    const tick = (now: number) => {
      const t = Math.min(1, (now - start) / dur);
      const eased = 1 - Math.pow(1 - t, 3);
      el.textContent = String(Math.round(target * eased));
      if (t < 1) requestAnimationFrame(tick);
    };
    requestAnimationFrame(tick);
  };
  const io = new IntersectionObserver(
    (entries) => {
      entries.forEach((e) => {
        if (e.isIntersecting) {
          animate(e.target as HTMLElement);
          io.unobserve(e.target);
        }
      });
    },
    { threshold: 0.4 },
  );
  els.forEach((el) => io.observe(el));
}

function initHoverVideos() {
  document.querySelectorAll<HTMLVideoElement>('video[data-hover-play]').forEach((video) => {
    const card = video.closest('.work-card') || video;
    const play = () => video.play().catch(() => {});
    const pause = () => {
      video.pause();
      video.currentTime = 0;
    };
    card.addEventListener('mouseenter', play);
    card.addEventListener('mouseleave', pause);
    card.addEventListener('touchstart', play, { passive: true });
  });
}

function initReveal() {
  const els = document.querySelectorAll('[data-reveal]');
  if (!els.length) return;
  const io = new IntersectionObserver(
    (entries) => {
      entries.forEach((e) => {
        if (e.isIntersecting) {
          (e.target as HTMLElement).classList.add('is-visible');
          io.unobserve(e.target);
        }
      });
    },
    { threshold: 0.12, rootMargin: '0px 0px -40px 0px' },
  );
  els.forEach((el) => io.observe(el));
}

function initForms() {
  document.querySelectorAll<HTMLElement>('.contact-form-wrapper').forEach((wrapper) => {
    const form = wrapper.querySelector<HTMLFormElement>('.contact-form');
    const successEl = wrapper.querySelector<HTMLElement>('.contact-form__success');
    const errorEl = wrapper.querySelector<HTMLElement>('.contact-form__error');
    const retryBtn = wrapper.querySelector<HTMLButtonElement>('.contact-form__retry');
    if (!form || !successEl || !errorEl) return;

    form.addEventListener('submit', async (e) => {
      e.preventDefault();
      const submitBtn = form.querySelector<HTMLButtonElement>('.contact-form__submit');
      if (submitBtn) {
        submitBtn.classList.add('is-submitting');
        submitBtn.disabled = true;
      }
      try {
        const response = await fetch(form.action, {
          method: 'POST',
          body: new FormData(form),
          headers: { Accept: 'application/json' },
        });
        if (!response.ok) throw new Error('fail');
        form.style.display = 'none';
        successEl.style.display = 'block';
      } catch {
        form.style.display = 'none';
        errorEl.style.display = 'block';
      }
    });

    retryBtn?.addEventListener('click', () => {
      errorEl.style.display = 'none';
      form.style.display = 'flex';
      const submitBtn = form.querySelector<HTMLButtonElement>('.contact-form__submit');
      if (submitBtn) {
        submitBtn.classList.remove('is-submitting');
        submitBtn.disabled = false;
      }
    });
  });
}

initHeader();
initCounters();
initHoverVideos();
initReveal();
initForms();
