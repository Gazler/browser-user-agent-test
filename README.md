# Browser User Agent Comparison

This project demonstrates how browsers report their `User-Agent` string
differently across contexts — direct page requests, `fetch()` calls, and Web
Worker `fetch()` calls — and shows that Chromium and Firefox behave differently.

## Installation

```
npm install
npx playwright install
```

Elixir is required for the exs script (tested on 1.18)

## The server

`server.js` is a dependency-free Node.js HTTP server with three endpoints:

| Endpoint     | Behaviour                                                                               |
| ------------ | --------------------------------------------------------------------------------------- |
| `GET /`      | Returns an HTML page that logs `navigator.userAgent` to the browser console             |
| `GET /fetch` | Returns an HTML page that fetches `/agent` and logs the response to the browser console |
| `GET /agent` | Returns the `User-Agent` header sent by the caller as plain text                        |

Every request also logs the URL and `User-Agent` to the server console.

Start it with:

```
node server.js
```

## JavaScript tests (Playwright)

Tests are in `tests/example.spec.js` and run against Chromium, Firefox, and
WebKit.

```
npx playwright test
npx playwright test --project=chromium
npx playwright test --project=firefox
```

The tests set a custom `User-Agent` of `"Custom User Agent"` and verify it
appears correctly in:

1. `navigator.userAgent` logged from a page script
2. A `fetch()` response from `/agent` initiated by the page
3. A `fetch()` response from `/agent` initiated inside a **Web Worker**

The Web Worker test is where browser differences emerge: chrome sends the
context's custom User-Agent from workers, while firefox uses the default value.

## Elixir tests (playwright_ex)

`playwright_ex.exs` is a self-contained Elixir script using
[playwright_ex](https://hex.pm/packages/playwright_ex) and ExUnit. It runs the
same three tests without needing a full Mix project.

Run against Firefox (default):

```
elixir playwright_ex.exs
```

Run against Chromium:

```
elixir playwright_ex.exs -- --project=chromium
```
