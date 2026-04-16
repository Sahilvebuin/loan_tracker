class User < ApplicationRecord
  has_secure_password

  has_many :loans, dependent: :destroy

  before_validation :normalize_email

  validates :name, presence: true
  validates :email, presence: true, uniqueness: { case_sensitive: false }
  validates :account_balance, numericality: { greater_than_or_equal_to: 0 }

  private

  def normalize_email
    self.email = email.to_s.strip.downcase
  end
end
