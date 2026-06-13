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
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"

const prefersReducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)")

const Hooks = {
  RevealOnScroll: {
    mounted() {
      if (prefersReducedMotion.matches) {
        this.el.classList.add("is-visible")
        return
      }

      this.observer = new IntersectionObserver(
        entries => {
          entries.forEach(entry => {
            if (!entry.isIntersecting) return

            this.el.classList.add("is-visible")
            this.observer.disconnect()
          })
        },
        {threshold: 0.18}
      )

      this.observer.observe(this.el)
    },

    destroyed() {
      if (this.observer) {
        this.observer.disconnect()
      }
    }
  },

  CopyLink: {
    mounted() {
      this.el.addEventListener("click", () => {
        const url = this.el.dataset.url
        const label = this.el.querySelector("[data-copy-label]")
        const original = label ? label.textContent : null

        const done = () => {
          if (label) {
            label.textContent = "Copied!"
            setTimeout(() => {
              label.textContent = original
            }, 2000)
          }
        }

        if (navigator.clipboard && navigator.clipboard.writeText) {
          navigator.clipboard.writeText(url).then(done).catch(() => {})
        } else {
          const input = document.createElement("input")
          input.value = url
          document.body.appendChild(input)
          input.select()
          document.execCommand("copy")
          document.body.removeChild(input)
          done()
        }
      })
    }
  }
}

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken},
  hooks: Hooks
})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket
