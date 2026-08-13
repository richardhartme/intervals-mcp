Rails.application.routes.draw do
  mcp_public_host = ENV.fetch("MCP_PUBLIC_HOST", ENV.fetch("NGROK_HOST", "b863-88-97-204-75.ngrok-free.app"))
  mcp_transport = MCP::Server::Transports::StreamableHTTPTransport.new(
    IntervalsMcp::Server.build,
    allowed_hosts: [ mcp_public_host ],
    stateless: true,
    enable_json_response: true,
  )
  mount mcp_transport => "/mcp"

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"
end
