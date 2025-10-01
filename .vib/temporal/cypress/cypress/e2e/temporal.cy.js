/*
 * Copyright Broadcom, Inc. All Rights Reserved.
 * SPDX-License-Identifier: APACHE-2.0
 */

/// <reference types="cypress" />

it('allows inspecting namespaces', () => {
  cy.visit('/namespaces');
  cy.get('[href="/namespaces/default"]').click();
  cy.contains('Details');
  cy.contains('Client Actions');
  cy.contains('Versions');
});

it('allows inspecting workflows', () => {
  cy.visit('/namespaces/default/workflows');
  cy.contains('No Workflows running in this Namespace');
  cy.get('[href*="namespaces/default/workflows/start-workflow"]').click();
  cy.contains('Start a Workflow');
});
