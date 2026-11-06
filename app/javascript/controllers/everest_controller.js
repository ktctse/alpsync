import { Controller } from "@hotwired/stimulus"

// The closing motion graphic: a jagged white line traces Mount Everest around the
// Alpsync logo. Moving the pointer left and right circles the mountain (its skyline
// from the south, west, north and east); moving it down tilts the view until you're
// looking down on the South Col route. Left alone, it drifts around by itself.
// It only animates while on screen, and holds still for people who prefer reduced
// motion (it still follows the pointer, since that motion is theirs).

const POINTS = 240 // per shape; index POINTS / 2 is always the summit
const BACKGROUND = "#05070b"
const BLUE = "#0084d1"
const LOGO_ARM = "M32 32V7.2M28.4 8.2 32 11.6l3.6-3.4M32 14l15.6 9M32 14l5.2 9-5.2 9m5.2-9h10.4"

// Skylines as [x, y] knots from the left base, through the summit at [0, 1], to the
// right base. Hand-drawn from photos of each face; heights are relative, not to scale.
const VIEWS = [
  {
    name: "Seen from the south",
    knots: [[-1, 0.02], [-0.82, 0.16], [-0.66, 0.38], [-0.54, 0.56], [-0.47, 0.6], [-0.4, 0.53], [-0.3, 0.6],
            [-0.18, 0.72], [-0.09, 0.88], [0, 1], [0.08, 0.84], [0.17, 0.72], [0.24, 0.68], [0.31, 0.78],
            [0.39, 0.9], [0.47, 0.76], [0.6, 0.56], [0.76, 0.32], [0.9, 0.14], [1, 0.02]]
  },
  {
    name: "Seen from the west",
    knots: [[-1, 0.02], [-0.84, 0.12], [-0.68, 0.28], [-0.52, 0.46], [-0.36, 0.62], [-0.2, 0.8], [-0.1, 0.9],
            [0, 1], [0.1, 0.88], [0.2, 0.8], [0.3, 0.76], [0.42, 0.68], [0.54, 0.64], [0.64, 0.58],
            [0.74, 0.42], [0.86, 0.22], [1, 0.02]]
  },
  {
    name: "Seen from the north",
    knots: [[-1, 0.02], [-0.86, 0.12], [-0.72, 0.26], [-0.6, 0.4], [-0.52, 0.46], [-0.46, 0.44], [-0.38, 0.54],
            [-0.26, 0.68], [-0.14, 0.84], [0, 1], [0.1, 0.86], [0.2, 0.72], [0.3, 0.6], [0.38, 0.5],
            [0.46, 0.54], [0.54, 0.5], [0.66, 0.36], [0.82, 0.18], [1, 0.02]]
  },
  {
    name: "Seen from the east",
    knots: [[-1, 0.02], [-0.8, 0.22], [-0.62, 0.42], [-0.46, 0.58], [-0.3, 0.7], [-0.16, 0.82], [0, 1],
            [0.14, 0.88], [0.26, 0.84], [0.36, 0.86], [0.44, 0.92], [0.54, 0.76], [0.68, 0.54], [0.82, 0.3],
            [1, 0.02]]
  }
]

// Looking down: the South Col route up from Base Camp (Khumbu Icefall, Western Cwm,
// Lhotse Face, South Col) to the summit, and a descent line back down beside it.
const ROUTE = {
  name: "The South Col route, from above",
  knots: [[-0.04, 0], [-0.12, 0.06], [0.02, 0.12], [-0.1, 0.18], [0.04, 0.24], [-0.06, 0.3], [0.02, 0.38],
          [0.1, 0.48], [0.16, 0.56], [0.08, 0.6], [0.18, 0.64], [0.09, 0.68], [0.19, 0.72], [0.12, 0.8],
          [0.06, 0.88], [0.02, 0.95], [0, 1], [0.05, 0.93], [-0.03, 0.86], [0.04, 0.78], [-0.07, 0.7],
          [-0.01, 0.6], [-0.13, 0.5], [-0.05, 0.38], [-0.15, 0.28], [-0.07, 0.16], [-0.17, 0.08], [-0.1, 0]]
}

export default class extends Controller {
  static targets = ["canvas", "view"]

  connect() {
    this.pen = this.canvasTarget.getContext("2d")
    this.reducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches
    this.views = VIEWS.map((view, i) => ({ name: view.name, points: buildShape(view.knots, 0.03, 11 + i) }))
    this.route = { name: ROUTE.name, points: buildShape(ROUTE.knots, 0.016, 31) }
    this.boils = [1, 2, 3].map(seed => jitter(seed, 0.0035))
    this.logo = logoPath()

    this.azimuth = this.targetAzimuth = 0 // 0..4, one unit per face
    this.tilt = this.targetTilt = 0 // 0 = side view, 1 = from above
    this.lastPointerAt = -Infinity

    this.resize = new ResizeObserver(() => this.fit())
    this.resize.observe(this.canvasTarget)
    this.visibility = new IntersectionObserver(([entry]) => entry.isIntersecting ? this.play() : this.pause())
    this.visibility.observe(this.element)
  }

  disconnect() {
    this.pause()
    this.resize.disconnect()
    this.visibility.disconnect()
  }

  point(event) {
    const box = this.element.getBoundingClientRect()
    this.targetAzimuth = ((event.clientX - box.left) / box.width) * VIEWS.length
    this.targetTilt = clamp(((event.clientY - box.top) / box.height - 0.45) / 0.4, 0, 1)
    this.lastPointerAt = performance.now()
    if (this.reducedMotion) {
      this.azimuth = this.targetAzimuth
      this.tilt = this.targetTilt
      this.draw()
    }
  }

  release() {
    this.lastPointerAt = -Infinity
  }

  play() {
    if (this.reducedMotion) return this.draw()
    if (this.frame) return
    this.previous = performance.now()
    const tick = (now) => {
      this.step(now)
      this.draw(now)
      this.frame = requestAnimationFrame(tick)
    }
    this.frame = requestAnimationFrame(tick)
  }

  pause() {
    cancelAnimationFrame(this.frame)
    this.frame = null
  }

  fit() {
    const ratio = window.devicePixelRatio || 1
    const { clientWidth: width, clientHeight: height } = this.canvasTarget
    this.canvasTarget.width = Math.round(width * ratio)
    this.canvasTarget.height = Math.round(height * ratio)
    this.pen.setTransform(ratio, 0, 0, ratio, 0, 0)
    this.size = { width, height }
    this.draw()
  }

  // Ease towards the pointer, or drift around the mountain when nobody's pointing.
  step(now) {
    const elapsed = Math.min(now - this.previous, 50)
    this.previous = now
    if (now - this.lastPointerAt > 2500) {
      this.targetAzimuth += elapsed * 0.00012
      this.targetTilt = 0.35 - 0.35 * Math.cos(now * 0.00022)
    }
    const turn = mod(this.targetAzimuth - this.azimuth + 2, 4) - 2
    this.azimuth = mod(this.azimuth + turn * 0.06, 4)
    this.tilt += (this.targetTilt - this.tilt) * 0.06
  }

  draw(now = 0) {
    if (!this.size) return
    const { width, height } = this.size
    const ctx = this.pen
    ctx.fillStyle = BACKGROUND
    ctx.fillRect(0, 0, width, height)

    // Where the mountain sits: summit near the upper middle, base towards the bottom.
    const tall = Math.min(height * 0.6, width * 0.75)
    const half = Math.min(width * 0.42, tall * 1.25)
    const baseY = height * 0.5 + tall * 0.42
    const centerX = width / 2

    const shape = this.currentShape()
    const boil = this.reducedMotion ? this.boils[0] : this.boils[Math.floor(now / 110) % this.boils.length]
    this.drawLogo(centerX + half * 0.11, baseY - tall * 0.74, Math.min(tall * 0.19, half * 0.3))

    ctx.beginPath()
    for (let i = 0; i < POINTS; i++) {
      const x = centerX + (shape[i * 2] + boil[i * 2]) * half
      const y = baseY - (shape[i * 2 + 1] + boil[i * 2 + 1]) * tall
      i ? ctx.lineTo(x, y) : ctx.moveTo(x, y)
    }
    ctx.strokeStyle = "rgba(255, 255, 255, 0.92)"
    ctx.lineWidth = 1.2
    ctx.lineJoin = "round"
    ctx.stroke()

    const name = this.tilt > 0.55 ? this.route.name : this.views[Math.round(this.azimuth) % VIEWS.length].name
    if (this.hasViewTarget && this.viewTarget.textContent !== name) this.viewTarget.textContent = name
  }

  // Blend the two nearest faces, then tilt towards the route seen from above.
  currentShape() {
    const from = Math.floor(this.azimuth) % VIEWS.length
    const to = (from + 1) % VIEWS.length
    const turn = smooth(this.azimuth - Math.floor(this.azimuth))
    const tilt = smooth(this.tilt)
    const a = this.views[from].points
    const b = this.views[to].points
    const route = this.route.points
    const shape = new Float32Array(POINTS * 2)
    for (let i = 0; i < shape.length; i++) {
      const side = a[i] + (b[i] - a[i]) * turn
      shape[i] = side + (route[i] - side) * tilt
    }
    return shape
  }

  // The Alpsync snowflake in blue, drawn hollow (a wide blue stroke with a thin
  // background-coloured stroke inside it), turning as you circle the mountain.
  drawLogo(x, y, radius) {
    const ctx = this.pen
    const scale = radius / 32
    ctx.save()
    ctx.translate(x, y)
    ctx.rotate(this.azimuth * (Math.PI / 6))
    ctx.scale(scale, scale)
    ctx.translate(-32, -32)
    ctx.lineJoin = ctx.lineCap = "round"
    ctx.strokeStyle = BLUE
    ctx.lineWidth = 3.2 / scale
    ctx.stroke(this.logo)
    ctx.strokeStyle = BACKGROUND
    ctx.lineWidth = 1.1 / scale
    ctx.stroke(this.logo)
    ctx.restore()
  }
}

// Samples the knots into POINTS evenly spaced points with the summit at the middle
// index, then roughens them into a rocky, hand-drawn line.
function buildShape(knots, roughness, seed) {
  const summit = knots.findIndex(([x, y]) => x === 0 && y === 1)
  const up = resample(knots.slice(0, summit + 1), POINTS / 2 + 1)
  const down = resample(knots.slice(summit), POINTS / 2)
  const points = up.concat(down.slice(1))
  const dx = fractalNoise(seed, roughness)
  const dy = fractalNoise(seed + 100, roughness)
  const shape = new Float32Array(POINTS * 2)
  points.forEach(([x, y], i) => {
    const pin = i === POINTS / 2 ? 0 : 1 // keep the summit exactly in place
    shape[i * 2] = x + dx[i] * pin
    shape[i * 2 + 1] = y + dy[i] * pin
  })
  return shape
}

function resample(knots, count) {
  const lengths = [0]
  for (let i = 1; i < knots.length; i++) {
    lengths.push(lengths[i - 1] + Math.hypot(knots[i][0] - knots[i - 1][0], knots[i][1] - knots[i - 1][1]))
  }
  const total = lengths[lengths.length - 1]
  const points = []
  let segment = 1
  for (let n = 0; n < count; n++) {
    const at = (total * n) / (count - 1)
    while (segment < knots.length - 1 && lengths[segment] < at) segment++
    const span = lengths[segment] - lengths[segment - 1] || 1
    const t = (at - lengths[segment - 1]) / span
    const [x0, y0] = knots[segment - 1]
    const [x1, y1] = knots[segment]
    points.push([x0 + (x1 - x0) * t, y0 + (y1 - y0) * t])
  }
  return points
}

// Sum of six sine octaves with random phases: jagged at small scale, wandering at
// large scale, and the same every time for a given seed.
function fractalNoise(seed, amplitude) {
  const random = seeded(seed)
  const octaves = [0, 1, 2, 3, 4, 5].map(o => ({
    frequency: 0.2 * 2 ** o * (0.75 + random() * 0.5),
    phase: random() * Math.PI * 2,
    weight: 0.68 ** o
  }))
  const total = octaves.reduce((sum, o) => sum + o.weight, 0)
  return Array.from({ length: POINTS }, (_, i) =>
    (octaves.reduce((sum, o) => sum + o.weight * Math.sin(i * o.frequency + o.phase), 0) / total) * amplitude)
}

// A small random wobble per point; cycling three of these gives the line its
// stop-motion "boil".
function jitter(seed, amplitude) {
  const random = seeded(seed)
  return Float32Array.from({ length: POINTS * 2 }, () => (random() * 2 - 1) * amplitude)
}

function logoPath() {
  const path = new Path2D()
  path.arc(32, 32, 27.5, 0, Math.PI * 2)
  path.closePath()
  const arm = new Path2D(LOGO_ARM)
  for (let k = 0; k < 6; k++) {
    path.addPath(arm, new DOMMatrix().translate(32, 32).rotate(k * 60).translate(-32, -32))
  }
  return path
}

function seeded(seed) {
  let a = seed
  return () => {
    a = (a + 0x6d2b79f5) | 0
    let t = Math.imul(a ^ (a >>> 15), 1 | a)
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296
  }
}

const clamp = (value, min, max) => Math.min(max, Math.max(min, value))
const mod = (value, n) => ((value % n) + n) % n
const smooth = (t) => t * t * (3 - 2 * t)
