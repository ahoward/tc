#!/usr/bin/env python3
"""
TC Adapter for Python DAO implementation 🐍

Contract:
- Read JSON from stdin: {operation: String, params: Object}
- Write JSON to stdout: {id: UUID, status: String, result?: Object, error?: String}
- Exit 0 for success (even if operation failed)
- Exit non-zero only for fatal adapter errors

Sssslither through that JSON like a pro! 🐍
"""

import json
import sys
from pathlib import Path

# Add current directory to path to import dao
sys.path.insert(0, str(Path(__file__).parent))

from dao.dao import DAO


def main():
    """Main adapter entry point 🐍"""
    try:
        # Read and parse input JSON from stdin 🐍
        input_data = json.load(sys.stdin)

        # Extract operation and params 🐍
        operation = input_data.get('operation')
        params = input_data.get('params', {})

        # Create DAO instance and call operation 🐍
        dao = DAO()
        response = dao.call(operation, params)

        # Write response JSON to stdout 🐍
        print(json.dumps(response))

        sys.exit(0)

    except json.JSONDecodeError as e:
        # Invalid JSON input - fatal adapter error 🐍
        error_response = {
            'error': f'Adapter error: Invalid JSON input - {str(e)}'
        }
        print(json.dumps(error_response))
        sys.exit(1)

    except Exception as e:
        # Unexpected adapter error 🐍
        error_response = {
            'error': f'Adapter error: {str(e)}'
        }
        print(json.dumps(error_response))
        sys.exit(1)


if __name__ == '__main__':
    main()
