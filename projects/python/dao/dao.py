#!/usr/bin/env python3
"""
DAO - Data Access Object providing unified interface 🐍

All operations follow an async pattern:
1. Generate UUID immediately
2. Store result with status="pending"
3. Execute operation (simulated synchronously for demo)
4. Update result to status="completed"
5. Return initial response {id: uuid, status: "pending"}

Clients poll for results using /result/poll operation.
Sssso elegant! 🐍
"""

import uuid
import sys
from pathlib import Path
from typing import Dict, Any

# Add parent directory to path to import store and operations
sys.path.insert(0, str(Path(__file__).parent.parent))

from store import ResultStore
from operations import prompt


class DAO:
    """
    Unified DAO interface for all operations 🐍

    Provides call(operation, params) method that routes to handlers.
    """

    def __init__(self):
        """Initialize DAO with result store 🐍"""
        self.store = ResultStore()

    def call(self, operation: str, params: Dict[str, Any] = None) -> Dict[str, Any]:
        """
        Call an operation with parameters 🐍

        Args:
            operation: Hierarchical operation path (e.g., "/prompt/generate")
            params: Operation-specific parameters

        Returns:
            Operation response with id, status, and optional result or error
        """
        if params is None:
            params = {}

        # Special case: /result/poll retrieves existing result 🐍
        if operation == '/result/poll':
            poll_id = params.get('id')
            if not poll_id:
                return {'error': 'Missing required parameter: id'}

            stored = self.store.get(poll_id)
            if not stored:
                return {'error': f'Result not found or expired: {poll_id}'}

            return stored

        # Generate correlation UUID 🐍
        id = str(uuid.uuid4())

        # Route to operation handler
        try:
            result = self._route_operation(operation, params)

            # Special case: /usage/track completes synchronously 🐍
            if operation == '/usage/track':
                completed_response = {
                    'id': id,
                    'status': 'completed',
                    'result': result
                }
                self.store.set(id, completed_response)
                return completed_response

            # Standard async pattern: store completed result, return pending 🐍
            completed_response = {
                'id': id,
                'status': 'completed',
                'result': result
            }
            self.store.set(id, completed_response)

            # Return initial pending response (async pattern) 🐍
            return {
                'id': id,
                'status': 'pending'
            }

        except Exception as e:
            # Store failed result and return error 🐍
            failed_response = {
                'id': id,
                'status': 'failed',
                'error': str(e)
            }
            self.store.set(id, failed_response)

            return {'error': str(e)}

    def _route_operation(self, operation: str, params: Dict[str, Any]) -> Dict[str, Any]:
        """
        Route operation to appropriate handler 🐍

        Args:
            operation: Operation path
            params: Operation parameters

        Returns:
            Operation result

        Raises:
            ValueError: If operation is unknown
        """
        if operation == '/prompt/generate':
            return prompt.process_prompt(params)
        elif operation == '/template/create':
            return prompt.create_template(params)
        elif operation == '/template/render':
            return prompt.render_template(params)
        elif operation == '/usage/track':
            return prompt.track_usage(params)
        else:
            raise ValueError(f'Invalid operation: {operation}')
