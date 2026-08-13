# frozen_string_literal: true

module IntervalsMcp
  class Activity
    SUMMARY_FIELDS = %w[
      id
      name
      type
      start_date_local
      distance
      moving_time
      elapsed_time
      total_elevation_gain
      average_speed
      average_heartrate
      average_cadence
      calories
      icu_training_load
      icu_intensity
    ].freeze

    attr_reader(*SUMMARY_FIELDS, :intervals)

    def initialize(attributes = nil, intervals: nil, **keyword_attributes)
      attributes ||= keyword_attributes
      raise ArgumentError, "Activity attributes must be an object" unless attributes.is_a?(Hash)

      @attributes = normalize_attributes(attributes)
      @intervals = build_intervals(intervals || @attributes.fetch("icu_intervals", []))
      SUMMARY_FIELDS.each { |field| instance_variable_set("@#{field}", @attributes[field]) }
      freeze
    end

    def summary
      @attributes.slice(*SUMMARY_FIELDS)
    end

    def to_h
      @attributes.dup
    end

    def work_intervals
      intervals.select(&:work?)
    end

    def recovery_intervals
      intervals.reject(&:work?)
    end

    def with_intervals(intervals)
      self.class.new(@attributes, intervals: intervals)
    end

    private

    def normalize_attributes(attributes)
      attributes.transform_keys(&:to_s).freeze
    end

    def build_intervals(intervals)
      intervals.map { |interval| interval.is_a?(ActivityInterval) ? interval : ActivityInterval.new(interval) }.freeze
    end
  end
end
