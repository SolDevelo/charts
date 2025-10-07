module.exports = {
  viewportWidth: 1920,
  viewportHeight: 1080,
  chromeWebSecurity: false,
  pageLoadTimeout: 240000,
  defaultCommandTimeout: 80000,
  env: {
    username: 'user',
    password: 'ComplicatedPassword123!4',
    baseUrl: 'http://airflow.apache.org',
  },
  e2e: {
    setupNodeEvents(on, config) {},
  },
  hosts: {
    'airflow.apache.org': '{{ TARGET_IP }}',
  },
}
