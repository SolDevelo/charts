module.exports = {
  env: {
    username: 'vib-user',
    password: 'ComplicatedPassword123!4',
  },
  defaultCommandTimeout: 30000,
  e2e: {
    setupNodeEvents(on, config) {},
    baseUrl: 'https://nifi.com',
  },
  hosts: {
    'nifi.com': '{{ TARGET_IP }}',
  },
  retries: 5
}
