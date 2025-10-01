/*
 * Copyright Broadcom, Inc. All Rights Reserved.
 * SPDX-License-Identifier: APACHE-2.0
 */

/// <reference types="cypress" />

// NOTE: The UI is fully based on mouse and drag & drop events, which do not work properly in Cypress
// Instead we go to the admin panel and check the cluster status
it('Allows to login and check the cluster status', () => {
  cy.login();
  cy.visit('nifi/#/cluster/nodes')
  // There's a primary node
  cy.contains('PRIMARY');
  // There's a coordinator node
  cy.contains('COORDINATOR');
});
