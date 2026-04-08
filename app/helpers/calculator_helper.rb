module CalculatorHelper
  EMI_PAY_DAY = 15

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
    home = (cfg[:home] || cfg["home"] || {}).with_indifferent_access
    p_orig = home[:principal].to_f
    rate = home[:annual_interest_rate].to_f
    m = home[:term_months].to_i
    outstanding = home[:outstanding_principal].present? ? home[:outstanding_principal].to_f : p_orig
    outstanding = [ outstanding, 0.0 ].max

    monthly = loan_emi(p_orig, rate, m)
    prepay_total = [ p_orig - outstanding, 0.0 ].max

    if outstanding <= 0.01
      return {
        emi: monthly,
        total_interest: 0.0,
        total_payment: 0.0,
        remaining_months: 0,
        outstanding_principal: 0.0
      }
    end

    m_rem =
      if prepay_total <= 0.01
        m
      else
        loan_months_from_fixed_emi(outstanding, rate, monthly)
      end

    total_payment = monthly * m_rem
    total_interest = total_payment - outstanding
    {
      emi: monthly,
      total_interest: total_interest,
      total_payment: total_payment,
      remaining_months: m_rem,
      outstanding_principal: outstanding
    }
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

  # EMIs on EMI_PAY_DAY whose due date is strictly before +as_of+ are treated as already paid (autopay after the 15th).
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

  # Hash for ERB: tenure UI for "home" slice (months vs years + slider max).
  def home_loan_ui(cfg)
    home = (cfg[:home] || cfg["home"] || {}).with_indifferent_access
    tm = home[:term_months].to_i
    if tm <= 0
      return { use_months: true, tenure_value: 165, tenure_max: 360, amount_max: 20_000_000,
               principal: 2_637_000, rate: 7.70 }
    end
    if (tm % 12).zero?
      { use_months: false, tenure_value: [ tm / 12, 30 ].min, tenure_max: 30, amount_max: (home[:amount_slider_max].presence || 20_000_000).to_i,
        principal: home[:principal].to_f, rate: home[:annual_interest_rate].to_f }
    else
      { use_months: true, tenure_value: tm, tenure_max: 360, amount_max: (home[:amount_slider_max].presence || 20_000_000).to_i,
        principal: home[:principal].to_f, rate: home[:annual_interest_rate].to_f }
    end
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
    # +principal+ = original disbursed amount (slider). Outstanding after prepayments is separate.
    principal =
      if loan
        loan.principal.to_d
      else
        (preset&.principal || hardcoded[:principal]).to_d
      end
    outstanding =
      if loan
        loan.outstanding_principal.to_d
      else
        principal
      end
    recorded_prepayment =
      if loan
        loan.total_prepayments.to_d
      else
        0.to_d
      end
    rate = (loan&.annual_interest_rate || preset&.annual_interest_rate || hardcoded[:rate]).to_d
    term_months = (loan&.term_months || preset&.term_months || hardcoded[:term_months]).to_i
    amount_slider_max = (preset&.amount_slider_max || hardcoded[:amount_slider_max]).to_i

    {
      principal: principal.to_f,
      outstanding_principal: outstanding.to_f,
      recorded_prepayment_total: recorded_prepayment.to_f,
      annual_interest_rate: rate.to_f,
      term_months: term_months,
      amount_slider_max: amount_slider_max
    }
  end

  def home_fallback
    {
      principal: 2_637_000,
      rate: 7.70,
      term_months: 165,
      amount_slider_max: 20_000_000
    }
  end

  def additional_fallback
    {
      principal: 2_637_000,
      rate: 7.70,
      term_months: 165,
      amount_slider_max: 20_000_000
    }
  end
end
