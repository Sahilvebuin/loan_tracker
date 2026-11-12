# frozen_string_literal: true

require "test_helper"

class LoanEmiSchedulesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @loan = loans(:one)
    LoanEmiScheduleGenerator.generate!(@loan, mode: :full, as_of: Date.new(2026, 4, 1))
  end

  test "index shows schedule" do
    get loan_loan_emi_schedules_url(@loan)
    assert_response :success
    assert_match(/EMI schedule/, @response.body)
  end

  test "guest cannot regenerate schedule" do
    assert_no_difference -> { @loan.loan_emi_schedules.count } do
      post loan_loan_emi_schedules_url(@loan), params: { mode: "full" }
    end
    assert_redirected_to new_session_url
  end

  test "owner can regenerate schedule" do
    post session_url, params: { email: users(:one).email, password: "password" }
    post loan_loan_emi_schedules_url(@loan), params: { mode: "full" }
    assert_redirected_to loan_loan_emi_schedules_url(@loan)
  end
end
