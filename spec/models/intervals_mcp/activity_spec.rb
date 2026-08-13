# frozen_string_literal: true

require "rails_helper"

RSpec.describe IntervalsMcp::Activity do
  subject(:activity) do
    described_class.new(
      "id" => "activity-1",
      "name" => "Morning ride",
      "distance" => 42_000,
      "icu_training_load" => 85,
      "device_name" => "Garmin Edge 540",
    )
  end

  it "exposes the common activity attributes" do
    expect(activity.id).to eq("activity-1")
    expect(activity.name).to eq("Morning ride")
    expect(activity.distance).to eq(42_000)
    expect(activity.icu_training_load).to eq(85)
  end

  it "returns a concise summary for activity listings" do
    expect(activity.summary).to eq(
      "id" => "activity-1",
      "name" => "Morning ride",
      "distance" => 42_000,
      "icu_training_load" => 85,
    )
  end

  it "preserves full upstream data for a single activity" do
    expect(activity.to_h).to include("device_name" => "Garmin Edge 540")
  end

  it "owns interval value objects and categorizes work and recovery" do
    aggregate = described_class.new(
      { "id" => "activity-1" },
      intervals: [
        { "id" => 1, "type" => "WORK" },
        { "id" => 2, "type" => "RECOVERY" }
      ],
    )

    expect(aggregate.intervals).to all(be_a(IntervalsMcp::ActivityInterval))
    expect(aggregate.work_intervals.map(&:id)).to eq([ 1 ])
    expect(aggregate.recovery_intervals.map(&:id)).to eq([ 2 ])
  end
end
