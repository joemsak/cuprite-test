require "system_helper"

RSpec.describe "Hello world" do
  scenario do
    visit root_path
    expect(page.body).to have_content("Hello cuprite world")
  end
end
