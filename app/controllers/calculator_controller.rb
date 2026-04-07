class CalculatorController < ApplicationController
  include CalculatorHelper

  BROTHER_ONE_EMAIL = "brother1@example.com".freeze
  BROTHER_TWO_EMAIL = "brother2@example.com".freeze

  def index
    @brother_one = User.find_by(email: BROTHER_ONE_EMAIL)
    @brother_two = User.find_by(email: BROTHER_TWO_EMAIL)
    @calculator_config_one = loan_calculator_config_for(@brother_one)
    @calculator_config_two = loan_calculator_config_for(@brother_two)
    @home_loan_brother_one = @brother_one&.loans&.find_by(title: "Home Loan")
    @home_loan_brother_two = @brother_two&.loans&.find_by(title: "Home Loan")
    @additional_loan_brother_one = @brother_one&.loans&.find_by(title: "Additional Home Loan")
    @additional_loan_brother_two = @brother_two&.loans&.find_by(title: "Additional Home Loan")
  end
end
