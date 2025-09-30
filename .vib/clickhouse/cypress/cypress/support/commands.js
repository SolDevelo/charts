/*
 * Copyright Broadcom, Inc. All Rights Reserved.
 * SPDX-License-Identifier: APACHE-2.0
 */

const COMMAND_DELAY = 2000;
const BASE_URL = 'https://clickhouse.com';

for (const command of ['click']) {
  Cypress.Commands.overwrite(command, (originalFn, ...args) => {
    const origVal = originalFn(...args);

    return new Promise((resolve) => {
      setTimeout(() => {
        resolve(origVal);
      }, COMMAND_DELAY);
    });
  });
}

// Due to a bug when using "hosts" in Cypress, we cannot set a "baseUrl" in the
// cypress.json file. Workaround this by modifying the "visit" command to preprend
// the base URL.
//
// Further details: https://github.com/cypress-io/cypress/issues/20647
Cypress.Commands.overwrite('visit', (originalFn, url, options) => {
  return originalFn(`${BASE_URL}${url}`, options);
});

Cypress.on('uncaught:exception', (err) => {
  // We expect an error "The user agent does not support public key credentials."
  // when the browser does not support WebAuthn. This is expected in our tests
  // as we are not testing WebAuthn functionality, so we ignore this error.
  if (err.message.includes("The user agent does not support public key credentials.")) {
    return false;
  }
  // we still want to ensure there are no other unexpected
  // errors, so we let them fail the test
})
