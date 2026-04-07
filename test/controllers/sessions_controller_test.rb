require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get new_session_url
    assert_response :success
  end

  test "should get create" do
    post session_url, params: { email: "one@example.com", password: "password" }
    assert_redirected_to root_path
  end

  test "should get destroy" do
    delete session_url
    assert_redirected_to root_path
  end
end
