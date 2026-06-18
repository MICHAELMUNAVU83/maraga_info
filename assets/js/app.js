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
        ],
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

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket;
