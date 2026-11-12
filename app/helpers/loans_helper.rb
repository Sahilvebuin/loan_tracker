# frozen_string_literal: true

module LoansHelper
  def loan_repaid_percent(loan)
    original = loan.original_principal.to_d
    return 0 if original <= 0

    paid = loan.total_principal_paid_ledger.to_d
    ((paid / original) * 100).clamp(0, 100).round(1)
  end

  def loan_remaining_percent(loan)
    original = loan.original_principal.to_d
    return 0 if original <= 0

    left = loan.ledger_outstanding.to_d
    ((left / original) * 100).clamp(0, 100).round(1)
  end

  def person_account_theme(name)
    case name.to_s.strip.downcase
    when "sahil" then "blue"
    when "sanket" then "green"
    else "neutral"
    end
  end

  def loan_years_months_label(months)
    m = months.to_i
    return "0 months" if m <= 0

    years = m / 12
    rem = m % 12
    parts = []
    parts << "#{years} #{'year'.pluralize(years)}" if years.positive?
    parts << "#{rem} #{'month'.pluralize(rem)}" if rem.positive? || years.zero?
    parts.join(" ")
  end

  def payment_type_plain(type)
    {
      "emi" => "Monthly EMI",
      "prepayment" => "Extra prepayment",
      "part_payment" => "Part payment",
      "late_payment" => "Late payment",
      "other" => "Other payment"
    }[type.to_s] || type.to_s.tr("_", " ").titleize
  end

  def schedule_status_plain(status)
    {
      "paid" => "Paid",
      "pending" => "Upcoming",
      "overdue" => "Overdue",
      "partially_paid" => "Partly paid",
      "skipped" => "Skipped",
      "cancelled" => "Cancelled"
    }[status.to_s] || status.to_s.tr("_", " ").titleize
  end
end
