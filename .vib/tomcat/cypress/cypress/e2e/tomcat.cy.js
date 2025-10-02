/*
 * Copyright Broadcom, Inc. All Rights Reserved.
 * SPDX-License-Identifier: APACHE-2.0
 */

/// <reference types="cypress" />
import { random } from '../support/utils';

it('allows to deploy a new WAR app', () => {
  cy.visitAuth('/manager');
  cy.contains('/examples').click();
  cy.contains('Servlets examples').click();
  cy.get('[href*="servlet/HelloWorldExample"]').first().click();
  cy.contains('Hello World!');
});
