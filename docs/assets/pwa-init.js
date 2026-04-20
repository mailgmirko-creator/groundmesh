(() => {
  if (!("serviceWorker" in navigator)) {
    return;
  }

  if (!/^https?:$/.test(window.location.protocol)) {
    return;
  }

  const script = document.currentScript;
  const rootUrl = script ? new URL("../", script.src) : new URL("./", window.location.href);
  const serviceWorkerUrl = new URL("sw.js", rootUrl);
  const dismissKey = "groundmesh.pwa.install-banner.dismissed.v1";
  let deferredPrompt = null;

  const isStandalone = () =>
    window.matchMedia("(display-mode: standalone)").matches ||
    window.navigator.standalone === true;

  const isIos = () => /iphone|ipad|ipod/i.test(window.navigator.userAgent);

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
