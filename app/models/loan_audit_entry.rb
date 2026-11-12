# frozen_string_literal: true

class LoanAuditEntry < ApplicationRecord
  belongs_to :loan, optional: true
  belongs_to :user, optional: true
  belongs_to :auditable, polymorphic: true, optional: true

  validates :auditable_type, :action, presence: true

  scope :recent, -> { order(created_at: :desc) }

  def self.record!(loan:, auditable:, action:, old_values: {}, new_values: {}, reason: nil, user: nil)
    create!(
      loan: loan,
      auditable: auditable,
      action: action,
      old_values: old_values,
      new_values: new_values,
      reason: reason,
      user: user
    )
  end
end
