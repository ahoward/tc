/**
 * ResultStore - In-memory storage for operation results
 *
 * Provides simple Map-based storage for async operation results.
 * Node.js is single-threaded, so no mutex needed for synchronous code.
 */

class ResultStore {
  constructor() {
    this.store = new Map();
  }

  /**
   * Store an operation response by UUID
   * @param {string} id - Correlation UUID
   * @param {object} response - Operation response
   */
  set(id, response) {
    this.store.set(id, response);
  }

  /**
   * Retrieve an operation response by UUID
   * @param {string} id - Correlation UUID
   * @returns {object|undefined} Operation response if found
   */
  get(id) {
    return this.store.get(id);
  }

  /**
   * Remove an operation response by UUID
   * @param {string} id - Correlation UUID
   * @returns {boolean} True if removed
   */
  delete(id) {
    return this.store.delete(id);
  }

  /**
   * Check if a result exists for the given UUID
   * @param {string} id - Correlation UUID
   * @returns {boolean} True if result exists
   */
  exists(id) {
    return this.store.has(id);
  }
}

export default ResultStore;
