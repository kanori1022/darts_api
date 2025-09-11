module AuthHelper
  # Stubs ApplicationController#authenticate_user to set @current_user
  def stub_current_user(user)
    allow_any_instance_of(ApplicationController).to receive(:authenticate_user) do |controller|
      controller.instance_variable_set(:@current_user, user)
    end
  end

  # Builds Authorization header with a non-verified JWT for when you prefer exercising the filter
  def auth_headers_for(user)
    payload = {
      "iss" => "https://securetoken.google.com/combines-darts",
      "user_id" => user.firebase_uid || "test-uid"
    }
    token = JWT.encode(payload, nil, "none")
    { "Authorization" => "Bearer #{token}" }
  end
end

RSpec.configure do |config|
  config.include AuthHelper, type: :request
end


