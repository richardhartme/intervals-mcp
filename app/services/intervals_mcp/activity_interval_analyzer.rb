# frozen_string_literal: true

module IntervalsMcp
  class ActivityIntervalAnalyzer
    def initialize(activity:)
      @activity = activity
    end

    def analyze(include_recovery: false)
      selected = selected_intervals(include_recovery)

      {
        "activity" => @activity.summary,
        "intervals" => selected.each_with_index.map { |interval, index| interval.summary(position: index + 1) },
        "observations" => observations(selected),
        "data_availability" => data_availability(selected)
      }
    end

    private

    def selected_intervals(include_recovery)
      include_recovery ? @activity.intervals : @activity.work_intervals
    end

    def observations(intervals)
      return [ "No work intervals are available for this activity." ] if intervals.empty?

      repeat_observations(intervals)
    end

    def repeat_observations(intervals)
      return [] if intervals.length < 2

      comparison_observations(intervals, :average_watts, "average power", "W") +
        comparison_observations(intervals, :average_heartrate, "average heart rate", "bpm")
    end

    def comparison_observations(intervals, metric, label, unit)
      first = intervals.first.public_send(metric)
      last = intervals.last.public_send(metric)
      return [] unless first && last && first.nonzero?

      change = ((last - first) / first.to_f) * 100
      [ "From the first to final work interval, #{label} changed #{format("%+.1f%%", change)} (#{first} to #{last} #{unit})." ]
    end

    def data_availability(intervals)
      {
        "heart_rate" => intervals.any? { |interval| interval.average_heartrate },
        "power" => intervals.any? { |interval| interval.average_watts },
        "interval_decoupling" => intervals.any? { |interval| !interval.decoupling.nil? }
      }
    end
  end
end
