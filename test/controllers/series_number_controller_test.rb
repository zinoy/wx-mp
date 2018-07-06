require 'test_helper'

class SeriesNumberControllerTest < ActionDispatch::IntegrationTest
  test "should get list" do
    get series_number_list_url
    assert_response :success
  end

  test "should get new" do
    get series_number_new_url
    assert_response :success
  end

end
