require_relative '../test_helper'

include Rack::Test::Methods
  
def app
  ResolveController.new
end

describe "resolve" do
  it "sets status to 400 if no parameters has been supplied" do
    EM.run_block {
      get '/'
      assert_equal 400, last_response.status
    }
  end  

  it "handles requests for unknown services" do
  end
  
end

### benchmark example - http://recipes.sinatrarb.com/p/testing/minitest

# require 'minitest/benchmark'

# include Rack::Test::Methods

# def app
#   Sinatra::Application
# end

# describe "my example app" do
#   bench_range { bench_exp 1, 10_000 }
#   bench_performance_linear "welcome message", 0.9999 do |n|
#     n.times do
#       get '/'
#       assert_equal 'Welcome to my page!', last_response.body
#     end
#   end
# end
