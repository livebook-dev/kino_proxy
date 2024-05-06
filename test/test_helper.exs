Application.put_env(:livebook, :default_runtime, Livebook.Runtime.Embedded.new())
Application.put_env(:livebook, :default_app_runtime, Livebook.Runtime.Embedded.new())

ExUnit.start(assert_receive_timeout: 1_500)
