require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get new_user_url
    assert_response :success
  end

  test "creates user and redirects to calculator" do
    assert_difference("User.count", 1) do
      post users_url, params: { user: { name: "Brother Three", email: "brother3@example.com", password: "password", password_confirmation: "password" } }
    end
    assert_redirected_to root_path
  end
end
