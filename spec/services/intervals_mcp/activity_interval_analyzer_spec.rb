# frozen_string_literal: true

require "rails_helper"

RSpec.describe IntervalsMcp::ActivityIntervalAnalyzer do
  subject(:analysis) { described_class.new(activity: activity).analyze }

  let(:activity) { IntervalsMcp::Activity.new({ "id" => "activity-1", "name" => "Five by five" }, intervals: intervals) }
  let(:intervals) do
    [
      interval("id" => 1, "label" => "Rep 1", "average_watts" => 300, "average_heartrate" => 150, "decoupling" => 2.0),
      interval("id" => 2, "label" => "Recovery", "type" => "RECOVERY", "average_watts" => 120, "average_heartrate" => 135),
      interval("id" => 3, "label" => "Rep 2", "average_watts" => 285, "average_heartrate" => 160, "decoupling" => 6.2)
    ]
  end

  it "returns work-interval splits, heart-rate drift data, and neutral repeat observations" do
    expect(analysis.fetch("intervals")).to contain_exactly(
      include("number" => 1, "label" => "Rep 1", "split" => include("elapsed_seconds" => 300), "heart_rate" => include("drift_percent" => 2.0)),
      include("number" => 2, "label" => "Rep 2", "heart_rate" => include("drift_percent" => 6.2)),
    )
    expect(analysis.fetch("observations")).to include(
      "From the first to final work interval, average power changed -5.0% (300 to 285 W).",
      "From the first to final work interval, average heart rate changed +6.7% (150 to 160 bpm).",
    )
  end

  it "can include recovery intervals" do
    result = described_class.new(activity: activity).analyze(include_recovery: true)

    expect(result.fetch("intervals").map { |interval| interval.fetch("label") }).to eq([ "Rep 1", "Recovery", "Rep 2" ])
  end

  def interval(attributes)
    IntervalsMcp::ActivityInterval.new(
      {
        "type" => "WORK",
        "start_time" => 0,
        "end_time" => 300,
        "moving_time" => 300,
        "elapsed_time" => 300,
        "distance" => 2500
      }.merge(attributes),
    )
  end
end
