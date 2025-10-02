module.exports = {
  viewportWidth: 1920,
  viewportHeight: 1080,
  env: {
    user: 'test_user',
    password: 'ComplicatedPassword123!4',
  },
  e2e: {
    setupNodeEvents(on, config) {},
    baseUrl: 'http://localhost/',
    defaultBrowser: 'chrome',
  },
}
