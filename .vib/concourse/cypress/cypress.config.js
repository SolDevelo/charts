module.exports = {
  env: {
    username: 'bitnamiUser',
    password: 'ComplicatedPassword123!4',
  },
  hosts: {
    'concourse.com': '{{ TARGET_IP }}',
  },
  e2e: {
    setupNodeEvents(on, config) {},
  },
}
