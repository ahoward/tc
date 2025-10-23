/**
 * DAO - Data Access Object providing unified interface
 *
 * All operations follow an async pattern:
 * 1. Generate UUID immediately
 * 2. Store result with status="pending"
 * 3. Execute operation (simulated synchronously for demo)
 * 4. Update result to status="completed"
 * 5. Return initial response {id: uuid, status: "pending"}
 *
 * Clients poll for results using /result/poll operation.
 */

import { v4 as uuidv4 } from 'uuid';
import ResultStore from './store.js';
import * as operations from './operations.js';

class DAO {
  constructor() {
    this.store = new ResultStore();
  }

  /**
   * Call an operation with parameters
   * @param {string} operation - Hierarchical operation path
   * @param {object} params - Operation-specific parameters
   * @returns {object} Operation response with id, status, and optional result or error
   */
  call(operation, params = {}) {
    // Special case: /result/poll retrieves existing result
    if (operation === '/result/poll') {
      const pollId = params.id;
      if (!pollId) {
        return { error: 'Missing required parameter: id' };
      }

      const stored = this.store.get(pollId);
      if (!stored) {
        return { error: `Result not found or expired: ${pollId}` };
      }

      return stored;
    }

    // Generate correlation UUID
    const id = uuidv4();

    // Route to operation handler
    try {
      const result = this._routeOperation(operation, params);

      // Special case: /usage/track completes synchronously
      if (operation === '/usage/track') {
        const completedResponse = {
          id: id,
          status: 'completed',
          result: result
        };
        this.store.set(id, completedResponse);
        return completedResponse;
      }

      // Standard async pattern: store completed result, return pending
      const completedResponse = {
        id: id,
        status: 'completed',
        result: result
      };
      this.store.set(id, completedResponse);

      // Return initial pending response (async pattern)
      return {
        id: id,
        status: 'pending'
      };

    } catch (error) {
      // Store failed result and return error
      const failedResponse = {
        id: id,
        status: 'failed',
        error: error.message
      };
      this.store.set(id, failedResponse);

      return { error: error.message };
    }
  }

  /**
   * Route operation to appropriate handler
   * @param {string} operation - Operation path
   * @param {object} params - Operation parameters
   * @returns {object} Operation result
   * @private
   */
  _routeOperation(operation, params) {
    switch (operation) {
      case '/prompt/generate':
        return operations.processPrompt(params);
      case '/template/create':
        return operations.createTemplate(params);
      case '/template/render':
        return operations.renderTemplate(params);
      case '/usage/track':
        return operations.trackUsage(params);
      default:
        throw new Error(`Invalid operation: ${operation}`);
    }
  }
}

export default DAO;
