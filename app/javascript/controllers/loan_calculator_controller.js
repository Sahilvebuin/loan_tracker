import { Controller } from "@hotwired/stimulus"
import { Chart } from "chart.bundle"

const INR = new Intl.NumberFormat("en-IN", { style: "currency", currency: "INR", maximumFractionDigits: 0 })

const MONTH_SHORT = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
const EMI_PAY_DAY = 15

/** EMI-calculator style: green / orange / magenta */
const SCH = {
  principal: "#80C000",
  interest: "#FF9900",
  balance: "#C00058",
  balanceFill: "rgba(192, 0, 88, 0.07)",
}

function toNumber(value, fallback = 0) {
  if (value == null) return fallback
  const s = String(value).trim()
  if (!s) return fallback
  // Strip currency, spaces, narrow no-break space; commas (Western or Indian grouping)
  const cleaned = s.replace(/[₹\s\u00a0]/g, "").replace(/,/g, "")
  const n = Number(cleaned)
  return Number.isFinite(n) ? n : fallback
}

function formatInr(n) {
  return INR.format(Math.round(n))
}

function formatAxisInr(v) {
  if (!Number.isFinite(v)) return ""
  const abs = Math.abs(v)
  if (abs >= 1e7) return `₹ ${(v / 1e7).toFixed(2)} Cr`
  if (abs >= 1e5) return `₹ ${Math.round(v / 1e5)} L`
  if (abs >= 1e3) return `₹ ${Math.round(v / 1e3)}k`
  return formatInr(v)
}

/** Axis ticks like the reference: ₹ 10,000, ₹ 20,000 (Western grouping, easy to scan). */
const AXIS_COMMA = new Intl.NumberFormat("en-US", { maximumFractionDigits: 0 })

function formatAxisCommaRupee(v) {
  if (!Number.isFinite(v)) return ""
  return `₹ ${AXIS_COMMA.format(Math.round(v))}`
}

function round2(n) {
  return Math.round(n * 100) / 100
}

/** Months to close at a fixed monthly payment (original EMI) on outstanding principal. */
function monthsFromFixedEmi(principal, annualRatePercent, monthlyPayment) {
  const p = principal
  const e = monthlyPayment
  if (p <= 0) return 0
  if (e <= 0) return 0
  const r = annualRatePercent / 12 / 100
  if (r === 0) return Math.max(0, Math.ceil(p / e))
  if (e <= p * r) return 0
  const k = e / (e - p * r)
  if (k <= 1) return 0
  return Math.max(1, Math.ceil(Math.log(k) / Math.log(1 + r)))
}

function emi(principal, annualRatePercent, months) {
  const p = principal
  const r = annualRatePercent / 12 / 100
  const n = months

  if (n <= 0 || p <= 0) return 0
  if (r === 0) return p / n

  const x = Math.pow(1 + r, n)
  return (p * r * x) / (x - 1)
}

function buildMonthSchedule({ principal, annualRatePercent, months, startYear, startMonth, fixedPayment }) {
  const payment = fixedPayment != null ? fixedPayment : emi(principal, annualRatePercent, months)
  const r = annualRatePercent / 12 / 100
  let balance = principal
  const rows = []
  let y = startYear
  let mo = startMonth

  for (let i = 0; i < months && balance > 0.01; i++) {
    const interest = balance * r
    let pp = payment - interest
    if (pp > balance) pp = balance
    balance -= pp
    rows.push({
      calYear: y,
      month: mo,
      day: EMI_PAY_DAY,
      principalPaid: round2(pp),
      interestPaid: round2(interest),
      totalPaid: round2(pp + interest),
      balance: round2(Math.max(balance, 0)),
      paidToDate: round2(principal > 0 ? ((principal - balance) / principal) * 100 : 0),
    })
    mo += 1
    if (mo > 12) {
      mo = 1
      y += 1
    }
  }
  return rows
}

/** EMIs whose due date (15th) has already passed — autopay treated as done for those months. */
function countAutopayEmisAlreadyPassed(startYear, startMonth, maxMonths) {
  const now = new Date()
  const today = new Date(now.getFullYear(), now.getMonth(), now.getDate())
  let y = startYear
  let mo = startMonth
  let paid = 0
  while (paid < maxMonths) {
    const due = new Date(y, mo - 1, EMI_PAY_DAY)
    due.setHours(0, 0, 0, 0)
    if (today <= due) break
    paid += 1
    mo += 1
    if (mo > 12) {
      mo = 1
      y += 1
    }
  }
  return paid
}

/**
 * Outstanding balance and remaining totals after autopay EMIs (same slice as yearly table).
 * +full+ schedule is built from pre-autopay principal + tenure; +skip+ rows are treated as already paid.
 */
function scheduleAfterAutopay(principal, annualRatePercent, months, fixedPayment, startYear, startMonth) {
  const full = buildMonthSchedule({
    principal,
    annualRatePercent,
    months,
    startYear,
    startMonth,
    fixedPayment,
  })
  const skipRaw = countAutopayEmisAlreadyPassed(startYear, startMonth, months)
  const skip = Math.min(skipRaw, full.length)
  let outstanding = principal
  if (skip > 0) {
    outstanding = skip >= full.length ? 0 : full[skip - 1].balance
  }
  const tail = full.slice(skip)
  let totalPayRem = 0
  let totalIntRem = 0
  for (const r of tail) {
    totalPayRem += r.totalPaid
    totalIntRem += r.interestPaid
  }
  return { full, skip, outstanding, remainingMonths: tail.length, totalPayRem, totalIntRem }
}

function groupIntoPeriods(monthRows, basis) {
  const map = new Map()
  const order = []

  for (const row of monthRows) {
    let periodKey
    let label
    if (basis === "financial") {
      const fy = row.month >= 4 ? row.calYear : row.calYear - 1
      periodKey = `fy:${fy}`
      const y2 = (fy + 1) % 100
      label = `FY ${fy}\u2013${String(y2).padStart(2, "0")}`
    } else {
      periodKey = `cy:${row.calYear}`
      label = String(row.calYear)
    }

    if (!map.has(periodKey)) {
      map.set(periodKey, {
        periodKey,
        label,
        months: [],
        principalPaid: 0,
        interestPaid: 0,
        totalPaid: 0,
        endBalance: 0,
        paidToDate: 0,
      })
      order.push(periodKey)
    }
    const g = map.get(periodKey)
    g.months.push(row)
    g.principalPaid += row.principalPaid
    g.interestPaid += row.interestPaid
    g.totalPaid += row.totalPaid
    g.endBalance = row.balance
    g.paidToDate = row.paidToDate
  }

  return order.map((k) => {
    const g = map.get(k)
    return {
      ...g,
      principalPaid: round2(g.principalPaid),
      interestPaid: round2(g.interestPaid),
      totalPaid: round2(g.totalPaid),
    }
  })
}

function monthCellLabel(m) {
  const d = m.day || EMI_PAY_DAY
  return `${String(d).padStart(2, "0")} ${MONTH_SHORT[m.month - 1]} ${m.calYear}`
}

const FALLBACK = {
  home: {
    principal: 2_637_000,
    outstanding_principal: 2_637_000,
    recorded_prepayment_total: 0,
    amount_slider_max: 20_000_000,
    annual_interest_rate: 7.7,
    term_months: 165,
  },
  additional: {
    principal: 493_693,
    outstanding_principal: 493_693,
    recorded_prepayment_total: 0,
    amount_slider_max: 5_000_000,
    annual_interest_rate: 7.55,
    term_months: 172,
  },
}

function fullFallbackConfig() {
  return {
    home: { ...FALLBACK.home },
    additional: { ...FALLBACK.additional },
  }
}

export default class extends Controller {
  static values = {
    config: Object,
    storageKey: String,
  }

  initialize() {
    // Must run before configValueChanged(); otherwise applyDefaults(undefined) clears the amount label text.
    this.activeLoanType = "home"
    this.appliedPrepayments = { home: [], additional: [] }
    /** Original sanctioned principal for EMI math; amount field may show current outstanding after EMI due dates. */
    this.emiBasisBySlot = { home: null, additional: null }
  }

  storageNamespace() {
    const k = this.hasStorageKeyValue && this.storageKeyValue ? String(this.storageKeyValue) : "default"
    return `lc:appliedPrepayments:${k}`
  }

  loadPersistedPrepayments() {
    try {
      const raw = window.localStorage.getItem(this.storageNamespace())
      if (!raw) return
      const parsed = JSON.parse(raw)
      if (!parsed || typeof parsed !== "object") return
      const home = Array.isArray(parsed.home) ? parsed.home : []
      const additional = Array.isArray(parsed.additional) ? parsed.additional : []
      const sanitize = (arr) =>
        arr
          .map((p) => ({
            amount: Math.max(0, Number(p?.amount) || 0),
            paidOn: p?.paidOn ? String(p.paidOn) : "",
            notes: p?.notes ? String(p.notes) : "",
            monthsSaved: Math.max(0, Number(p?.monthsSaved) || 0),
            interestSaved: Math.max(0, Number(p?.interestSaved) || 0),
          }))
          .filter((p) => p.amount > 0.01)
      this.appliedPrepayments = { home: sanitize(home), additional: sanitize(additional) }
    } catch (_) {
      /* ignore */
    }
  }

  persistAppliedPrepayments() {
    try {
      window.localStorage.setItem(this.storageNamespace(), JSON.stringify(this.appliedPrepayments))
    } catch (_) {
      /* ignore */
    }
  }

  static targets = [
    "tab",
    "amountLabel",
    "amountInput",
    "amountRange",
    "amountMarks",
    "amountSaveBtn",
    "rateInput",
    "rateRange",
    "tenureInput",
    "tenureRange",
    "tenureUnitBtn",
    "emiOut",
    "interestOut",
    "totalOut",
    "donutRing",
    "donutPriPct",
    "donutIntPct",
    "prepaymentInput",
    "prepaymentDateInput",
    "prepaymentNoteInput",
    "prepayPreview",
    "prepayPreviewInterest",
    "prepayPreviewMonths",
    "appliedPrepaymentsWrap",
    "appliedPrepaymentsList",
    "saveLoanForm",
    "savePrepaymentForm",
    "savedPrepaymentsWrap",
    "effectivePrincipalOut",
    "effectivePrincipalNote",
    "remainingTenureOut",
    "scheduleStart",
    "scheduleBasis",
    "yearlyWrap",
    "yearlySsrFallback",
    "yearlyCanvasWrap",
    "yearlyCanvas",
    "yearlyBody",
  ]

  connect() {
    this.yearlyChart = null

    this.loadPersistedPrepayments()
    this.bootstrapFromConfig()
    this.renderAppliedPrepayments()
    this.syncSaveLoanUi()
    this.syncSavePrepaymentUi()
    this.recalc()
    requestAnimationFrame(() => {
      this.loadPersistedPrepayments()
      this.bootstrapFromConfig()
      this.renderAppliedPrepayments()
      this.syncSaveLoanUi()
      this.syncSavePrepaymentUi()
      this.recalc()
    })
  }

  configValueChanged() {
    this.bootstrapFromConfig()
    this.recalc()
  }

  mergedConfig() {
    const fromStimulus = this.configValue && Object.keys(this.configValue).length > 0 ? this.configValue : null
    if (fromStimulus?.home && fromStimulus?.additional) return fromStimulus

    const raw = this.element.getAttribute("data-loan-calculator-config-value")
    if (raw) {
      try {
        const parsed = JSON.parse(raw)
        if (parsed?.home && parsed?.additional) return parsed
      } catch (_) {
        /* ignore */
      }
    }
    return fullFallbackConfig()
  }

  bootstrapFromConfig() {
    this.applyDefaults(this.activeLoanType)
  }

  disconnect() {
    this.yearlyChart?.destroy()
    this.yearlyChart = null
  }

  scheduleControlChanged() {
    this.recalc()
  }

  /** Delegated from `.lc-tabs` so the whole tab strip receives clicks reliably. */
  onTabBarClick(event) {
    const btn = event.target.closest("button.lc-tab[data-loan-type]")
    if (!btn || !this.element.contains(btn)) return
    event.preventDefault()
    event.stopPropagation()
    const type = btn.getAttribute("data-loan-type")
    this.activateLoanTab(type)
  }

  activateLoanTab(type) {
    if (type !== "home" && type !== "additional") return
    this.activeLoanType = type
    this.tabTargets.forEach((el) => {
      const tabType = el.getAttribute("data-loan-type") || el.dataset.loanType
      const on = tabType === type
      el.classList.toggle("lc-tab--active", on)
      el.setAttribute("aria-selected", on ? "true" : "false")
    })
    this.applyDefaults(type)
    this.renderAppliedPrepayments()
    this.syncSaveLoanUi()
    this.syncSavePrepaymentUi()
    this.previewPrepayment()
    this.recalc()
  }

  syncSaveLoanUi() {
    const key = this.currentKey()
    const forms = this.saveLoanFormTargets || []
    forms.forEach((f) => {
      const type = f.dataset.loanType
      const show = type === key
      f.hidden = !show
    })
    const activeForm = forms.find((f) => f.dataset.loanType === key)
    if (this.hasAmountSaveBtnTarget) {
      if (activeForm && activeForm.id) {
        this.amountSaveBtnTarget.hidden = false
        this.amountSaveBtnTarget.setAttribute("form", activeForm.id)
      } else {
        this.amountSaveBtnTarget.hidden = true
        this.amountSaveBtnTarget.removeAttribute("form")
      }
    }
    if (activeForm && activeForm.id && this.hasAmountInputTarget) {
      // Submit sanctioned principal (EMI basis), not the displayed current outstanding.
      this.amountInputTarget.removeAttribute("name")
      this.amountInputTarget.removeAttribute("form")
      const hid = activeForm.querySelector('input[type="hidden"][name="loan[principal]"]')
      if (hid) hid.value = String(Math.round(this.emiBasisPrincipal()))
    }
  }

  syncSavePrepaymentUi() {
    // Amount input should submit to the correct loan's form (home vs additional).
    const key = this.currentKey()
    const forms = this.savePrepaymentFormTargets || []
    forms.forEach((f) => {
      const type = f.dataset.loanType
      const show = type === key
      f.hidden = !show
    })
    const wraps = this.savedPrepaymentsWrapTargets || []
    wraps.forEach((w) => {
      const type = w.dataset.loanType
      const show = type === key
      w.hidden = !show
    })

    const activeForm = forms.find((f) => f.dataset.loanType === key)
    if (!this.hasPrepaymentInputTarget) return
    if (activeForm && activeForm.id) {
      this.prepaymentInputTarget.setAttribute("name", "prepayment[amount]")
      this.prepaymentInputTarget.setAttribute("form", activeForm.id)
      if (this.hasPrepaymentNoteInputTarget) {
        this.prepaymentNoteInputTarget.setAttribute("name", "prepayment[notes]")
        this.prepaymentNoteInputTarget.setAttribute("form", activeForm.id)
      }
    }
  }

  applyDefaults(type) {
    const loanType = type === "additional" ? "additional" : "home"
    const labels = { home: "Home Loan Amount", additional: "Additional Home Loan Amount" }
    if (this.hasAmountLabelTarget) {
      this.amountLabelTarget.textContent = labels[loanType]
    }

    const cfg = this.mergedConfig()
    const slot = cfg[loanType] || {}
    const fb = FALLBACK[loanType]
    const principal = Number(slot.principal) || fb.principal
    this.emiBasisBySlot[loanType] = principal
    const max = Number(slot.amount_slider_max) || fb.amount_slider_max
    const rate = Number(slot.annual_interest_rate) || fb.annual_interest_rate
    const termMonths = Number(slot.term_months) || fb.term_months

    this.amountRangeTarget.max = String(max)
    this.updateAmountMarks(max)

    this.rateInputTarget.value = String(rate)
    this.rateRangeTarget.value = String(rate)

    const tenure = this.tenureFromMonths(termMonths)
    this.tenureUnit = tenure.unit
    this.tenureUnitBtnTargets.forEach((b) => b.classList.toggle("is-active", b.dataset.unit === tenure.unit))
    this.tenureInputTarget.value = String(tenure.value)
    this.tenureRangeTarget.max = String(tenure.max)
    this.tenureRangeTarget.value = String(tenure.value)
  }

  updateAmountMarks(max) {
    if (!this.hasAmountMarksTarget) return
    const m = Number(max) || 0
    // Home loan: up to ~2Cr; Additional: up to ~50L by default.
    if (m <= 6_000_000) {
      this.amountMarksTarget.innerHTML = "<span>0</span><span>5L</span><span>10L</span><span>20L</span><span>30L</span><span>40L</span><span>50L</span>"
    } else {
      this.amountMarksTarget.innerHTML = "<span>0</span><span>25L</span><span>50L</span><span>75L</span><span>1Cr</span><span>1.5Cr</span><span>2Cr</span>"
    }
  }

  tenureFromMonths(termMonths) {
    if (!termMonths || termMonths <= 0) {
      return { unit: "yr", value: 15, max: 30 }
    }
    if (termMonths % 12 === 0) {
      return { unit: "yr", value: termMonths / 12, max: 30 }
    }
    return { unit: "mo", value: termMonths, max: 360 }
  }

  setTenureUnit(event) {
    const unit = event.currentTarget.dataset.unit
    if (unit === this.tenureUnit) return

    const current = toNumber(this.tenureInputTarget.value, 0)
    let next = current
    if (unit === "mo") next = Math.round(current * 12)
    if (unit === "yr") next = Math.max(1, Math.round(current / 12))

    this.tenureUnit = unit
    this.tenureUnitBtnTargets.forEach((b) => b.classList.toggle("is-active", b.dataset.unit === unit))
    this.tenureInputTarget.value = String(next)

    if (unit === "yr") {
      this.tenureRangeTarget.max = "30"
      this.tenureRangeTarget.value = String(Math.min(next, 30))
    } else {
      this.tenureRangeTarget.max = "360"
      this.tenureRangeTarget.value = String(Math.min(next, 360))
    }

    this.recalc()
  }

  currentSlot() {
    const cfg = this.mergedConfig()
    const key = this.activeLoanType === "additional" ? "additional" : "home"
    return cfg[key] || {}
  }

  currentKey() {
    return this.activeLoanType === "additional" ? "additional" : "home"
  }

  /**
   * Sanctioned loan amount used for EMI (original principal). The amount field may show current
   * outstanding after calendar EMIs on the 15th are treated as paid.
   */
  emiBasisPrincipal() {
    const key = this.currentKey()
    const slot = this.currentSlot()
    const fb = FALLBACK[key]
    let n = this.emiBasisBySlot[key]
    if (n == null || n <= 0) {
      n = Number(slot?.principal) || fb.principal
      this.emiBasisBySlot[key] = n
    }
    return n
  }

  appliedExtraTotal() {
    const key = this.currentKey()
    const list = this.appliedPrepayments[key]
    if (!Array.isArray(list)) return 0
    return list.reduce((sum, p) => sum + (Number(p.amount) || 0), 0)
  }

  computeSchedule({ loanAmount, annualRatePercent, totalMonths, totalPrepay }) {
    const outstanding = Math.max(0, loanAmount - totalPrepay)
    const monthlyEmi = emi(loanAmount, annualRatePercent, totalMonths)
    const scheduleMonths = outstanding <= 0.01 ? 0 : monthsFromFixedEmi(outstanding, annualRatePercent, monthlyEmi)
    const totalInterest = outstanding <= 0.01 ? 0 : Math.max(0, monthlyEmi * scheduleMonths - outstanding)
    return { outstanding, monthlyEmi, scheduleMonths, totalInterest }
  }

  clampPrepaymentToLoanAmount() {
    if (!this.hasPrepaymentInputTarget) return
    const slot = this.currentSlot()
    const recorded = Number(slot.recorded_prepayment_total || 0)
    const loanAmt = this.emiBasisPrincipal()
    let prep = Math.max(0, toNumber(this.prepaymentInputTarget.value, 0))
    const applied = this.appliedExtraTotal()
    const maxExtra = Math.max(0, loanAmt - recorded - applied)
    if (prep > maxExtra) this.prepaymentInputTarget.value = String(maxExtra)
  }

  renderAppliedPrepayments() {
    if (!this.hasAppliedPrepaymentsWrapTarget || !this.hasAppliedPrepaymentsListTarget) return
    const key = this.currentKey()
    const list = this.appliedPrepayments[key] || []
    this.appliedPrepaymentsWrapTarget.hidden = list.length === 0
    if (list.length === 0) {
      this.appliedPrepaymentsListTarget.innerHTML = ""
      return
    }
    this.appliedPrepaymentsListTarget.innerHTML = list
      .map((p, idx) => ({ p, idx }))
      .slice()
      .reverse()
      .map(({ p, idx }) => {
        const date = p.paidOn ? String(p.paidOn) : ""
        const note = p.notes ? String(p.notes) : ""
        const months = Number(p.monthsSaved || 0)
        const interest = Number(p.interestSaved || 0)
        return `<li class="lc-prepay-applied__item">
          <div class="lc-prepay-applied__main">
            <strong>${formatInr(p.amount)}</strong>
            <span class="lc-prepay-applied__meta">${date}</span>
          </div>
          <div class="lc-prepay-applied__metaRow">
            <span class="lc-prepay-applied__meta">saved ${formatInr(interest)}</span>
            <span class="lc-prepay-applied__meta">−${months} months</span>
          </div>
          ${note ? `<div class="lc-prepay-applied__note">${note}</div>` : ""}
          <button type="button" class="lc-btn lc-btn--ghost lc-btn--tiny lc-btn--prepay-remove" data-action="click->loan-calculator#removeAppliedPrepayment" data-index="${idx}">Remove</button>
        </li>`
      })
      .join("")
  }

  removeAppliedPrepayment(event) {
    event.preventDefault()
    event.stopPropagation()
    const idx = Number(event.currentTarget?.dataset?.index)
    if (!Number.isFinite(idx)) return
    const key = this.currentKey()
    const list = this.appliedPrepayments[key] || []
    if (idx < 0 || idx >= list.length) return
    list.splice(idx, 1)
    this.appliedPrepayments[key] = list
    this.persistAppliedPrepayments()
    this.renderAppliedPrepayments()
    this.previewPrepayment()
    this.yearlyChart?.destroy()
    this.yearlyChart = null
    this.recalc()
  }

  formatRemainingMonths(m) {
    if (!Number.isFinite(m) || m <= 0) return "—"
    if (this.tenureUnit === "yr") {
      const y = m / 12
      const s = y.toFixed(1)
      return `${s.endsWith(".0") ? String(Math.round(y)) : s} years`
    }
    return `${m} months`
  }

  syncFromAmountInput() {
    const n = toNumber(this.amountInputTarget.value, 0)
    this.emiBasisBySlot[this.currentKey()] = n
    this.amountRangeTarget.value = String(n)
    this.amountInputTarget.value = n.toLocaleString("en-IN")
    this.clampPrepaymentToLoanAmount()
    this.syncSaveLoanUi()
    this.previewPrepayment()
    this.recalc()
  }

  syncFromAmountRange() {
    const n = toNumber(this.amountRangeTarget.value, 0)
    this.emiBasisBySlot[this.currentKey()] = n
    this.amountInputTarget.value = n.toLocaleString("en-IN")
    this.clampPrepaymentToLoanAmount()
    this.syncSaveLoanUi()
    this.previewPrepayment()
    this.recalc()
  }

  syncFromRateInput() {
    const n = toNumber(this.rateInputTarget.value, 0)
    this.rateRangeTarget.value = String(n)
    this.rateInputTarget.value = String(n)
    this.previewPrepayment()
    this.recalc()
  }

  syncFromRateRange() {
    const n = toNumber(this.rateRangeTarget.value, 0)
    this.rateInputTarget.value = String(n)
    this.previewPrepayment()
    this.recalc()
  }

  syncFromTenureInput() {
    const n = Math.max(1, Math.floor(toNumber(this.tenureInputTarget.value, 1)))
    this.tenureInputTarget.value = String(n)
    this.tenureRangeTarget.value = String(n)
    this.previewPrepayment()
    this.recalc()
  }

  syncFromTenureRange() {
    const n = Math.max(1, Math.floor(toNumber(this.tenureRangeTarget.value, 1)))
    this.tenureInputTarget.value = String(n)
    this.previewPrepayment()
    this.recalc()
  }

  applyPrepayment(event) {
    event?.preventDefault?.()
    event?.stopPropagation?.()
    this.clampPrepaymentToLoanAmount()
    const appliedAmt = this.hasPrepaymentInputTarget ? Math.max(0, toNumber(this.prepaymentInputTarget.value, 0)) : 0
    if (appliedAmt <= 0.01) return
    const paidOn = this.hasPrepaymentDateInputTarget && this.prepaymentDateInputTarget.value ? this.prepaymentDateInputTarget.value : ""
    const notes = this.hasPrepaymentNoteInputTarget && this.prepaymentNoteInputTarget.value ? String(this.prepaymentNoteInputTarget.value).trim() : ""
    const key = this.currentKey()

    const slot = this.currentSlot()
    const recorded = Number(slot.recorded_prepayment_total || 0)
    let loanAmount = this.emiBasisPrincipal()
    let rate = toNumber(this.rateRangeTarget.value, 0)
    let tenure = toNumber(this.tenureRangeTarget.value, 0)
    if (rate <= 0) rate = toNumber(this.rateInputTarget.value, 0)
    if (tenure <= 0) tenure = toNumber(this.tenureInputTarget.value, 0)
    const months = this.tenureUnit === "yr" ? tenure * 12 : tenure

    const appliedBefore = this.appliedExtraTotal()
    const before = this.computeSchedule({
      loanAmount,
      annualRatePercent: rate,
      totalMonths: months,
      totalPrepay: recorded + appliedBefore,
    })
    const after = this.computeSchedule({
      loanAmount,
      annualRatePercent: rate,
      totalMonths: months,
      totalPrepay: recorded + appliedBefore + appliedAmt,
    })
    const monthsSaved = Math.max(0, before.scheduleMonths - after.scheduleMonths)
    const interestSaved = Math.max(0, before.totalInterest - after.totalInterest)

    if (!Array.isArray(this.appliedPrepayments[key])) this.appliedPrepayments[key] = []
    this.appliedPrepayments[key].push({ amount: appliedAmt, paidOn, notes, monthsSaved, interestSaved })
    this.persistAppliedPrepayments()
    this.prepaymentInputTarget.value = "0"
    if (this.hasPrepaymentNoteInputTarget) this.prepaymentNoteInputTarget.value = ""
    this.renderAppliedPrepayments()
    if (this.hasPrepayPreviewTarget) this.prepayPreviewTarget.hidden = true
    this.yearlyChart?.destroy()
    this.yearlyChart = null
    this.recalc()
  }

  previewPrepayment() {
    if (!this.hasPrepayPreviewTarget) return

    const slot = this.currentSlot()
    const recorded = Number(slot.recorded_prepayment_total || 0)
    const applied = this.appliedExtraTotal()

    this.clampPrepaymentToLoanAmount()

    let loanAmount = this.emiBasisPrincipal()
    let rate = toNumber(this.rateRangeTarget.value, 0)
    let tenure = toNumber(this.tenureRangeTarget.value, 0)
    if (rate <= 0) rate = toNumber(this.rateInputTarget.value, 0)
    if (tenure <= 0) tenure = toNumber(this.tenureInputTarget.value, 0)
    const months = this.tenureUnit === "yr" ? tenure * 12 : tenure

    const extra = this.hasPrepaymentInputTarget ? Math.max(0, toNumber(this.prepaymentInputTarget.value, 0)) : 0
    const totalPrepay = recorded + applied + extra
    const outstanding = Math.max(0, loanAmount - totalPrepay)

    if (extra <= 0.01 || loanAmount <= 0 || months <= 0) {
      this.prepayPreviewTarget.hidden = true
      return
    }

    const before = this.computeSchedule({
      loanAmount,
      annualRatePercent: rate,
      totalMonths: months,
      totalPrepay: recorded + applied,
    })
    const after = this.computeSchedule({
      loanAmount,
      annualRatePercent: rate,
      totalMonths: months,
      totalPrepay: recorded + applied + extra,
    })
    const interestSaved = Math.max(0, before.totalInterest - after.totalInterest)
    const monthsSaved = Math.max(0, before.scheduleMonths - after.scheduleMonths)

    const show = interestSaved > 0.01 || monthsSaved > 0
    this.prepayPreviewTarget.hidden = !show
    if (!show) return

    if (this.hasPrepayPreviewInterestTarget) this.prepayPreviewInterestTarget.textContent = formatInr(interestSaved)
    if (this.hasPrepayPreviewMonthsTarget) this.prepayPreviewMonthsTarget.textContent = `${monthsSaved} months`
  }

  scheduleParams() {
    let startYear = new Date().getFullYear()
    let startMonth = new Date().getMonth() + 1
    if (this.hasScheduleStartTarget && this.scheduleStartTarget.value) {
      const parts = this.scheduleStartTarget.value.split("-").map(Number)
      if (Number.isFinite(parts[0]) && Number.isFinite(parts[1])) {
        startYear = parts[0]
        startMonth = Math.min(12, Math.max(1, parts[1]))
      }
    }
    const basis = this.hasScheduleBasisTarget && this.scheduleBasisTarget.value === "financial" ? "financial" : "calendar"
    return { startYear, startMonth, basis }
  }

  recalc() {
    const slot = this.currentSlot()
    const recorded = Number(slot.recorded_prepayment_total || 0)
    const applied = this.appliedExtraTotal()

    let loanAmount = this.emiBasisPrincipal()
    let rate = toNumber(this.rateRangeTarget.value, 0)
    let tenure = toNumber(this.tenureRangeTarget.value, 0)
    if (rate <= 0) rate = toNumber(this.rateInputTarget.value, 0)
    if (tenure <= 0) tenure = toNumber(this.tenureInputTarget.value, 0)
    const months = this.tenureUnit === "yr" ? tenure * 12 : tenure

    // Session prepayments (Add prepayment) + DB prepayments both reduce principal; do not gate on prepaymentInput target.
    const totalPrepay = recorded + applied
    const effectivePrincipal = Math.max(0, loanAmount - totalPrepay)

    const originalEmi = emi(loanAmount, rate, months)

    let scheduleMonths = 0
    if (effectivePrincipal <= 0) {
      scheduleMonths = 0
    } else if (loanAmount - effectivePrincipal < 0.01) {
      scheduleMonths = months
    } else {
      scheduleMonths = monthsFromFixedEmi(effectivePrincipal, rate, originalEmi)
    }

    const { startYear, startMonth } = this.scheduleParams()
    const ap = scheduleAfterAutopay(
      effectivePrincipal,
      rate,
      scheduleMonths,
      originalEmi,
      startYear,
      startMonth,
    )

    this.emiOutTarget.textContent = formatInr(originalEmi)
    this.interestOutTarget.textContent = formatInr(round2(ap.totalIntRem))
    this.totalOutTarget.textContent = formatInr(round2(ap.totalPayRem))

    if (this.hasEffectivePrincipalOutTarget) {
      this.effectivePrincipalOutTarget.textContent = formatInr(ap.outstanding)
    }
    if (this.hasEffectivePrincipalNoteTarget) {
      this.effectivePrincipalNoteTarget.hidden = totalPrepay <= 0
    }
    if (this.hasRemainingTenureOutTarget) {
      this.remainingTenureOutTarget.textContent = this.formatRemainingMonths(ap.remainingMonths)
    }

    // Keep the main amount control aligned with "Principal left" once an EMI due date has passed (e.g. after the 15th).
    if (this.hasAmountInputTarget && this.hasAmountRangeTarget) {
      const editing = document.activeElement === this.amountInputTarget
      if (!editing) {
        const displayAmt = Math.max(0, Math.round(ap.outstanding))
        this.amountInputTarget.value = displayAmt.toLocaleString("en-IN")
        this.amountRangeTarget.value = String(displayAmt)
      }
    }

    this.syncSaveLoanUi()

    this.updateDonut(ap.outstanding, ap.totalPayRem)
    this.renderYearly({
      principal: effectivePrincipal,
      rate,
      months: scheduleMonths,
      fixedPayment: originalEmi,
      schedulePrecalc: ap,
    })
  }

  updateDonut(principal, totalPayment) {
    if (!this.hasDonutRingTarget) return
    const pPct =
      totalPayment > 0 ? Math.min(100, Math.max(0, Math.round((principal / totalPayment) * 100))) : 0
    const iPct = Math.min(100, Math.max(0, 100 - pPct))
    this.donutRingTarget.style.setProperty("--p-split", `${pPct}%`)
    if (this.hasDonutPriPctTarget) this.donutPriPctTarget.textContent = `${pPct}%`
    if (this.hasDonutIntPctTarget) this.donutIntPctTarget.textContent = `${iPct}%`
  }

  toggleYear(event) {
    const btn = event.target.closest("button.lc-expand")
    if (!btn) return
    event.preventDefault()
    const row = btn.closest("tr.lc-tr-year")
    if (!row) return
    const key = row.dataset.periodKey
    if (!key) return

    const expanded = !row.classList.contains("is-expanded")
    row.classList.toggle("is-expanded", expanded)

    btn.setAttribute("aria-expanded", expanded ? "true" : "false")
    btn.textContent = expanded ? "−" : "+"

    this.yearlyBodyTarget.querySelectorAll("tr.lc-tr-month").forEach((tr) => {
      if (tr.dataset.periodKey !== key) return
      // Some browsers/CSS combinations may keep rows hidden; set both class and style explicitly.
      tr.classList.toggle("lc-tr-month--hidden", !expanded)
      tr.style.display = expanded ? "table-row" : "none"
    })
  }

  renderYearly({ principal, rate, months, fixedPayment, schedulePrecalc }) {
    const { startYear, startMonth, basis } = this.scheduleParams()
    const ap =
      schedulePrecalc ??
      scheduleAfterAutopay(principal, rate, months, fixedPayment, startYear, startMonth)
    const monthRows = ap.full.slice(ap.skip)
    const groups = groupIntoPeriods(monthRows, basis)

    const tableHtml = []
    groups.forEach((g) => {
      tableHtml.push(`<tr class="lc-tr-year" data-period-key="${g.periodKey}">
          <td class="lc-td-year">
            <button type="button" class="lc-expand" aria-expanded="false" aria-label="Show or hide monthly breakdown">+</button>
            <span class="lc-year-text">${g.label}</span>
          </td>
          <td class="num">${formatInr(g.principalPaid)}</td>
          <td class="num">${formatInr(g.interestPaid)}</td>
          <td class="num">${formatInr(g.totalPaid)}</td>
          <td class="num">${formatInr(g.endBalance)}</td>
          <td class="num">${g.paidToDate.toFixed(2)}%</td>
        </tr>`)

      g.months.forEach((mrow, mi) => {
        const stripe = mi % 2 === 0 ? "lc-tr-month--a" : "lc-tr-month--b"
        tableHtml.push(`<tr class="lc-tr-month lc-tr-month--hidden ${stripe}" data-period-key="${g.periodKey}">
          <td class="lc-td-month">${monthCellLabel(mrow)}</td>
          <td class="num">${formatInr(mrow.principalPaid)}</td>
          <td class="num">${formatInr(mrow.interestPaid)}</td>
          <td class="num">${formatInr(mrow.totalPaid)}</td>
          <td class="num">${formatInr(mrow.balance)}</td>
          <td class="num">${mrow.paidToDate.toFixed(2)}%</td>
        </tr>`)
      })
    })
    this.yearlyBodyTarget.innerHTML = tableHtml.join("")

    const labels = groups.map((g) => g.label)
    const principalSeries = groups.map((g) => g.principalPaid)
    const interestSeries = groups.map((g) => g.interestPaid)
    const balanceSeries = groups.map((g) => g.endBalance)

    const chartData = {
      labels,
      datasets: [
        {
          type: "bar",
          label: "Principal",
          data: principalSeries,
          yAxisID: "yPayment",
          backgroundColor: SCH.principal,
          borderColor: "rgba(90, 130, 0, 0.45)",
          borderWidth: 1,
          borderRadius: { topLeft: 0, topRight: 0, bottomLeft: 3, bottomRight: 3 },
          borderSkipped: false,
          stack: "pay",
          order: 1,
          maxBarThickness: 46,
        },
        {
          type: "bar",
          label: "Interest",
          data: interestSeries,
          yAxisID: "yPayment",
          backgroundColor: SCH.interest,
          borderColor: "rgba(200, 110, 0, 0.4)",
          borderWidth: 1,
          borderRadius: { topLeft: 3, topRight: 3, bottomLeft: 0, bottomRight: 0 },
          borderSkipped: false,
          stack: "pay",
          order: 1,
          maxBarThickness: 46,
        },
        {
          type: "line",
          label: "Balance",
          data: balanceSeries,
          yAxisID: "yBalance",
          borderColor: SCH.balance,
          backgroundColor: SCH.balanceFill,
          fill: true,
          pointRadius: 5,
          pointHoverRadius: 7,
          pointBackgroundColor: SCH.balance,
          pointBorderColor: "#ffffff",
          pointBorderWidth: 2,
          borderWidth: 2.5,
          tension: 0.35,
          order: 2,
        },
      ],
    }

    const chartOptions = {
      responsive: true,
      maintainAspectRatio: false,
      animation: { duration: 450 },
      datasets: {
        bar: {
          barPercentage: 0.78,
          categoryPercentage: 0.88,
        },
      },
      layout: {
        padding: { left: 4, right: 10, top: 8, bottom: 6 },
      },
      interaction: { mode: "index", intersect: false },
      scales: {
        x: {
          stacked: true,
          grid: { display: false },
          ticks: {
            maxRotation: 45,
            minRotation: 45,
            autoSkip: true,
            maxTicksLimit: 22,
            font: { size: 11 },
            color: "#4b5563",
          },
          border: { display: false },
        },
        yBalance: {
          position: "left",
          min: 0,
          title: {
            display: true,
            text: "Balance",
            color: "#374151",
            font: { size: 11, weight: "600" },
            padding: { bottom: 6 },
          },
          grid: {
            color: "rgba(0, 0, 0, 0.08)",
            drawBorder: false,
          },
          border: { display: false },
          ticks: {
            callback: (v) => formatAxisCommaRupee(v),
            font: { size: 10 },
            maxTicksLimit: 8,
            color: "#6b7280",
            padding: 6,
          },
        },
        yPayment: {
          position: "right",
          stacked: true,
          min: 0,
          title: {
            display: true,
            text: "EMI Payment / year",
            color: "#374151",
            font: { size: 11, weight: "600" },
            padding: { bottom: 6 },
          },
          grid: { drawOnChartArea: false },
          border: { display: false },
          ticks: {
            callback: (v) => formatAxisCommaRupee(v),
            font: { size: 10 },
            maxTicksLimit: 8,
            color: "#6b7280",
            padding: 6,
          },
        },
      },
      plugins: {
        legend: {
          position: "bottom",
          align: "center",
          labels: {
            usePointStyle: true,
            padding: 18,
            font: { size: 11, family: "system-ui, -apple-system, sans-serif" },
            color: "#374151",
            generateLabels: (chart) => {
              const sets = chart.data.datasets
              if (!sets?.length) return []
              return sets.map((dataset, i) => {
                const isLine = dataset.type === "line"
                return {
                  text: dataset.label || "",
                  fillStyle: isLine ? dataset.borderColor : dataset.backgroundColor,
                  strokeStyle: dataset.borderColor || dataset.backgroundColor,
                  lineWidth: isLine ? 2 : 0,
                  hidden: !chart.isDatasetVisible(i),
                  datasetIndex: i,
                  index: i,
                  pointStyle: isLine ? "rectRot" : "circle",
                }
              })
            },
          },
        },
        tooltip: {
          backgroundColor: "rgba(17, 24, 39, 0.92)",
          titleFont: { size: 12, weight: "700" },
          bodyFont: { size: 12 },
          padding: 12,
          cornerRadius: 8,
          callbacks: {
            title: (items) => (items[0]?.label ? String(items[0].label) : ""),
            label(ctx) {
              const v = ctx.parsed.y
              if (v == null) return `${ctx.dataset.label}`
              return ` ${ctx.dataset.label}: ${formatInr(v)}`
            },
          },
        },
      },
    }

    // Chart.js sometimes doesn't fully refresh mixed-type charts on deep changes (labels/length).
    // Recreate the chart each time so prepayment changes always reflect immediately.
    this.yearlyChart?.destroy()
    this.yearlyChart = null

    // Hard-reset the canvas to avoid stale drawing contexts.
    // (Some browsers keep a "sticky" internal state even after destroy.)
    let canvas = this.yearlyCanvasTarget
    try {
      const next = canvas.cloneNode(true)
      canvas.replaceWith(next)
      canvas = next
    } catch (_) {
      // ignore and reuse existing canvas
    }
    try {
      this.yearlyChart = new Chart(canvas, {
        type: "bar",
        data: chartData,
        options: chartOptions,
      })
      if (this.hasYearlySsrFallbackTarget) {
        this.yearlySsrFallbackTarget.hidden = true
      }
      if (this.hasYearlyCanvasWrapTarget) {
        this.yearlyCanvasWrapTarget.classList.add("is-visible")
      }
      requestAnimationFrame(() => this.yearlyChart?.resize())
    } catch (_) {
      /* keep SSR bars visible */
    }
  }
}
