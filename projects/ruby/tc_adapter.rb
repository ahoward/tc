#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'
require_relative 'lib/dao'

##
# TC Adapter for Ruby DAO implementation.
#
# Contract:
# - Read JSON from stdin: {operation: String, params: Object}
# - Write JSON to stdout: {id: UUID, status: String, result?: Object, error?: String}
# - Exit 0 for success (even if operation failed)
# - Exit non-zero only for fatal adapter errors
#
begin
  # Read and parse input JSON from stdin
  input_json = $stdin.read
  input = JSON.parse(input_json)

  # Extract operation and params
  operation = input['operation']
  params = input['params'] || {}

  # Create DAO instance and call operation
  dao = DAO.new
  response = dao.call(operation, params)

  # Write response JSON to stdout
  puts JSON.generate(response)

  exit 0
rescue JSON::ParserError => e
  # Invalid JSON input - fatal adapter error
  error_response = { error: "Adapter error: Invalid JSON input - #{e.message}" }
  puts JSON.generate(error_response)
  exit 1
rescue StandardError => e
  # Unexpected adapter error
  error_response = { error: "Adapter error: #{e.message}" }
  puts JSON.generate(error_response)
  exit 1
end
