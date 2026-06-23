// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html";
// Establish Phoenix Socket and LiveView configuration.
import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";
import topbar from "../vendor/topbar";

const prefersReducedMotion = window.matchMedia(
  "(prefers-reduced-motion: reduce)",
);

// CKEditor 5 is loaded on demand from the CDN so it never weighs down public
// pages. Bump this to upgrade. (Self-hosted use runs under the free GPL key;
// swap in a commercial license key here if the project becomes proprietary.)
// Pinned to the last pre-v44 release. CKEditor 5 v44 changed its licensing so
// the free "GPL" key is rejected on the CDN distribution channel
// (license-key-invalid-distribution-channel); v43.x still allows GPL over the
// CDN, which keeps this on-demand load working without a license account.
const CKEDITOR_VERSION = "43.3.1";
let ckeditorPromise = null;

function loadCKEditor() {
  if (window.CKEDITOR) return Promise.resolve(window.CKEDITOR);
  if (ckeditorPromise) return ckeditorPromise;

  ckeditorPromise = new Promise((resolve, reject) => {
    const link = document.createElement("link");
    link.rel = "stylesheet";
    link.href = `https://cdn.ckeditor.com/ckeditor5/${CKEDITOR_VERSION}/ckeditor5.css`;
    document.head.appendChild(link);

    const script = document.createElement("script");
    script.src = `https://cdn.ckeditor.com/ckeditor5/${CKEDITOR_VERSION}/ckeditor5.umd.js`;
    script.onload = () => resolve(window.CKEDITOR);
    script.onerror = () => reject(new Error("Failed to load CKEditor"));
    document.head.appendChild(script);
  });

  return ckeditorPromise;
}

const Hooks = {
  RevealOnScroll: {
    mounted() {
      if (prefersReducedMotion.matches) {
        this.el.classList.add("is-visible");
        return;
      }

      this.observer = new IntersectionObserver(
        (entries) => {
          entries.forEach((entry) => {
            if (!entry.isIntersecting) return;

            this.el.classList.add("is-visible");
            this.observer.disconnect();
          });
        },
        { threshold: 0.18 },
      );

      this.observer.observe(this.el);
    },

    destroyed() {
      if (this.observer) {
        this.observer.disconnect();
      }
    },
  },

  CKEditor: {
    async mounted() {
      this.input = this.el.querySelector("input[type=hidden]");
      const target = this.el.querySelector("[data-ck-editor]");

      let CK;
      try {
        CK = await loadCKEditor();
      } catch (_e) {
        return; // CDN unavailable: the hidden input still holds existing content.
      }
      if (!this.el.isConnected) return; // hook removed while loading

      const {
        ClassicEditor,
        Essentials,
        Paragraph,
        Heading,
        Bold,
        Italic,
        Underline,
        Strikethrough,
        FontColor,
        FontBackgroundColor,
        Alignment,
        List,
        Link,
        BlockQuote,
        MediaEmbed,
        PasteFromOffice,
      } = CK;

      this.editor = await ClassicEditor.create(target, {
        licenseKey: "GPL",
        plugins: [
          Essentials,
          Paragraph,
          Heading,
          Bold,
          Italic,
          Underline,
          Strikethrough,
          FontColor,
          FontBackgroundColor,
          Alignment,
          List,
          Link,
          BlockQuote,
          MediaEmbed,
          PasteFromOffice,
        ],
        toolbar: [
          "undo",
          "redo",
          "|",
          "heading",
          "|",
          "bold",
          "italic",
          "underline",
          "strikethrough",
          "|",
          "fontColor",
          "fontBackgroundColor",
          "|",
          "alignment",
          "|",
          "bulletedList",
          "numberedList",
          "|",
          "link",
          "blockQuote",
          "mediaEmbed",
        ],
        mediaEmbed: {
          // Store the provider URL (<oembed url>) rather than a raw preview
          // iframe; RichText turns it into a sandboxed iframe at render time.
          previewsInData: false,
        },
        heading: {
          options: [
            { model: "paragraph", title: "Paragraph", class: "ck-heading_paragraph" },
            { model: "heading2", view: "h2", title: "Heading 2", class: "ck-heading_heading2" },
            { model: "heading3", view: "h3", title: "Heading 3", class: "ck-heading_heading3" },
          ],
        },
        fontColor: { colorPicker: { format: "hex" } },
        fontBackgroundColor: { colorPicker: { format: "hex" } },
      });

      if (!this.el.isConnected) {
        this.editor.destroy();
        this.editor = null;
        return;
      }

      this.editor.setData(this.input.value || "");
      this.currentValue = this.editor.getData();

      // Keep the hidden input (which the LiveView form submits) in sync.
      this.editor.model.document.on("change:data", () => {
        this.currentValue = this.editor.getData();
        this.input.value = this.currentValue;
        this.input.dispatchEvent(new Event("input", { bubbles: true }));
      });
    },

    updated() {
      // Server-driven content changes (e.g. reordering sections) arrive via the
      // data attribute. Only apply them when the author isn't actively typing.
      if (!this.editor) return;
      const incoming = this.el.dataset.ckValue || "";
      const focused = this.editor.editing.view.document.isFocused;
      if (!focused && incoming !== this.currentValue) {
        this.editor.setData(incoming);
        this.currentValue = incoming;
        if (this.input) this.input.value = incoming;
      }
    },

    destroyed() {
      if (this.editor) {
        this.editor.destroy();
        this.editor = null;
      }
    },
  },

  CopyLink: {
    mounted() {
      this.el.addEventListener("click", () => {
        const url = this.el.dataset.url;
        const label = this.el.querySelector("[data-copy-label]");
        const original = label ? label.textContent : null;

        const done = () => {
          if (label) {
            label.textContent = "Copied!";
            setTimeout(() => {
              label.textContent = original;
            }, 2000);
          }
        };

        if (navigator.clipboard && navigator.clipboard.writeText) {
          navigator.clipboard
            .writeText(url)
            .then(done)
            .catch(() => {});
        } else {
          const input = document.createElement("input");
          input.value = url;
          document.body.appendChild(input);
          input.select();
          document.execCommand("copy");
          document.body.removeChild(input);
          done();
        }
      });
    },
  },
};

const EXIT_INTENT_SESSION_KEY = "maraga_exit_intent_seen";
const EXIT_INTENT_ARM_DELAY_MS = 6000;

function initExitIntentModal() {
  const modal = document.querySelector("[data-exit-intent-modal]");
  if (!modal) return;

  const path = window.location.pathname;
  const isPrivatePath =
    path.startsWith("/admin") ||
    path.startsWith("/users") ||
    path.startsWith("/dev");

  const supportsExitIntent =
    window.matchMedia("(pointer: fine)").matches &&
    !window.matchMedia("(max-width: 1023px)").matches;

  if (isPrivatePath || !supportsExitIntent) return;

  const donateButton = modal.querySelector("[data-exit-intent-donate]");
  const closeTargets = modal.querySelectorAll("[data-exit-intent-close]");
  let isOpen = false;
  let startTime = Date.now();
  let bypassBeforeUnload = false;

  const markSeen = () => {
    try {
      window.sessionStorage.setItem(EXIT_INTENT_SESSION_KEY, "true");
    } catch (_e) {}
  };

  const seenThisSession = () => {
    try {
      return window.sessionStorage.getItem(EXIT_INTENT_SESSION_KEY) === "true";
    } catch (_e) {
      return false;
    }
  };

  const openModal = () => {
    if (isOpen || seenThisSession()) return;

    isOpen = true;
    markSeen();
    modal.classList.remove("hidden");
    modal.classList.add("flex");
    modal.setAttribute("aria-hidden", "false");
    document.body.classList.add("overflow-hidden");
    donateButton?.focus();
  };

  const closeModal = () => {
    if (!isOpen) return;

    isOpen = false;
    modal.classList.add("hidden");
    modal.classList.remove("flex");
    modal.setAttribute("aria-hidden", "true");
    document.body.classList.remove("overflow-hidden");
  };

  const isSamePageAnchor = (link) => {
    const href = link.getAttribute("href") || "";
    if (href.startsWith("#")) return true;

    try {
      const url = new URL(link.href, window.location.href);

      return (
        url.origin === window.location.origin &&
        url.pathname === window.location.pathname &&
        url.search === window.location.search &&
        url.hash !== ""
      );
    } catch (_e) {
      return false;
    }
  };

  const shouldBypassBeforeUnload = (event, link) => {
    if (!link) return false;
    if (event.defaultPrevented || event.button !== 0) return false;
    if (event.metaKey || event.ctrlKey || event.shiftKey || event.altKey) return false;
    if (link.hasAttribute("download")) return false;
    if ((link.getAttribute("target") || "").toLowerCase() === "_blank") return false;
    if (isSamePageAnchor(link)) return false;

    return true;
  };

  const handleMouseOut = (event) => {
    if (event.relatedTarget || event.toElement) return;
    if (event.clientY > 12) return;
    if (Date.now() - startTime < EXIT_INTENT_ARM_DELAY_MS) return;

    openModal();
  };

  const handleKeyDown = (event) => {
    if (event.key === "Escape") closeModal();
  };

  const handleDocumentClick = (event) => {
    const link = event.target.closest("a[href]");
    if (!shouldBypassBeforeUnload(event, link)) return;

    bypassBeforeUnload = true;
  };

  const handleBeforeUnload = (event) => {
    if (bypassBeforeUnload) return undefined;
    if (Date.now() - startTime < EXIT_INTENT_ARM_DELAY_MS) return undefined;

    event.preventDefault();
    event.returnValue = "";
    return "";
  };

  const handleFormSubmit = () => {
    bypassBeforeUnload = true;
  };

  closeTargets.forEach((element) => {
    element.addEventListener("click", closeModal);
  });

  document.addEventListener("mouseout", handleMouseOut);
  document.addEventListener("keydown", handleKeyDown);
  document.addEventListener("click", handleDocumentClick);
  document.addEventListener("submit", handleFormSubmit);
  window.addEventListener("beforeunload", handleBeforeUnload);

  window.addEventListener("phx:page-loading-stop", () => {
    startTime = Date.now();
    bypassBeforeUnload = false;
    closeModal();
  });
}

let csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute("content");
let liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: { _csrf_token: csrfToken },
  hooks: Hooks,
});

// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" });
window.addEventListener("phx:page-loading-start", (_info) => topbar.show(300));
window.addEventListener("phx:page-loading-stop", (_info) => topbar.hide());

// connect if there are any LiveViews on the page
liveSocket.connect();
initExitIntentModal();

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket;
