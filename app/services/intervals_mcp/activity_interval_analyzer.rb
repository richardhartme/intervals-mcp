# frozen_string_literal: true

module IntervalsMcp
  class ActivityIntervalAnalyzer
    HIGH_DRIFT_PERCENT = 5.0

    def initialize(activity:)
      @activity = activity
    end

    def analyze(include_recovery: false)
      selected = selected_intervals(include_recovery)

      {
        "activity" => @activity.summary,
        "intervals" => selected.each_with_index.map { |interval, index| interval.summary(position: index + 1) },
        "insights" => insights(selected),
        "data_availability" => data_availability(selected)
      }
    end

    private

    def selected_intervals(include_recovery)
      include_recovery ? @activity.intervals : @activity.work_intervals
    end

    def insights(intervals)
      return [ "No work intervals are available for this activity." ] if intervals.empty?

      drift_insights(intervals) + repeat_insights(intervals)
    end

    def drift_insights(intervals)
      intervals.filter_map do |interval|
        next unless interval.decoupling

        if interval.decoupling.abs >= HIGH_DRIFT_PERCENT
          "#{interval_name(interval)} showed #{format("%+.1f%%", interval.decoupling)} heart-rate drift."
        end
      end
    end

    def interval_name(interval)
      interval.label.presence || "Interval #{interval.id}"
    end

    def repeat_insights(intervals)
      return [] if intervals.length < 2

      comparison_insights(intervals, :average_watts, "average power", "W") +
        comparison_insights(intervals, :average_heartrate, "average heart rate", "bpm")
    end

    def comparison_insights(intervals, metric, label, unit)
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
