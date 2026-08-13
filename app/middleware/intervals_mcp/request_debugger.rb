# frozen_string_literal: true

require "json"
require "stringio"

module IntervalsMcp
  class RequestDebugger
    MAX_LOGGED_BODY_BYTES = 16 * 1024
    MCP_HEADERS = %w[
      HTTP_ACCEPT
      CONTENT_TYPE
      CONTENT_LENGTH
      HTTP_HOST
      HTTP_ORIGIN
      HTTP_USER_AGENT
      HTTP_MCP_PROTOCOL_VERSION
      HTTP_MCP_SESSION_ID
    ].freeze

    def initialize(app, logger: Rails.logger, parameter_filter: ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters))
      @app = app
      @logger = logger
      @parameter_filter = parameter_filter
    end

    def call(env)
      return @app.call(env) unless mcp_request?(env)

      request_body = capture_request_body(env)
      log_request(env, request_body)
      response = @app.call(env)
      log_response(response)
      response
    rescue StandardError => error
      @logger.debug("[MCP] request failed before a response: #{error.class}: #{error.message}")
      raise
    end

    private

    def mcp_request?(env)
      env["PATH_INFO"] == "/mcp" || env["PATH_INFO"].start_with?("/mcp/")
    end

    def capture_request_body(env)
      body = env.fetch("rack.input").read
      env["rack.input"] = StringIO.new(body)
      body
    end

    def log_request(env, body)
      @logger.debug(
        "[MCP] request method=#{env["REQUEST_METHOD"]} path=#{env["PATH_INFO"]} " \
        "headers=#{mcp_headers(env).to_json} body=#{filtered_body(body)}",
      )
    end

    def mcp_headers(env)
      MCP_HEADERS.to_h { |header| [ header.delete_prefix("HTTP_").downcase.tr("_", "-"), env[header] ] }.compact
    end

    def filtered_body(body)
      parsed_body = JSON.parse(body)
      truncate(JSON.generate(@parameter_filter.filter(parsed_body)))
    rescue JSON::ParserError
      truncate(body)
    end

    def log_response(response)
      status, headers, body = response
      return unless status >= 400

      @logger.debug(
        "[MCP] response status=#{status} content_type=#{headers["content-type"]} " \
        "body=#{response_body_for_log(body)}",
      )
    end

    def response_body_for_log(body)
      response_body = unwrap_response_body(body)
      return "[streaming response]" unless response_body.is_a?(Array)

      truncate(response_body.join)
    end

    def unwrap_response_body(body)
      return body unless body.instance_variable_defined?(:@body)

      unwrap_response_body(body.instance_variable_get(:@body))
    end

    def truncate(value)
      return value if value.bytesize <= MAX_LOGGED_BODY_BYTES

      "#{value.byteslice(0, MAX_LOGGED_BODY_BYTES)}...[truncated]"
    end
  end
end
