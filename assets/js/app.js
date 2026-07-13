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
  CoverPosition: {
    mounted() {
      this.frame = this.el.querySelector("[data-cover-frame]");
      this.image = this.el.querySelector("[data-cover-image]");
      this.xInput = this.el.querySelector("[data-position-x-input]");
      this.yInput = this.el.querySelector("[data-position-y-input]");
      this.resetButton = this.el.querySelector("[data-reset-position]");
      this.drag = null;

      this.clamp = (value) => Math.max(0, Math.min(100, Math.round(value)));
      this.readPosition = () => ({
        x: this.clamp(Number.parseFloat(this.xInput?.value || this.el.dataset.positionX || 50)),
        y: this.clamp(Number.parseFloat(this.yInput?.value || this.el.dataset.positionY || 50)),
      });
      this.setPosition = (x, y) => {
        this.x = this.clamp(x);
        this.y = this.clamp(y);

        if (this.image) this.image.style.objectPosition = `${this.x}% ${this.y}%`;
        if (this.xInput) this.xInput.value = this.x;
        if (this.yInput) this.yInput.value = this.y;
      };
      this.commit = () => {
        this.xInput?.dispatchEvent(new Event("input", { bubbles: true }));
      };

      this.handlePointerDown = (event) => {
        if (event.button !== 0 || event.target.closest("button")) return;

        event.preventDefault();
        this.frame.setPointerCapture(event.pointerId);
        this.drag = {
          pointerId: event.pointerId,
          clientX: event.clientX,
          clientY: event.clientY,
          x: this.x,
          y: this.y,
        };
      };
      this.handlePointerMove = (event) => {
        if (!this.drag || event.pointerId !== this.drag.pointerId) return;

        event.preventDefault();
        const bounds = this.frame.getBoundingClientRect();
        const deltaX = ((event.clientX - this.drag.clientX) / bounds.width) * 100;
        const deltaY = ((event.clientY - this.drag.clientY) / bounds.height) * 100;

        // Increasing object-position moves an oversized image in the opposite
        // direction, hence subtraction makes the image follow the pointer.
        this.setPosition(this.drag.x - deltaX, this.drag.y - deltaY);
      };
      this.handlePointerUp = (event) => {
        if (!this.drag || event.pointerId !== this.drag.pointerId) return;

        this.frame.releasePointerCapture(event.pointerId);
        this.drag = null;
        this.commit();
      };
      this.handleReset = () => {
        this.setPosition(50, 50);
        this.commit();
      };

      this.frame?.addEventListener("pointerdown", this.handlePointerDown);
      this.frame?.addEventListener("pointermove", this.handlePointerMove);
      this.frame?.addEventListener("pointerup", this.handlePointerUp);
      this.frame?.addEventListener("pointercancel", this.handlePointerUp);
      this.resetButton?.addEventListener("click", this.handleReset);

      const { x, y } = this.readPosition();
      this.setPosition(x, y);
    },

    updated() {
      if (this.drag) return;
      const { x, y } = this.readPosition();
      this.setPosition(x, y);
    },

    destroyed() {
      this.frame?.removeEventListener("pointerdown", this.handlePointerDown);
      this.frame?.removeEventListener("pointermove", this.handlePointerMove);
      this.frame?.removeEventListener("pointerup", this.handlePointerUp);
      this.frame?.removeEventListener("pointercancel", this.handlePointerUp);
      this.resetButton?.removeEventListener("click", this.handleReset);
    },
  },

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

  SiteSearchModal: {
    mounted() {
      this.input = this.el.querySelector("[data-search-input]");
      this.items = Array.from(this.el.querySelectorAll("[data-search-item]"));
      this.emptyState = this.el.querySelector("[data-search-empty]");
      this.count = this.el.querySelector("[data-search-count]");

      this.filterItems = () => {
        const query = (this.input?.value || "").trim().toLowerCase();
        let visibleCount = 0;

        this.items.forEach((item) => {
          const searchText = (item.dataset.searchText || "").toLowerCase();
          const matches = query === "" || searchText.includes(query);

          item.classList.toggle("hidden", !matches);

          if (matches) visibleCount += 1;
        });

        if (this.count) {
          this.count.textContent = `${visibleCount} result${visibleCount === 1 ? "" : "s"}`;
        }

        if (this.emptyState) {
          this.emptyState.classList.toggle("hidden", visibleCount !== 0);
        }
      };

      this.handleInput = () => this.filterItems();
      this.handleOpen = () => {
        window.requestAnimationFrame(() => {
          if (this.input) {
            this.input.focus();
            this.input.select();
          }

          this.filterItems();
        });
      };
      this.handleClose = () => {
        if (this.input) {
          this.input.value = "";
        }

        this.filterItems();
      };

      this.input?.addEventListener("input", this.handleInput);
      this.el.addEventListener("site-search:open", this.handleOpen);
      this.el.addEventListener("site-search:close", this.handleClose);
      this.filterItems();
    },

    destroyed() {
      this.input?.removeEventListener("input", this.handleInput);
      this.el.removeEventListener("site-search:open", this.handleOpen);
      this.el.removeEventListener("site-search:close", this.handleClose);
    },
  },

  CKEditor: {
    async mounted() {
      this.input = this.el.querySelector("input[type=hidden]");
      // Section bodies (e.g. the email composer) can't rely on form
      // serialisation, so they opt into "push mode": each edit is sent to the
      // LiveView as `data-ck-push-event` with the section index and field.
      this.pushEventName = this.el.dataset.ckPushEvent || null;
      this.pushDebounceMs = 500;
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
        FontSize,
        FontColor,
        FontBackgroundColor,
        Alignment,
        List,
        Link,
        BlockQuote,
        MediaEmbed,
        PasteFromOffice,
        Image,
        ImageToolbar,
        ImageCaption,
        ImageStyle,
        ImageResize,
        ImageUpload,
        SimpleUploadAdapter,
      } = CK;

      const csrfToken =
        document
          .querySelector("meta[name='csrf-token']")
          ?.getAttribute("content") || "";

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
          FontSize,
          FontColor,
          FontBackgroundColor,
          Alignment,
          List,
          Link,
          BlockQuote,
          MediaEmbed,
          PasteFromOffice,
          Image,
          ImageToolbar,
          ImageCaption,
          ImageStyle,
          ImageResize,
          ImageUpload,
          SimpleUploadAdapter,
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
          "fontSize",
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
          "uploadImage",
          "mediaEmbed",
        ],
        mediaEmbed: {
          // Store the provider URL (<oembed url>) rather than a raw preview
          // iframe; RichText turns it into a sandboxed iframe at render time.
          previewsInData: false,
        },
        image: {
          toolbar: [
            "imageStyle:inline",
            "imageStyle:block",
            "imageStyle:side",
            "|",
            "toggleImageCaption",
            "imageTextAlternative",
          ],
        },
        simpleUpload: {
          // Inline images POST to an admin-only endpoint that stores the file
          // and returns its public /uploads URL. RichText whitelists the
          // resulting <figure class="image">/<img> markup.
          uploadUrl: "/admin/uploads/image",
          headers: { "X-CSRF-Token": csrfToken },
        },
        heading: {
          options: [
            { model: "paragraph", title: "Paragraph", class: "ck-heading_paragraph" },
            { model: "heading2", view: "h2", title: "Heading 2", class: "ck-heading_heading2" },
            { model: "heading3", view: "h3", title: "Heading 3", class: "ck-heading_heading3" },
          ],
        },
        fontSize: {
          // Numeric options with supportAllValues emit inline `font-size:NNpx`,
          // which RichText's sanitiser whitelists (see keep_style/2).
          options: [12, 14, "default", 18, 24, 30, 36],
          supportAllValues: true,
        },
        fontColor: { colorPicker: { format: "hex" } },
        fontBackgroundColor: { colorPicker: { format: "hex" } },
      });

      if (!this.el.isConnected) {
        this.editor.destroy();
        this.editor = null;
        return;
      }

      const seed =
        this.el.dataset.ckValue || (this.input && this.input.value) || "";
      this.editor.setData(seed);
      this.currentValue = this.editor.getData();

      // On every edit, push the new value out. In push mode we notify the
      // LiveView directly; otherwise we keep the hidden input (which the
      // surrounding form serialises on submit) in sync.
      this.editor.model.document.on("change:data", () => {
        this.currentValue = this.editor.getData();
        if (this.input) this.input.value = this.currentValue;
        if (this.applying) return; // programmatic setData — don't echo back
        if (this.pushEventName) {
          this.schedulePush();
        } else if (this.input) {
          this.input.dispatchEvent(new Event("input", { bubbles: true }));
        }
      });

      // Flush immediately when focus leaves so a click on Save / Send captures
      // the latest content before the server reads it.
      if (this.pushEventName) {
        this.editor.editing.view.document.on(
          "change:isFocused",
          (_evt, _name, isFocused) => {
            if (!isFocused) this.flushPush();
          },
        );
      }
    },

    schedulePush() {
      clearTimeout(this.pushTimer);
      this.pushTimer = setTimeout(() => this.flushPush(), this.pushDebounceMs);
    },

    flushPush() {
      if (!this.pushEventName) return;
      clearTimeout(this.pushTimer);
      this.pushEvent(this.pushEventName, {
        index: this.el.dataset.ckIndex,
        field: this.el.dataset.ckField,
        value: this.currentValue,
      });
    },

    updated() {
      // Server-driven content changes (e.g. reordering sections) arrive via the
      // data attribute. Only apply them when the author isn't actively typing.
      if (!this.editor) return;
      const incoming = this.el.dataset.ckValue || "";
      const focused = this.editor.editing.view.document.isFocused;
      if (!focused && incoming !== this.currentValue) {
        this.applying = true;
        this.editor.setData(incoming);
        this.applying = false;
        this.currentValue = incoming;
        if (this.input) this.input.value = incoming;
      }
    },

    destroyed() {
      clearTimeout(this.pushTimer);
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
