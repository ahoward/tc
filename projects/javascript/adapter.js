#!/usr/bin/env node
/**
 * TC Adapter for JavaScript DAO implementation
 *
 * Contract:
 * - Read JSON from stdin: {operation: String, params: Object}
 * - Write JSON to stdout: {id: UUID, status: String, result?: Object, error?: String}
 * - Exit 0 for success (even if operation failed)
 * - Exit non-zero only for fatal adapter errors
 */

import fs from 'fs';
import DAO from './lib/dao.js';

async function main() {
  try {
    // Read and parse input JSON from stdin (fd 0)
    const inputData = fs.readFileSync(0, 'utf-8');
    const input = JSON.parse(inputData);

    // Extract operation and params
    const operation = input.operation;
    const params = input.params || {};

    // Create DAO instance and call operation
    const dao = new DAO();
    const response = dao.call(operation, params);

    // Write response JSON to stdout
    console.log(JSON.stringify(response));

    process.exit(0);

  } catch (error) {
    if (error instanceof SyntaxError) {
      // Invalid JSON input - fatal adapter error
      const errorResponse = {
        error: `Adapter error: Invalid JSON input - ${error.message}`
      };
      console.log(JSON.stringify(errorResponse));
      process.exit(1);
    } else {
      // Unexpected adapter error
      const errorResponse = {
        error: `Adapter error: ${error.message}`
      };
      console.log(JSON.stringify(errorResponse));
      process.exit(1);
    }
  }
}

main();
