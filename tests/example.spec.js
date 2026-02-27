// @ts-check
import { test, expect } from "@playwright/test";

test.use({ userAgent: "Custom User Agent" });


test("has custom user agent", async ({ page }) => {
  const logs = [];
  page.on("console", msg => {
    logs.push(msg.text());
  });
  await page.goto("http://localhost:8000/");
  expect(logs).toContain("Custom User Agent");
});


test("has custom user agent for fetch requests", async ({ page }) => {
  const logs = [];
  page.on("console", msg => {
    logs.push(msg.text());
  });
  await page.goto("http://localhost:8000/fetch");
  await expect(page.locator("body")).toHaveText("fetched");
  expect(logs).toContain("Custom User Agent");
});


test("has custom user agent for worker fetch requests", async ({ page }) => {
  await page.goto("http://localhost:8000/");
  const ua = await page.evaluate(() =>
    new Promise((resolve) => {
      const blob = new Blob([
        'fetch("http://localhost:8000/agent").then(r => r.text()).then(t => postMessage(t)).catch(e => postMessage("error: " + e));'
      ], { type: "application/javascript" });
      const worker = new Worker(URL.createObjectURL(blob));
      worker.onmessage = e => resolve(e.data);
    })
  );
  expect(ua).toBe("Custom User Agent");
});
