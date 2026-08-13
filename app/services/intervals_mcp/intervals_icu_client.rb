# frozen_string_literal: true

require "json"
require "net/http"
require "uri"

module IntervalsMcp
  class IntervalsIcuClient
    BASE_URL = "https://intervals.icu".freeze
    OPEN_TIMEOUT = 5
    READ_TIMEOUT = 15

    class Error < StandardError; end
    class ConfigurationError < Error; end
    class AuthenticationError < Error; end
    class NotFoundError < Error; end
    class RateLimitError < Error; end
    class UpstreamError < Error; end

    def initialize(api_key: ENV.fetch("INTERVALS_ICU_API_KEY", nil), base_url: BASE_URL)
      @api_key = api_key
      @base_url = base_url
    end

    def list_activities(athlete_id:, oldest:, newest: nil, limit: nil, route_id: nil, fields: nil)
      activities = get(
        "/api/v1/athlete/#{escape_path(athlete_id)}/activities",
        oldest: validate_local_date!(oldest, "oldest"),
        newest: newest && validate_local_date!(newest, "newest"),
        limit: validate_positive_integer!(limit, "limit"),
        route_id: route_id,
        fields: fields && Array(fields).join(","),
      )
      raise UpstreamError, "Intervals.icu returned an invalid activities response" unless activities.is_a?(Array)

      activities.map { |activity| Activity.new(activity) }
    end

    def get_activity_with_intervals(activity_id:)
      get_activity(activity_id: activity_id, intervals: true)
    end

    def get_activity(activity_id:, intervals: false)
      Activity.new(get("/api/v1/activity/#{escape_path(activity_id)}", intervals: intervals))
    end

    def get_intervals(activity_id:)
      response = get("/api/v1/activity/#{escape_path(activity_id)}/intervals")
      intervals = response["icu_intervals"]
      raise UpstreamError, "Intervals.icu returned an invalid intervals response" unless intervals.is_a?(Array)

      intervals.map { |interval| ActivityInterval.new(interval) }
    end

    private

    def get(path, query = {})
      require_api_key!
      response = perform_get(build_uri(path, query))
      parse_response(response)
    rescue SocketError, Errno::ECONNREFUSED, Net::OpenTimeout, Net::ReadTimeout => error
      raise UpstreamError, "Intervals.icu could not be reached: #{error.class}"
    end

    def require_api_key!
      raise ConfigurationError, "INTERVALS_ICU_API_KEY is not configured" if @api_key.to_s.empty?
    end

    def build_uri(path, query)
      uri = URI.join(@base_url, path)
      compact_query = query.compact
      uri.query = URI.encode_www_form(compact_query) if compact_query.any?
      uri
    end

    def perform_get(uri)
      request = Net::HTTP::Get.new(uri).tap { |value| value.basic_auth("API_KEY", @api_key) }
      Net::HTTP.start(
        uri.host,
        uri.port,
        use_ssl: uri.scheme == "https",
        open_timeout: OPEN_TIMEOUT,
        read_timeout: READ_TIMEOUT,
      ) { |http| http.request(request) }
    end

    def parse_response(response)
      return JSON.parse(response.body) if response.is_a?(Net::HTTPSuccess)

      case response.code.to_i
      when 401, 403 then raise AuthenticationError, "Intervals.icu authentication failed"
      when 404 then raise NotFoundError, "The requested Intervals.icu resource was not found"
      when 429 then raise RateLimitError, "Intervals.icu rate limit exceeded"
      else raise UpstreamError, "Intervals.icu returned HTTP #{response.code}"
      end
    rescue JSON::ParserError
      raise UpstreamError, "Intervals.icu returned an invalid JSON response"
    end

    def escape_path(value)
      URI::DEFAULT_PARSER.escape(value.to_s, /[^#{URI::PATTERN::UNRESERVED}]/)
    end

    def validate_local_date!(value, name)
      string = value.to_s
      Date.iso8601(string)
      string
    rescue Date::Error
      raise ArgumentError, "#{name} must be an ISO 8601 date or date-time"
    end

    def validate_positive_integer!(value, name)
      return if value.nil?

      integer = Integer(value)
      raise ArgumentError, "#{name} must be greater than zero" unless integer.positive?

      integer
    rescue ArgumentError, TypeError
      raise ArgumentError, "#{name} must be a positive integer"
    end
  end
end
