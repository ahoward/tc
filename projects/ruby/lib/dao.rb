# frozen_string_literal: true

require 'securerandom'
require_relative 'result_store'
require_relative 'operations'

##
# DAO (Data Access Object) provides a unified interface for operation invocation.
#
# All operations follow an async pattern:
# 1. Operation is invoked with call(operation, params)
# 2. UUID is generated immediately
# 3. Result is stored with status="pending"
# 4. Operation executes (simulated synchronously for demo)
# 5. Result is updated to status="completed" with result data
# 6. Initial response returns {id: uuid, status: "pending"}
#
# Client can poll for results using /result/poll operation.
#
class DAO
  def initialize
    @store = ResultStore.new
  end

  ##
  # Call an operation with parameters.
  #
  # @param operation [String] Hierarchical operation path (e.g., "/prompt/generate")
  # @param params [Hash] Operation-specific parameters
  # @return [Hash] Operation response with :id, :status, and optional :result or :error
  #
  def call(operation, params = {})
    # Special case: /result/poll retrieves existing result
    if operation == '/result/poll'
      poll_id = params['id'] || params[:id]
      raise ArgumentError, 'Missing required parameter: id' if poll_id.nil?

      stored = @store.get(poll_id)
      return { error: "Result not found or expired: #{poll_id}" } if stored.nil?

      return stored
    end

    # Generate correlation UUID
    id = SecureRandom.uuid

    # Route to operation handler
    begin
      result = route_operation(operation, params)

      # Special case: /usage/track completes synchronously
      if operation == '/usage/track'
        completed_response = {
          id: id,
          status: 'completed',
          result: result
        }
        @store.set(id, completed_response)
        return completed_response
      end

      # Standard async pattern: store completed result, return pending
      completed_response = {
        id: id,
        status: 'completed',
        result: result
      }
      @store.set(id, completed_response)

      # Return initial pending response (async pattern)
      {
        id: id,
        status: 'pending'
      }

    rescue StandardError => e
      # Store failed result and return error
      failed_response = {
        id: id,
        status: 'failed',
        error: e.message
      }
      @store.set(id, failed_response)

      { error: e.message }
    end
  end

  private

  ##
  # Route operation to appropriate handler.
  #
  # @param operation [String] Operation path
  # @param params [Hash] Operation parameters
  # @return [Hash] Operation result
  # @raise [ArgumentError] If operation is unknown
  #
  def route_operation(operation, params)
    case operation
    when '/prompt/generate'
      Operations.process_prompt(params)
    when '/template/create'
      Operations.create_template(params)
    when '/template/render'
      Operations.render_template(params)
    when '/usage/track'
      Operations.track_usage(params)
    else
      raise ArgumentError, "Invalid operation: #{operation}"
    end
  end
end
