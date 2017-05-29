require 'excon'

module Doremi

  # This is a namespace for Consul specific implementation.
  module Consul

    # Service registration command.
    class Register

      attr_reader :params

      # Constructor.
      def initialize(name, url='http://localhost:8500')
        @params = { :Name => name }
        @url = url
      end

      # Adds a new service, with an optional health check, to the agent.
      def exec
        Excon.put("#{@url}/v1/agent/service/register",
            body: @params.to_json,
            headers: {'Content-Type' => 'application/json'})
      end

      def to_s
        @params.to_s
      end

      def to_json
        @params.to_json
      end

    end

    # Service deregistration command.
    class Deregister

      # Constructor.
      def initialize(docker_id, url='http://localhost:8500')
        @did = docker_id
        @url = url
      end

      # Removes a service from the agent.
      def exec
        Excon.put("#{@url}/v1/agent/service/deregister/#{@did}",
            headers: {'Content-Type' => 'application/json'})
      end

      def to_s
        @did
      end

    end

  end

end
