Mix.install([{:playwright_ex, "~> 0.4"}])

ExUnit.start()

defmodule JsLogger do
  @behaviour PlaywrightEx.JsLogger

  @impl true
  def log(_level, text, _msg) do
    case :persistent_term.get(:test_pid, nil) do
      nil -> :ok
      pid -> send(pid, {:console, text})
    end
  end
end

defmodule PlaywrightTest do
  use ExUnit.Case

  alias PlaywrightEx.{Browser, BrowserContext, Frame}

  setup_all do
    {:ok, _} =
      PlaywrightEx.Supervisor.start_link(
        timeout: 5000,
        executable: "./node_modules/playwright/cli.js",
        js_logger: JsLogger
      )

    browser_type =
      System.argv()
      |> Enum.find_value(:firefox, fn
        "--project=chromium" -> :chromium
        "--project=firefox" -> :firefox
        _ -> nil
      end)

    {:ok, browser} = PlaywrightEx.launch_browser(browser_type, timeout: 5000)
    %{browser: browser}
  end

  setup %{browser: browser} do
    :persistent_term.put(:test_pid, self())

    {:ok, context} =
      Browser.new_context(browser.guid, user_agent: "Custom User Agent", timeout: 5000)

    {:ok, %{guid: page_guid, main_frame: frame}} =
      BrowserContext.new_page(context.guid, timeout: 5000)

    {:ok, _} =
      PlaywrightEx.Page.update_subscription(page_guid,
        event: :console,
        enabled: true,
        timeout: 5000
      )

    %{frame: frame}
  end

  test "has custom user agent", %{frame: frame} do
    {:ok, _} = Frame.goto(frame.guid, url: "http://localhost:8000/", timeout: 5000)
    assert_receive {:console, "Custom User Agent"}
  end

  test "has custom user agent for fetch requests", %{frame: frame} do
    {:ok, _} = Frame.goto(frame.guid, url: "http://localhost:8000/fetch", timeout: 5000)
    assert_receive {:console, "Custom User Agent"}, 5000
  end

  test "has custom user agent for worker fetch requests", %{frame: frame} do
    {:ok, _} = Frame.goto(frame.guid, url: "http://localhost:8000/", timeout: 5000)

    {:ok, ua} =
      Frame.evaluate(frame.guid,
        expression: """
        new Promise((resolve) => {
          const blob = new Blob([
            'fetch("http://localhost:8000/agent").then(r => r.text()).then(t => postMessage(t)).catch(e => postMessage("error: " + e));'
          ], {type: 'application/javascript'});
          const worker = new Worker(URL.createObjectURL(blob));
          worker.onmessage = e => resolve(e.data);
        })
        """,
        timeout: 5000
      )

    assert ua == "Custom User Agent", "Worker fetch sent UA: #{ua}"
  end
end
