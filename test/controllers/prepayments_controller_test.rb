require "test_helper"

class PrepaymentsControllerTest < ActionDispatch::IntegrationTest
  test "redirects to login when not logged in for create" do
    loan = loans(:one)
    post loan_prepayments_url(loan), params: { prepayment: { amount: 1000, paid_on: Date.current } }
    assert_redirected_to new_session_path
  end

  test "creates prepayment when logged in as owner" do
    loan = loans(:one)
    post session_url, params: { email: "one@example.com", password: "password" }
    assert_difference -> { loan.prepayments.count }, 1 do
      post loan_prepayments_url(loan), params: { prepayment: { amount: 1000, paid_on: Date.current } }
    end
    assert_redirected_to root_path
  end

  test "rejects create when another user owns the loan" do
    loan = loans(:one)
    post session_url, params: { email: "two@example.com", password: "password" }
    assert_no_difference -> { loan.prepayments.count } do
      post loan_prepayments_url(loan), params: { prepayment: { amount: 1000, paid_on: Date.current } }
    end
    assert_redirected_to root_path
  end

  test "rejects when amount exceeds outstanding principal" do
    loan = loans(:one)
    post session_url, params: { email: "one@example.com", password: "password" }
    assert_no_difference -> { loan.prepayments.count } do
      post loan_prepayments_url(loan), params: { prepayment: { amount: 2_000_000, paid_on: Date.current } }
    end
    assert_redirected_to root_path
  end

  test "destroys prepayment when logged in as owner" do
    loan = loans(:one)
    prep = prepayments(:one)
    post session_url, params: { email: "one@example.com", password: "password" }
    # Within removal window (paid_on 2026-04-07 vs Date.current − 5 days)
    travel_to Time.zone.local(2026, 4, 8, 12, 0, 0) do
      assert_difference -> { loan.prepayments.count }, -1 do
        delete loan_prepayment_url(loan, prep)
      end
    end
    assert_redirected_to root_path
  end
end
