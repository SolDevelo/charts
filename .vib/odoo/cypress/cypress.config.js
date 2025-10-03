module.exports = {
  viewportWidth: 1920,
  viewportHeight: 1080,
  env: {
    email: 'user@example.com',
    password: 'ComplicatedPassword123!4',
  },
  defaultCommandTimeout: 70000,
  pageLoadTimeout: 150000,
  e2e: {
    setupNodeEvents(on, config) {},
    baseUrl: 'http://localhost/',
    defaultBrowser: 'chromium',
  },
}
