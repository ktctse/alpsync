import { Controller } from "@hotwired/stimulus"

// Type-to-search for resorts, with the picks shown as removable chips.
//
// The plain checkboxes in the fallback target are still the real form fields:
// this controller only hides them and ticks or unticks them, so the form posts
// exactly as before and still works if JavaScript doesn't load.
export default class extends Controller {
  static targets = ["picker", "fallback", "input", "list", "chips", "status"]
  static values = { resorts: Array, max: Number }

  connect() {
    this.fallbackTarget.hidden = true
    this.pickerTarget.hidden = false
    this.active = -1
    this.renderChips()
  }

  // --- Events -------------------------------------------------------------

  open() {
    this.say("")
    this.renderList()
  }

  close() {
    this.listTarget.hidden = true
    this.inputTarget.setAttribute("aria-expanded", "false")
    this.inputTarget.removeAttribute("aria-activedescendant")
  }

  keydown(event) {
    const isOpen = !this.listTarget.hidden

    switch (event.key) {
      case "ArrowDown":
        event.preventDefault()
        if (!isOpen) return this.renderList()
        return this.move(1)
      case "ArrowUp":
        event.preventDefault()
        if (!isOpen) return this.renderList()
        return this.move(-1)
      case "Enter":
        // Never let Enter in the search box submit the whole trip form.
        if (isOpen || this.inputTarget.value) event.preventDefault()
        if (isOpen && this.options[this.active]) this.pick(this.options[this.active].dataset.name)
        return
      case "Escape":
        if (isOpen) {
          event.preventDefault()
          this.close()
        } else {
          this.inputTarget.value = ""
        }
        return
      case "Backspace":
        if (!this.inputTarget.value && this.chosen.length) this.remove(this.chosen.at(-1))
        return
    }
  }

  // Clicking an option would otherwise blur the input and close the list first.
  keepFocus(event) {
    event.preventDefault()
  }

  choose(event) {
    const option = event.target.closest("[role=option]")
    if (option) this.pick(option.dataset.name)
  }

  unchoose(event) {
    // Focus first: focusing opens the list and clears the status line.
    this.inputTarget.focus()
    this.remove(event.currentTarget.dataset.name)
  }

  // --- Picking ------------------------------------------------------------

  pick(name) {
    if (this.chosen.length >= this.maxValue) {
      this.say(`You can pick up to ${this.maxValue} resorts. Remove one to add ${name}.`)
      return
    }
    this.checkbox(name).checked = true
    this.inputTarget.value = ""
    this.renderChips()
    this.renderList()
    this.say(`Added ${name}.`)
  }

  remove(name) {
    this.checkbox(name).checked = false
    this.renderChips()
    if (!this.listTarget.hidden) this.renderList()
    this.say(`Removed ${name}.`)
  }

  checkbox(name) {
    return this.fallbackTarget.querySelector(`input[type=checkbox][value="${CSS.escape(name)}"]`)
  }

  get chosen() {
    return [...this.fallbackTarget.querySelectorAll("input[type=checkbox]:checked")].map((box) => box.value)
  }

  say(message) {
    this.statusTarget.textContent = message
  }

  // --- Searching ----------------------------------------------------------

  // Best matches first: the resort's name, then a word in it, then a nickname,
  // then its region. Accents, case, spaces and hyphens don't matter.
  search(query) {
    const q = normalize(query)
    const chosen = this.chosen
    const results = []

    this.resortsValue.forEach((resort, order) => {
      if (chosen.includes(resort.name)) return
      if (!q) return results.push({ resort, rank: 0, order })

      const name = normalize(resort.name)
      const words = resort.name.split(/[\s-]+/).map(normalize)
      const nickname = resort.nicknames.find((nick) => normalize(nick).startsWith(q)) ||
                       resort.nicknames.find((nick) => normalize(nick).includes(q))
      let rank
      if (name.startsWith(q)) rank = 0
      else if (words.some((word) => word.startsWith(q))) rank = 1
      else if (nickname && normalize(nickname).startsWith(q)) rank = 2
      else if (resort.places.some((place) => normalize(place).startsWith(q))) rank = 3
      else if (name.includes(q) || nickname) rank = 4
      else return

      // Say why a nickname matched, so "Hirafu" visibly leads to Niseko United.
      const via = rank >= 2 && nickname && !name.includes(q) ? nickname : null
      results.push({ resort, rank, order, via })
    })

    return results.sort((a, b) => a.rank - b.rank || a.order - b.order)
  }

  // --- Rendering ----------------------------------------------------------

  renderList() {
    const query = this.inputTarget.value.trim()
    const results = this.search(query)
    const list = this.listTarget
    list.replaceChildren()

    if (this.chosen.length >= this.maxValue) {
      list.append(note(`That's ${this.maxValue}, the most one trip can cover.`))
    } else if (!results.length) {
      list.append(note(query ? `No resort matches "${query}" yet. Mention it in your notes.` : "You've picked them all."))
    } else if (!query) {
      // Browsing: everything, under region headings.
      let region
      for (const { resort } of results) {
        if (resort.region !== region) {
          region = resort.region
          list.append(heading(region))
        }
        list.append(this.option(resort, null, { showRegion: false }))
      }
    } else {
      for (const { resort, via } of results) list.append(this.option(resort, via))
    }

    list.hidden = false
    this.inputTarget.setAttribute("aria-expanded", "true")
    this.highlight(query && results.length ? 0 : -1)
  }

  option(resort, via, { showRegion = true } = {}) {
    const item = document.createElement("li")
    item.id = `resort_option_${resort.name.toLowerCase().replace(/[^a-z0-9]+/g, "_")}`
    item.setAttribute("role", "option")
    item.setAttribute("aria-selected", "false")
    item.dataset.name = resort.name
    item.className = "flex cursor-pointer items-baseline justify-between gap-3 rounded-md px-3 py-2 text-sm text-slate-800 aria-selected:bg-slate-100"

    const name = document.createElement("span")
    name.textContent = resort.name
    if (via) {
      const hint = document.createElement("span")
      hint.className = "ml-1.5 text-slate-500"
      hint.textContent = `(${via})`
      name.append(hint)
    }
    item.append(name)

    // Left out while browsing, where the region is already the heading above.
    if (showRegion) {
      const region = document.createElement("span")
      region.className = "shrink-0 text-xs text-slate-500"
      region.textContent = resort.region
      item.append(region)
    }
    item.addEventListener("mousemove", () => this.highlight(this.options.indexOf(item)))
    return item
  }

  get options() {
    return [...this.listTarget.querySelectorAll("[role=option]")]
  }

  // Arrow keys wrap around from the last option to the first and back.
  move(step) {
    const count = this.options.length
    if (!count) return
    this.highlight((this.active + step + count + (this.active < 0 && step < 0 ? 1 : 0)) % count)
  }

  highlight(index) {
    const options = this.options
    this.active = index
    options.forEach((option, i) => option.setAttribute("aria-selected", String(i === index)))

    const current = options[index]
    if (current) {
      this.inputTarget.setAttribute("aria-activedescendant", current.id)
      current.scrollIntoView({ block: "nearest" })
    } else {
      this.inputTarget.removeAttribute("aria-activedescendant")
    }
  }

  renderChips() {
    const chosen = this.chosen
    this.chipsTarget.replaceChildren(...chosen.map((name) => {
      const item = document.createElement("li")
      const button = document.createElement("button")
      button.type = "button"
      button.dataset.name = name
      button.dataset.action = "resort-picker#unchoose"
      button.setAttribute("aria-label", `Remove ${name}`)
      button.className = "inline-flex cursor-pointer items-center gap-1.5 rounded-full bg-slate-900 py-1.5 pr-2.5 pl-3 text-sm text-white hover:bg-slate-700 focus-visible:ring-2 focus-visible:ring-sky-300 focus-visible:outline-none"
      button.textContent = name
      const cross = document.createElement("span")
      cross.setAttribute("aria-hidden", "true")
      cross.className = "text-slate-300"
      cross.textContent = "×"
      button.append(cross)
      item.append(button)
      return item
    }))
    this.chipsTarget.hidden = chosen.length === 0

    const full = chosen.length >= this.maxValue
    this.inputTarget.placeholder = full ? `That's ${this.maxValue}. Remove one to change` : "Search resorts, e.g. Niseko or Whistler"
  }
}

function normalize(text) {
  return text.normalize("NFKD").replace(/[̀-ͯ]/g, "").toLowerCase().replace(/[\s\-'’.]+/g, "")
}

function heading(text) {
  const item = document.createElement("li")
  item.setAttribute("role", "presentation")
  item.className = "px-3 pt-2 pb-1 text-xs font-medium text-slate-500"
  item.textContent = text
  return item
}

function note(text) {
  const item = document.createElement("li")
  item.setAttribute("role", "presentation")
  item.className = "px-3 py-2 text-sm text-slate-500"
  item.textContent = text
  return item
}
