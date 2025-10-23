#!/usr/bin/env python3
"""
ResultStore - In-memory storage for operation results 🐍

Thread-safe storage using dict and threading.Lock.
Ssssimple and effective!
"""

import threading
from typing import Dict, Optional


class ResultStore:
    """Thread-safe result storage. Keeps track of all those async operations! 🐍"""

    def __init__(self):
        """Initialize the store with an empty dict and a lock 🐍"""
        self.store: Dict[str, dict] = {}
        self.lock = threading.Lock()

    def set(self, id: str, response: dict) -> None:
        """
        Store an operation response by UUID.

        Args:
            id: Correlation UUID 🐍
            response: Operation response dict
        """
        with self.lock:
            self.store[id] = response

    def get(self, id: str) -> Optional[dict]:
        """
        Retrieve an operation response by UUID.

        Args:
            id: Correlation UUID 🐍

        Returns:
            Operation response if found, None otherwise
        """
        with self.lock:
            return self.store.get(id)

    def delete(self, id: str) -> Optional[dict]:
        """
        Remove an operation response by UUID.

        Args:
            id: Correlation UUID 🐍

        Returns:
            Removed response if found, None otherwise
        """
        with self.lock:
            return self.store.pop(id, None)

    def exists(self, id: str) -> bool:
        """
        Check if a result exists for the given UUID.

        Args:
            id: Correlation UUID 🐍

        Returns:
            True if result exists
        """
        with self.lock:
            return id in self.store
