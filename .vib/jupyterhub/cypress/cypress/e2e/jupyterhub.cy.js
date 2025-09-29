/*
 * Copyright Broadcom, Inc. All Rights Reserved.
 * SPDX-License-Identifier: APACHE-2.0
 */

/// <reference types="cypress" />
import { random } from '../support/utils';

it('allows to upload and execute a python notebook', () => {
  cy.session('test_upload', () => {
    const userName = Cypress.env('username');

    cy.clearCookies()
    cy.login();
    cy.visit(`/user/${userName}/tree/tmp`);
    cy.contains('Upload').should('be.visible');
    cy.get('.jp-DirListing-content').selectFile('cypress/fixtures/notebook.ipynb', { action: 'drag-drop' });
    // Click overwrite button if file exists
    cy.get('body').then(($body) => {
      if ($body.find('[aria-label="Overwrite Existing File"]').is(':visible')) {
        cy.contains('Overwrite').click();
      }
    });
    cy.contains('li', 'notebook.ipynb');
    cy.visit(`/user/${userName}/notebooks/tmp/notebook.ipynb`);
    cy.contains('div', 'Run').click();
    cy.contains('div', 'Run All Cells').click();
    cy.contains('Hello World!');
  });
});

it('allows generating an API token', () => {
  cy.session('test_token', () => {
    cy.clearCookies()
    cy.login();
    cy.visit('/hub/token');
    // We need to wait until the background API request is finished
    cy.contains(/\d+Z/).should('not.exist');
    cy.contains('button', 'API token').click();
    cy.get('#token-result')
      .should('be.visible')
      .invoke('text')
      .then((apiToken) => {
        cy.request({
          url: '/hub/api/users',
          method: 'GET',
          headers: {
            Authorization: `token ${apiToken}`,
          },
        }).then((response) => {
          expect(response.status).to.eq(200);
          expect(response.body[0].name).to.eq(Cypress.env('username'));
        });
      });
  });
});
