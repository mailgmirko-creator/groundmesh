(() => {
  const script = document.currentScript;
  const rootUrl = script ? new URL("../", script.src) : new URL("./", window.location.href);
  const serviceWorkerUrl = new URL("sw.js", rootUrl);
  const dismissKey = "groundmesh.pwa.install-banner.dismissed.v1";
  const navStackKey = "groundmesh.pwa.nav-stack.v1";
  const canUseServiceWorker = "serviceWorker" in navigator;
  const isHttpPage = /^https?:$/.test(window.location.protocol);
  let deferredPrompt = null;

  const isStandalone = () =>
    window.matchMedia("(display-mode: standalone)").matches ||
    window.navigator.standalone === true;

  const isIos = () => /iphone|ipad|ipod/i.test(window.navigator.userAgent);

  const normalizePath = (pathname) => {
    let value = pathname || "/";
    if (value.endsWith("/index.html")) {
      value = value.slice(0, -"/index.html".length);
    }
    if (value.length > 1 && value.endsWith("/")) {
      value = value.slice(0, -1);
    }
    return value;
  };

  const getHomeHref = () => rootUrl.href;

  const isHomePage = () =>
    normalizePath(window.location.pathname) === normalizePath(rootUrl.pathname);

  const bannerDismissed = () => {
    try {
      return window.localStorage.getItem(dismissKey) === "1";
    } catch {
      return false;
    }
  };

  const setBannerDismissed = () => {
    try {
      window.localStorage.setItem(dismissKey, "1");
    } catch {
      // Ignore storage failures. The prompt is still optional.
    }
  };

  const clearBannerDismissed = () => {
    try {
      window.localStorage.removeItem(dismissKey);
    } catch {
      // Ignore storage failures. This only controls banner persistence.
    }
  };

  const ensureBannerStyles = () => {
    if (document.getElementById("gm-pwa-banner-style")) {
      return;
    }

    const style = document.createElement("style");
    style.id = "gm-pwa-banner-style";
    style.textContent = `
      #gm-pwa-banner {
        position: fixed;
        right: 16px;
        bottom: 16px;
        z-index: 9999;
        width: min(360px, calc(100vw - 32px));
        padding: 14px 14px 12px;
        border-radius: 18px;
        border: 1px solid rgba(255, 255, 255, 0.14);
        background: rgba(11, 15, 20, 0.96);
        color: #eef2f7;
        box-shadow: 0 18px 40px rgba(0, 0, 0, 0.28);
        backdrop-filter: blur(12px);
        font-family: system-ui, -apple-system, Segoe UI, Roboto, Ubuntu, Cantarell, "Noto Sans", sans-serif;
      }
      #gm-pwa-banner strong {
        display: block;
        margin-bottom: 6px;
        font-size: 0.98rem;
      }
      #gm-pwa-banner p {
        margin: 0;
        color: #cfd8e3;
        font-size: 0.94rem;
        line-height: 1.45;
      }
      .gm-pwa-banner-actions {
        display: flex;
        gap: 10px;
        margin-top: 12px;
        flex-wrap: wrap;
      }
      .gm-pwa-banner-btn {
        border: 0;
        border-radius: 999px;
        padding: 9px 14px;
        font: inherit;
        font-weight: 600;
        cursor: pointer;
      }
      .gm-pwa-banner-btn-primary {
        background: linear-gradient(135deg, #95e3ae, #8bc4ff);
        color: #091018;
      }
      .gm-pwa-banner-btn-secondary {
        background: rgba(255, 255, 255, 0.08);
        color: #eef2f7;
      }
      @media (max-width: 640px) {
        #gm-pwa-banner {
          left: 12px;
          right: 12px;
          bottom: 12px;
          width: auto;
        }
      }
    `;
    document.head.appendChild(style);
  };

  const readNavStack = () => {
    try {
      const raw = window.sessionStorage.getItem(navStackKey);
      if (!raw) {
        return [];
      }
      const parsed = JSON.parse(raw);
      return Array.isArray(parsed) ? parsed.filter((item) => typeof item === "string") : [];
    } catch {
      return [];
    }
  };

  const writeNavStack = (stack) => {
    try {
      window.sessionStorage.setItem(navStackKey, JSON.stringify(stack.slice(-24)));
    } catch {
      // Ignore storage failures. Navigation still falls back to home.
    }
  };

  const trackCurrentLocation = () => {
    const current = window.location.href;
    const stack = readNavStack();
    const existingIndex = stack.lastIndexOf(current);

    if (existingIndex === -1) {
      stack.push(current);
      writeNavStack(stack);
      return;
    }

    if (existingIndex !== stack.length - 1) {
      writeNavStack(stack.slice(0, existingIndex + 1));
    }
  };

  const goHome = () => {
    window.location.href = getHomeHref();
  };

  const goBackWithinGroundMesh = () => {
    const stack = readNavStack();
    if (stack.length > 1) {
      stack.pop();
      const previous = stack[stack.length - 1];
      writeNavStack(stack);
      window.location.href = previous;
      return;
    }

    goHome();
  };

  const ensureShellNavStyles = () => {
    if (document.getElementById("gm-shell-nav-style")) {
      return;
    }

    const style = document.createElement("style");
    style.id = "gm-shell-nav-style";
    style.textContent = `
      #gm-shell-nav {
        position: fixed;
        left: 14px;
        bottom: calc(env(safe-area-inset-bottom, 0px) + 14px);
        z-index: 9998;
        display: flex;
        gap: 8px;
        padding: 8px;
        border-radius: 999px;
        border: 1px solid rgba(255, 255, 255, 0.12);
        background: rgba(11, 15, 20, 0.94);
        box-shadow: 0 18px 40px rgba(0, 0, 0, 0.28);
        backdrop-filter: blur(12px);
        font-family: system-ui, -apple-system, Segoe UI, Roboto, Ubuntu, Cantarell, "Noto Sans", sans-serif;
      }
      .gm-shell-nav-btn {
        appearance: none;
        border: 0;
        border-radius: 999px;
        min-height: 40px;
        padding: 0 14px;
        font: inherit;
        font-size: 0.94rem;
        font-weight: 700;
        cursor: pointer;
      }
      .gm-shell-nav-btn-primary {
        background: linear-gradient(135deg, #95e3ae, #8bc4ff);
        color: #091018;
      }
      .gm-shell-nav-btn-secondary {
        background: rgba(255, 255, 255, 0.08);
        color: #eef2f7;
      }
      @media (max-width: 640px) {
        #gm-shell-nav {
          left: 12px;
          right: 12px;
          bottom: calc(env(safe-area-inset-bottom, 0px) + 12px);
          justify-content: space-between;
        }
        .gm-shell-nav-btn {
          flex: 1 1 0;
        }
      }
    `;
    document.head.appendChild(style);
  };

  const removeShellNav = () => {
    document.getElementById("gm-shell-nav")?.remove();
  };

  const showShellNav = () => {
    if (!document.body || isHomePage()) {
      return;
    }

    ensureShellNavStyles();
    removeShellNav();

    const nav = document.createElement("nav");
    nav.id = "gm-shell-nav";
    nav.setAttribute("aria-label", "GroundMesh app navigation");

    const back = document.createElement("button");
    back.type = "button";
    back.className = "gm-shell-nav-btn gm-shell-nav-btn-secondary";
    back.textContent = "Back";
    back.addEventListener("click", goBackWithinGroundMesh);

    const home = document.createElement("button");
    home.type = "button";
    home.className = "gm-shell-nav-btn gm-shell-nav-btn-primary";
    home.textContent = "Home";
    home.addEventListener("click", goHome);

    nav.appendChild(back);
    nav.appendChild(home);
    document.body.appendChild(nav);
  };

  const removeBanner = () => {
    document.getElementById("gm-pwa-banner")?.remove();
  };

  const showBanner = ({ title, message, primaryLabel, onPrimary }) => {
    if (isStandalone() || bannerDismissed() || !document.body) {
      return;
    }

    ensureBannerStyles();
    removeBanner();

    const banner = document.createElement("aside");
    banner.id = "gm-pwa-banner";

    const heading = document.createElement("strong");
    heading.textContent = title;

    const copy = document.createElement("p");
    copy.textContent = message;

    const actions = document.createElement("div");
    actions.className = "gm-pwa-banner-actions";

    if (primaryLabel && onPrimary) {
      const primary = document.createElement("button");
      primary.type = "button";
      primary.className = "gm-pwa-banner-btn gm-pwa-banner-btn-primary";
      primary.textContent = primaryLabel;
      primary.addEventListener("click", onPrimary);
      actions.appendChild(primary);
    }

    const secondary = document.createElement("button");
    secondary.type = "button";
    secondary.className = "gm-pwa-banner-btn gm-pwa-banner-btn-secondary";
    secondary.textContent = "Later";
    secondary.addEventListener("click", () => {
      setBannerDismissed();
      removeBanner();
    });
    actions.appendChild(secondary);

    banner.appendChild(heading);
    banner.appendChild(copy);
    banner.appendChild(actions);
    document.body.appendChild(banner);
  };

  window.addEventListener("load", () => {
    if (!canUseServiceWorker || !isHttpPage) {
      return;
    }

    navigator.serviceWorker
      .register(serviceWorkerUrl.href, { scope: rootUrl.pathname })
      .catch(console.error);
  });

  window.addEventListener("beforeinstallprompt", (event) => {
    event.preventDefault();
    deferredPrompt = event;
    clearBannerDismissed();

    showBanner({
      title: "Install GroundMesh",
      message: "Keep GroundMesh close, launch faster, and retain the cached shell for lighter offline use.",
      primaryLabel: "Install",
      onPrimary: async () => {
        if (!deferredPrompt) {
          return;
        }

        deferredPrompt.prompt();
        const result = await deferredPrompt.userChoice;
        if (result.outcome !== "accepted") {
          setBannerDismissed();
        }
        deferredPrompt = null;
        removeBanner();
      }
    });
  });

  window.addEventListener("appinstalled", () => {
    deferredPrompt = null;
    clearBannerDismissed();
    removeBanner();
  });

  window.addEventListener("DOMContentLoaded", () => {
    trackCurrentLocation();
    showShellNav();

    if (isStandalone() || bannerDismissed()) {
      return;
    }

    if (isIos()) {
      showBanner({
        title: "Add GroundMesh to Home Screen",
        message: "On iPhone or iPad, use the browser Share menu and choose Add to Home Screen when your browser offers it."
      });
    }
  });
})();
