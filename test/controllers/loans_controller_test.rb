require "test_helper"

class LoansControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get loans_url
    assert_response :success
  end

  test "should get show" do
    get loan_url(loans(:one))
    assert_response :success
  end

  test "should get new" do
    get new_loan_url
    assert_redirected_to new_session_path
  end

  test "should get create" do
    post loans_url, params: { loan: { user_id: users(:one).id, principal: 100000, annual_interest_rate: 9.5, term_months: 60, start_date: Date.current } }
    assert_redirected_to new_session_path
  end

  test "should get edit" do
    get edit_loan_url(loans(:one))
    assert_redirected_to new_session_path
  end

  test "should get update" do
    patch loan_url(loans(:one)), params: { loan: { title: "Updated" } }
    assert_redirected_to new_session_path
  end

  test "should get destroy" do
    delete loan_url(loans(:one))
    assert_redirected_to new_session_path
  end

  test "updates principal when logged in as owner" do
    loan = loans(:one)
    post session_url, params: { email: "one@example.com", password: "password" }
    patch loan_url(loan), params: { loan: { principal: 123_456 } }
    assert_redirected_to root_path
    loan.reload
    assert_equal 123_456, loan.principal.to_i
  end
end
