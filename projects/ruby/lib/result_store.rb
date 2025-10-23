# frozen_string_literal: true

##
# ResultStore provides in-memory storage for operation results.
# Results are stored by correlation UUID and can be retrieved via polling.
#
# Thread Safety: MRI Ruby's GIL provides thread safety for Hash operations.
# For JRuby/TruffleRuby, consider adding a Mutex.
#
class ResultStore
  def initialize
    @store = {}
  end

  ##
  # Store an operation response by UUID.
  #
  # @param id [String] Correlation UUID
  # @param response [Hash] Operation response with :id, :status, :result, :error
  #
  def set(id, response)
    @store[id] = response
  end

  ##
  # Retrieve an operation response by UUID.
  #
  # @param id [String] Correlation UUID
  # @return [Hash, nil] Operation response if found, nil otherwise
  #
  def get(id)
    @store[id]
  end

  ##
  # Remove an operation response by UUID.
  #
  # @param id [String] Correlation UUID
  # @return [Hash, nil] Removed operation response if found, nil otherwise
  #
  def delete(id)
    @store.delete(id)
  end

  ##
  # Check if a result exists for the given UUID.
  #
  # @param id [String] Correlation UUID
  # @return [Boolean] True if result exists
  #
  def exists?(id)
    @store.key?(id)
  end

  ##
  # Clear all stored results (primarily for testing).
  #
  def clear
    @store.clear
  end
end
