import Config

if config_env() == :test do
  # Print only warnings and errors during test
  config :logger, level: :warning

  data_path = Path.expand("tmp/livebook_data/test")

  # Clear data path for tests
  if File.exists?(data_path) do
    File.rm_rf!(data_path)
  end

  config :livebook,
    random_boot_id: :crypto.strong_rand_bytes(3),
    cookie: :"c_#{Base.url_encode64(:crypto.strong_rand_bytes(39))}",
    identity_provider: {:session, Livebook.ZTA.PassThrough, :unused},
    data_path: data_path,
    teams_url: "https://teams.livebook.dev",
    agent_name: "chonky-cat",
    app_service_name: nil,
    app_service_url: nil,
    authentication_mode: :disabled,
    feature_flags: [deployment_groups: true],
    force_ssl_host: nil,
    learn_notebooks: [],
    plugs: [],
    shutdown_callback: nil,
    update_instructions_url: nil,
    within_iframe: false,
    allowed_uri_schemes: [],
    aws_credentials: false,
    check_completion_data_interval: 300,
    iframe_port: 4003

  config :livebook, Livebook.Apps.Manager, retry_backoff_base_ms: 0

  config :livebook, LivebookWeb.Endpoint,
    otp_app: :kino_proxy,
    http: [port: 4002],
    secret_key_base: Base.encode64(:crypto.strong_rand_bytes(48)),
    adapter: Bandit.PhoenixAdapter,
    url: [host: "localhost", path: "/"],
    pubsub_server: Livebook.PubSub,
    live_view: [signing_salt: "livebook"],
    drainer: [shutdown: 1000],
    render_errors: [formats: [html: LivebookWeb.ErrorHTML], layout: false],
    server: true

  # Use longnames when running tests in CI, so that no host resolution is required,
  # see https://github.com/livebook-dev/livebook/pull/173#issuecomment-819468549
  if System.get_env("CI") == "true" do
    config :livebook, :node, {:longnames, :"livebook@127.0.0.1"}
  end
end
