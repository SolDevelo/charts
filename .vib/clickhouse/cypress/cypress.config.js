module.exports = {
  env: {
    username: 'test_user',
    password: 'bitnami1234',
  },
  hosts: {
    'clickhouse.com': '{{ TARGET_IP }}',
  },
  defaultCommandTimeout: 30000,
  e2e: {
    setupNodeEvents(on, config) {},
  },
}
