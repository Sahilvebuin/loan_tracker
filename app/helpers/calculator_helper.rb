module CalculatorHelper
  EMI_PAY_DAY = 15

  # Calendar month of the first EMI (15th): first 15th on or after +start_date+ (disbursal after mid-month → next month).
  def emi_schedule_anchor_year_month(start_date)
    d = start_date.to_date
    y = d.year
    m = d.month
    fifteenth = Date.new(y, m, EMI_PAY_DAY)
    if d > fifteenth
      n = d.beginning_of_month + 1.month
      [ n.year, n.month ]
    else
      [ y, m ]
    end
  end

  # Same EMI formula as app/javascript/controllers/loan_calculator_controller.js
  def loan_emi(principal, annual_rate_percent, months)
    p = principal.to_f
    n = months.to_i
    return 0.0 if n <= 0 || p <= 0

    r = annual_rate_percent.to_f / 12.0 / 100.0
    return p / n if r.zero?

    x = (1 + r)**n
    (p * r * x) / (x - 1)
  end

  # Months to close the loan if you keep paying +monthly_payment+ (original EMI) on +principal+ (outstanding).
  def loan_months_from_fixed_emi(principal, annual_rate_percent, monthly_payment)
    p = principal.to_f
    return 0 if p <= 0.01

    e = monthly_payment.to_f
    return 0 if e <= 0

    r = annual_rate_percent.to_f / 12.0 / 100.0
    return (p / e).ceil if r.zero?

    return 0 if e <= (p * r)

    k = e / (e - (p * r))
    return 0 if k <= 1

    (Math.log(k) / Math.log(1 + r)).ceil.clamp(1, 1_000_000)
  end

  def loan_home_metrics(cfg)
    loan_slot_metrics(cfg, :home)
  end

  # First EMI due date (on EMI_PAY_DAY) on or after +date+.
  def first_emi_due_on_or_after(date)
    sy, sm = emi_schedule_anchor_year_month(date)
    Date.new(sy, sm, EMI_PAY_DAY)
  end

  # Loan terms as consecutive segments, one per interest-rate period:
  #   { first_due:, opening:, rate:, emi:, months:, rows_count: }
  # Segment 0 = sanctioned principal / original rate / original tenure (EMI on sanctioned amount).
  # Each later rate row starts a segment at the first EMI due on/after its effective_from:
  #   - opening  = row.opening_principal (bank statement) or the balance carried from the previous segment
  #   - emi      = row.emi_amount (bank-revised EMI) or the previous EMI (tenure absorbs the change)
  #   - months   = row.remaining_months or months needed at that EMI
  # Recorded prepayments reduce the opening of the segment they fall in (segments with a bank-stated
  # opening already include everything before them); pass apply_prepayments: false to ignore them.
  # rows_count is nil for the last (open) segment.
  def loan_term_segments(loan, apply_prepayments: true)
    rates = loan.persisted? ? loan.loan_interest_rates.sort_by { |r| [ r.effective_from, r.id ] } : []
    first_rate = rates.first
    anchor = loan.emi_start_date.presence || loan.start_date
    first_due = first_emi_due_on_or_after(anchor)
    base_rate = (first_rate&.interest_rate || loan.annual_interest_rate).to_f
    term = loan.term_months.to_i

    prepays = loan.persisted? && apply_prepayments ? loan.prepayments.map { |pp| [ pp.paid_on.to_date, pp.amount.to_f ] } : []
    explicit_starts = rates.drop(1).select(&:opening_principal).map { |r| first_emi_due_on_or_after(r.effective_from) }
    prepaid_between = lambda do |from, to|
      prepays.sum { |on, amt| (from.nil? || on >= from) && (to.nil? || on < to) ? amt : 0.0 }
    end

    segments = [ {
      first_due: first_due,
      opening: [ loan.principal.to_f - prepaid_between.call(nil, explicit_starts.first), 0.0 ].max,
      rate: base_rate,
      emi: (first_rate&.emi_amount || loan_emi(loan.principal, base_rate, term)).to_f,
      months: term,
      rows_count: nil
    } ]

    rates.drop(1).each do |r|
      prev = segments.last
      seg_due = first_emi_due_on_or_after(r.effective_from)
      elapsed = (seg_due.year * 12 + seg_due.month) - (prev[:first_due].year * 12 + prev[:first_due].month)
      prev_rows = monthly_amortization_rows(
        prev[:opening], prev[:rate], prev[:months],
        start_year: prev[:first_due].year, start_month: prev[:first_due].month, fixed_payment: prev[:emi]
      )

      carried =
        if elapsed <= 0 then prev[:opening]
        elsif elapsed > prev_rows.length then 0.0
        else prev_rows[elapsed - 1][:balance].to_f
        end

      opening =
        if r.opening_principal
          next_explicit = explicit_starts.find { |d| d > seg_due }
          [ r.opening_principal.to_f - prepaid_between.call(r.effective_from, next_explicit), 0.0 ].max
        else
          carried
        end
      rate = r.interest_rate.to_f
      emi = (r.emi_amount || prev[:emi]).to_f
      months = (r.remaining_months || loan_months_from_fixed_emi(opening, rate, emi)).to_i

      if elapsed <= 0
        segments.pop # revision before the first EMI replaces the earlier terms entirely
      else
        prev[:rows_count] = [ elapsed, prev_rows.length ].min
      end
      segments << { first_due: seg_due, opening: opening, rate: rate, emi: emi, months: months, rows_count: nil }
    end

    segments
  end

  # Full EMI schedule across all term segments (same row shape as monthly_amortization_rows,
  # plus :rate and :opening — principal outstanding just before that EMI).
  def loan_schedule_rows(loan, apply_prepayments: true, segments: loan_term_segments(loan, apply_prepayments: apply_prepayments))
    segments.flat_map do |seg|
      next [] if seg[:opening] <= 0.01

      rows = monthly_amortization_rows(
        seg[:opening], seg[:rate], seg[:months],
        start_year: seg[:first_due].year, start_month: seg[:first_due].month, fixed_payment: seg[:emi]
      )
      rows = rows.first(seg[:rows_count]) if seg[:rows_count]
      opening = seg[:opening].round(2)
      rows.map do |row|
        out = row.merge(rate: seg[:rate], opening: opening)
        opening = row[:balance].to_f
        out
      end
    end
  end

  # Terms currently in force (last segment) — EMI basis for the calculator UI.
  def loan_current_terms(loan)
    loan_term_segments(loan).last
  end

  # Outstanding after EMI debits on the 15th (see EmiDeduction). Walks the segmented schedule
  # (original terms, then any bank revisions) over recorded EMI debits.
  def loan_payment_state(loan, as_of: Date.current)
    anchor = loan.emi_start_date.presence || loan.start_date
    anchor_sy, anchor_sm = emi_schedule_anchor_year_month(anchor)
    full_rows = loan_schedule_rows(loan)
    return empty_payment_state if full_rows.empty?

    recorded_dues = loan.emi_deductions.pluck(:due_on).map(&:to_date).to_set

    balance = full_rows.first[:opening].to_f
    emis_paid = 0
    tail_sy = anchor_sy
    tail_sm = anchor_sm

    full_rows.each do |row|
      due_on = Date.new(row[:calendar_year], row[:month], EMI_PAY_DAY)
      break unless recorded_dues.include?(due_on)

      balance = row[:balance].to_f
      emis_paid += 1
      tail_sy, tail_sm = month_after_schedule_row(row)
    end

    m_rem = [ full_rows.length - emis_paid, 0 ].max
    # Next EMI may open a bank-revised segment whose stated opening differs from the carried balance.
    balance = full_rows[emis_paid][:opening].to_f if emis_paid.positive? && full_rows[emis_paid]

    {
      current_balance: balance,
      remaining_months: m_rem,
      schedule_months: m_rem,
      emis_paid_count: emis_paid,
      tail_start_year: tail_sy,
      tail_start_month: tail_sm,
      anchor_start_year: anchor_sy,
      anchor_start_month: anchor_sm
    }
  end

  def empty_payment_state
    {
      current_balance: 0.0,
      remaining_months: 0,
      schedule_months: 0,
      emis_paid_count: 0,
      tail_start_year: nil,
      tail_start_month: nil,
      anchor_start_year: nil,
      anchor_start_month: nil
    }
  end

  def month_after_schedule_row(row)
    y = row[:calendar_year].to_i
    m = row[:month].to_i + 1
    if m > 12
      m = 1
      y += 1
    end
    [ y, m ]
  end

  # KPIs for one loan tab (home / additional).
  def loan_slot_metrics(cfg, slot_key, as_of: Date.current)
    slot = (cfg[slot_key] || cfg[slot_key.to_s] || {}).with_indifferent_access
    return metrics_from_loan_slot(slot) if slot[:balance_from_loan]

    loan_slot_metrics_with_autopay(slot, as_of: as_of)
  end

  def metrics_from_loan_slot(slot)
    slot = slot.with_indifferent_access
    rate = slot[:annual_interest_rate].to_f
    monthly = slot_fixed_emi(slot)
    balance = slot[:outstanding_principal].to_f

    if balance <= 0.01
      return {
        emi: monthly,
        total_interest: 0.0,
        total_payment: 0.0,
        remaining_months: 0,
        schedule_months: 0,
        outstanding_principal: 0.0,
        tail_start_year: slot[:tail_start_year],
        tail_start_month: slot[:tail_start_month]
      }
    end

    m_rem = (slot[:remaining_months].presence || loan_months_from_fixed_emi(balance, rate, monthly)).to_i
    ty, tm = slot[:tail_start_year].to_i, slot[:tail_start_month].to_i
    if ty <= 0 || tm < 1 || tm > 12
      ty, tm = schedule_anchor_from_slot(slot)
    end

    tail = monthly_amortization_rows(balance, rate, m_rem, start_year: ty, start_month: tm, fixed_payment: monthly)
    {
      emi: monthly,
      outstanding_principal: balance,
      remaining_months: m_rem,
      schedule_months: m_rem,
      total_interest: tail.sum { |r| r[:interest_paid].to_f },
      total_payment: tail.sum { |r| r[:total_paid].to_f },
      tail_start_year: ty,
      tail_start_month: tm
    }
  end

  def loan_slot_metrics_with_autopay(slot, as_of: Date.current)
    slot = slot.with_indifferent_access
    p_orig = slot[:principal].to_f
    rate = slot[:annual_interest_rate].to_f
    m = slot[:term_months].to_i
    outstanding = slot[:outstanding_principal].present? ? slot[:outstanding_principal].to_f : p_orig
    outstanding = [ outstanding, 0.0 ].max

    monthly = slot_fixed_emi(slot)
    prepay_total = [ p_orig - outstanding, 0.0 ].max

    sy, sm = schedule_anchor_from_slot(slot)

    if outstanding <= 0.01
      return {
        emi: monthly,
        total_interest: 0.0,
        total_payment: 0.0,
        remaining_months: 0,
        schedule_months: 0,
        outstanding_principal: 0.0
      }
    end

    m_rem =
      if prepay_total <= 0.01
        m
      else
        loan_months_from_fixed_emi(outstanding, rate, monthly)
      end

    met_base = {
      emi: monthly,
      total_interest: (monthly * m_rem) - outstanding,
      total_payment: monthly * m_rem,
      remaining_months: m_rem,
      schedule_months: m_rem,
      outstanding_principal: outstanding
    }

    met_base.merge(
      loan_kpis_after_autopay(
        outstanding,
        rate,
        m_rem,
        monthly,
        start_year: sy,
        start_month: sm,
        as_of: as_of
      )
    )
  end

  def yearly_tail_amortization_rows(balance, annual_rate_percent, months, start_year:, start_month:, basis: :calendar, fixed_payment: nil)
    monthly = monthly_amortization_rows(
      balance,
      annual_rate_percent,
      months,
      start_year: start_year,
      start_month: start_month,
      fixed_payment: fixed_payment
    )
    group_yearly_from_monthly(monthly, basis: basis)
  end

  # One row per payment month, walking calendar from start_year/start_month (1–12).
  # Pass +fixed_payment:+ to use the original EMI while +months:+ is the remaining count (after prepayment).
  def monthly_amortization_rows(principal, annual_rate_percent, months, start_year:, start_month:, fixed_payment: nil)
    payment =
      if fixed_payment
        fixed_payment.to_f
      else
        loan_emi(principal, annual_rate_percent, months)
      end
    r = annual_rate_percent.to_f / 12.0 / 100.0
    balance = principal.to_f
    rows = []
    y = start_year.to_i
    m = start_month.to_i.clamp(1, 12)
    principal_total = principal.to_f

    months.to_i.times do
      break if balance <= 0.01

      interest = balance * r
      principal_part = payment - interest
      principal_part = balance if principal_part > balance
      balance -= principal_part
      paid_to_date = principal_total.positive? ? ((principal_total - balance) / principal_total) * 100 : 0.0

      rows << {
        calendar_year: y,
        month: m,
        day: EMI_PAY_DAY,
        principal_paid: principal_part.round(2),
        interest_paid: interest.round(2),
        total_paid: (principal_part + interest).round(2),
        balance: [ balance, 0 ].max.round(2),
        paid_to_date: paid_to_date.round(2)
      }

      m += 1
      if m > 12
        m = 1
        y += 1
      end
    end
    rows
  end

  # EMIs on EMI_PAY_DAY already passed before +as_of+ (not on due date — debit runs at 00:01 on the 15th).
  def autopay_emis_already_passed_count(start_year, start_month, max_months, as_of: Date.current)
    y = start_year.to_i
    m = start_month.to_i.clamp(1, 12)
    paid = 0
    while paid < max_months.to_i
      due = Date.new(y, m, EMI_PAY_DAY)
      break if as_of <= due

      paid += 1
      m += 1
      if m > 12
        m = 1
        y += 1
      end
    end
    paid
  end

  # KPIs aligned with the yearly table: outstanding, tenure, interest & total for EMIs still to come after autopay (15th passed).
  def loan_kpis_after_autopay(outstanding, annual_rate_percent, remaining_months, fixed_emi, start_year:, start_month:, as_of: Date.current)
    o = outstanding.to_f
    m_rem = remaining_months.to_i
    return { outstanding_principal: 0.0, remaining_months: 0, total_interest: 0.0, total_payment: 0.0 } if m_rem <= 0 || o <= 0.01

    rows = monthly_amortization_rows(o, annual_rate_percent, m_rem, start_year: start_year, start_month: start_month, fixed_payment: fixed_emi)
    skip = autopay_emis_already_passed_count(start_year, start_month, m_rem, as_of: as_of)
    skip = [ skip, rows.length ].min
    outstanding2 =
      if skip.zero?
        o
      elsif skip >= rows.length
        0.0
      else
        rows[skip - 1][:balance].to_f
      end
    tail = rows[skip..] || []
    {
      outstanding_principal: outstanding2,
      remaining_months: tail.length,
      total_interest: tail.sum { |r| r[:interest_paid].to_f },
      total_payment: tail.sum { |r| r[:total_paid].to_f }
    }
  end

  # basis: :calendar (Jan–Dec) or :financial (Indian Apr–Mar).
  def yearly_amortization_rows(principal, annual_rate_percent, months, start_year: Date.current.year, start_month: Date.current.month, basis: :calendar, fixed_payment: nil, as_of: Date.current)
    monthly = monthly_amortization_rows(principal, annual_rate_percent, months, start_year: start_year, start_month: start_month, fixed_payment: fixed_payment)
    skip = autopay_emis_already_passed_count(start_year, start_month, months, as_of: as_of)
    monthly = monthly.drop(skip)
    group_yearly_from_monthly(monthly, basis: basis)
  end

  def group_yearly_from_monthly(monthly, basis: :calendar)
    sym = basis.to_sym
    grouped = monthly.group_by do |r|
      sym == :financial ? financial_year_start(r[:calendar_year], r[:month]) : r[:calendar_year]
    end

    grouped.map do |key, mrows|
      year_label =
        if sym == :financial
          financial_year_label(key)
        else
          key.to_s
        end

      principal_paid = mrows.sum { |x| x[:principal_paid] }.round(2)
      interest_paid = mrows.sum { |x| x[:interest_paid] }.round(2)
      total_paid = mrows.sum { |x| x[:total_paid] }.round(2)

      {
        year: key,
        year_label: year_label,
        period_key: (sym == :financial ? "fy:#{key}" : "cy:#{key}"),
        principal_paid: principal_paid,
        interest_paid: interest_paid,
        total_paid: total_paid,
        balance: mrows.last[:balance],
        paid_to_date: mrows.last[:paid_to_date],
        months: mrows
      }
    end.sort_by { |row| row[:year] }
  end

  def financial_year_start(calendar_year, month)
    m = month.to_i
    # Indian FY: April (4) – March (3 next year)
    m >= 4 ? calendar_year.to_i : calendar_year.to_i - 1
  end

  def financial_year_label(fy_start)
    y = fy_start.to_i
    "FY #{y}\u2013#{format('%02d', (y + 1) % 100)}"
  end

  # Label for a monthly schedule row (matches JS monthCellLabel).
  def schedule_month_cell_label(mrow)
    m = mrow[:month].to_i
    abbr = Date::ABBR_MONTHNAMES[m]
    d = (mrow[:day].presence || EMI_PAY_DAY).to_i
    "#{format('%02d', d)} #{abbr} #{mrow[:calendar_year]}"
  end

  def format_inr(amount)
    number_to_currency(amount.to_f, unit: "₹ ", precision: 0, format: "%u%n")
  end

  # Percent of total payment (principal vs interest) for the donut visual
  def payment_breakup_percentages(principal_amount, total_interest)
    p = principal_amount.to_f
    i = total_interest.to_f
    t = p + i
    return [ 0.0, 0.0 ] if t <= 0

    [ (p / t * 100).round(1), (i / t * 100).round(1) ]
  end

  # Hash for ERB: tenure UI for a loan tab (months vs years + slider max).
  def home_loan_ui(cfg, slot_key: :home)
    home = (cfg[slot_key] || cfg[slot_key.to_s] || {}).with_indifferent_access
    tm =
      if home[:balance_from_loan] && home[:remaining_months].present?
        home[:remaining_months].to_i
      else
        home[:term_months].to_i
      end
    if tm <= 0
      return { use_months: true, tenure_value: 159, tenure_max: 360, amount_max: 20_000_000,
               principal: 2_572_312.50, rate: 7.95 }
    end
    if (tm % 12).zero?
      { use_months: false, tenure_value: [ tm / 12, 30 ].min, tenure_max: 30, amount_max: (home[:amount_slider_max].presence || 20_000_000).to_i,
        principal: home[:principal].to_f, rate: home[:annual_interest_rate].to_f }
    else
      { use_months: true, tenure_value: tm, tenure_max: 360, amount_max: (home[:amount_slider_max].presence || 20_000_000).to_i,
        principal: home[:principal].to_f, rate: home[:annual_interest_rate].to_f }
    end
  end

  # EMI currently debited for a calculator slot: bank-revised EMI when known, else the formula
  # on the current EMI basis (revision opening / remaining tenure, or sanctioned amount / term).
  def slot_fixed_emi(slot)
    slot = slot.with_indifferent_access
    return slot[:emi_amount].to_f if slot[:emi_amount].to_f.positive?

    loan_emi(
      (slot[:emi_basis_principal].presence || slot[:principal]).to_f,
      slot[:annual_interest_rate].to_f,
      (slot[:emi_basis_term_months].presence || slot[:term_months]).to_i
    )
  end

  # JSON for Stimulus: each key matches loan-calculator tab types (home / additional).
  def loan_calculator_config_for(user)
    home_loan = user&.loans&.find_by(title: "Home Loan")
    add_loan = user&.loans&.find_by(title: "Additional Home Loan")
    preset_home = LoanCalculatorPreset.find_by(key: "home")
    preset_add = LoanCalculatorPreset.find_by(key: "additional")

    {
      home: slot_config(home_loan, preset_home, home_fallback),
      additional: slot_config(add_loan, preset_add, additional_fallback)
    }
  end

  private

  def slot_config(loan, preset, hardcoded)
    principal =
      if loan
        loan.principal.to_d
      else
        (preset&.principal || hardcoded[:principal]).to_d
      end

    return slot_config_without_loan(preset, hardcoded, principal.to_f) unless loan

    state = loan_payment_state(loan)
    outstanding = loan.outstanding_principal.to_f
    remaining =
      if loan.loan_emi_schedules.exists?
        loan.loan_emi_schedules.where(status: %w[pending overdue]).count
      else
        state[:remaining_months]
      end
    remaining = state[:remaining_months] if remaining.to_i <= 0 && outstanding > 0.01

    rate = loan.annual_interest_rate.to_d
    term_months = loan.term_months.to_i
    current_terms = loan_current_terms(loan)
    amount_slider_max = (preset&.amount_slider_max || hardcoded[:amount_slider_max]).to_i
    start_date = loan.start_date.to_date
    schedule_sy, schedule_sm = emi_schedule_anchor_year_month(start_date)
    tail_sy = state[:tail_start_year]
    tail_sm = state[:tail_start_month]
    next_due = loan.loan_emi_schedules.where(status: %w[pending overdue]).order(:due_on).first
    if next_due
      tail_sy = next_due.due_on.year
      tail_sm = next_due.due_on.month
    end

    {
      principal: principal.to_f,
      outstanding_principal: outstanding,
      recorded_prepayment_total: loan.total_prepayments.to_f,
      annual_interest_rate: rate.to_f,
      term_months: term_months,
      emi_amount: current_terms[:emi].round(2),
      emi_basis_principal: current_terms[:opening].round(2),
      emi_basis_term_months: current_terms[:months],
      amount_slider_max: amount_slider_max,
      start_date: start_date.iso8601,
      schedule_start_year: schedule_sy,
      schedule_start_month: schedule_sm,
      balance_from_loan: true,
      remaining_months: remaining,
      emis_paid_count: state[:emis_paid_count],
      tail_start_year: tail_sy,
      tail_start_month: tail_sm
    }
  end

  def slot_config_without_loan(preset, hardcoded, principal)
    rate = (preset&.annual_interest_rate || hardcoded[:rate]).to_d
    term_months = (preset&.term_months || hardcoded[:term_months]).to_i
    amount_slider_max = (preset&.amount_slider_max || hardcoded[:amount_slider_max]).to_i
    start_date = default_loan_start_date
    schedule_sy, schedule_sm = emi_schedule_anchor_year_month(start_date)
    outstanding = (hardcoded[:outstanding] || principal).to_f
    basis_principal = (hardcoded[:emi_basis_principal] || principal).to_f
    basis_term = (hardcoded[:emi_basis_term_months] || term_months).to_i
    monthly = (hardcoded[:emi_amount] || loan_emi(basis_principal, rate, basis_term)).to_f
    m_rem = (hardcoded[:remaining_months] || loan_months_from_fixed_emi(outstanding, rate, monthly)).to_i

    {
      principal: principal.to_f,
      outstanding_principal: outstanding,
      recorded_prepayment_total: (principal - outstanding).to_f.clamp(0, Float::INFINITY),
      annual_interest_rate: rate.to_f,
      term_months: term_months,
      emi_amount: monthly.round(2),
      emi_basis_principal: basis_principal,
      emi_basis_term_months: basis_term,
      amount_slider_max: amount_slider_max,
      start_date: start_date.iso8601,
      schedule_start_year: schedule_sy,
      schedule_start_month: schedule_sm,
      balance_from_loan: true,
      remaining_months: m_rem,
      emis_paid_count: 0,
      tail_start_year: hardcoded[:tail_start_year] || schedule_sy,
      tail_start_month: hardcoded[:tail_start_month] || schedule_sm
    }
  end

  def schedule_anchor_from_slot(slot)
    sy = slot[:schedule_start_year].to_i
    sm = slot[:schedule_start_month].to_i
    return [ sy, sm ] if sy.positive? && sm.between?(1, 12)

    anchor = slot[:start_date].presence || default_loan_start_date
    emi_schedule_anchor_year_month(anchor)
  end

  def default_loan_start_date
    Date.new(2026, 3, 16)
  end

  # Per brother (half of the bank's combined figures). Revised Nov 2026 after repo +0.25%:
  # combined ₹51,44,625 @ 7.95% · EMI ₹52,620 · 159 months from 15 Nov 2026.
  def home_fallback
    {
      principal: 2_637_592.17,
      outstanding: 2_572_312.50,
      remaining_months: 159,
      rate: 7.95,
      term_months: 165,
      emi_amount: 26_310,
      emi_basis_principal: 2_572_312.50,
      emi_basis_term_months: 159,
      tail_start_year: 2026,
      tail_start_month: 11,
      amount_slider_max: 20_000_000
    }
  end

  # Combined ₹9,64,377 @ 7.80% · EMI ₹9,580 · 164 months from 15 Nov 2026.
  def additional_fallback
    {
      principal: 493_615.07,
      outstanding: 482_188.50,
      remaining_months: 164,
      rate: 7.80,
      term_months: 172,
      emi_amount: 4_790,
      emi_basis_principal: 482_188.50,
      emi_basis_term_months: 164,
      tail_start_year: 2026,
      tail_start_month: 11,
      amount_slider_max: 5_000_000
    }
  end
end
