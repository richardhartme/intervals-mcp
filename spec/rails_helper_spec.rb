# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Rails configuration" do
  it "boots in the test environment" do
    expect(Rails.env).to eq("test")
  end
end
