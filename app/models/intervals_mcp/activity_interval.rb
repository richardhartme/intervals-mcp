# frozen_string_literal: true

module IntervalsMcp
  class ActivityInterval
    FIELDS = %w[
      id
      type
      label
      group_id
      start_index
      end_index
      start_time
      end_time
      distance
      moving_time
      elapsed_time
      average_watts
      weighted_average_watts
      intensity
      training_load
      average_speed
      gap
      average_heartrate
      min_heartrate
      max_heartrate
      decoupling
      wbal_start
      wbal_end
      average_cadence
      total_elevation_gain
    ].freeze

    attr_reader(*FIELDS)

    def initialize(attributes)
      raise ArgumentError, "Interval attributes must be an object" unless attributes.is_a?(Hash)

      @attributes = attributes.transform_keys(&:to_s).freeze
      FIELDS.each { |field| instance_variable_set("@#{field}", @attributes[field]) }
      freeze
    end

    def work?
      type == "WORK"
    end

    def summary(position:)
      {
        "number" => position,
        "id" => id,
        "type" => type,
        "label" => label,
        "split" => split,
        "performance" => performance,
        "heart_rate" => heart_rate,
        "wbal_change_joules" => wbal_change
      }.compact
    end

    private

    def split
      compact_fields(
        "start_seconds" => start_time,
        "end_seconds" => end_time,
        "elapsed_seconds" => elapsed_time,
        "moving_seconds" => moving_time,
        "distance_meters" => distance,
      )
    end

    def performance
      compact_fields(
        "average_watts" => average_watts,
        "weighted_average_watts" => weighted_average_watts,
        "intensity_percent" => intensity,
        "average_speed_mps" => average_speed,
        "gap_seconds_per_km" => gap,
        "training_load" => training_load,
        "average_cadence" => average_cadence,
        "elevation_gain_meters" => total_elevation_gain,
      )
    end

    def heart_rate
      compact_fields(
        "average_bpm" => average_heartrate,
        "minimum_bpm" => min_heartrate,
        "maximum_bpm" => max_heartrate,
        "drift_percent" => decoupling,
      )
    end

    def wbal_change
      return unless wbal_start && wbal_end

      wbal_end - wbal_start
    end

    def compact_fields(fields)
      fields.compact
    end
  end
end
