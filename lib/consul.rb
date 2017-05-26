require 'excon'

module Doremi

  # This is a namespace for Consul specific implementation.
  module Consul

    # Service registration command.
    class Register

      # Constructor.
      def initialize(docker_info, url='http://localhost:8500')
        @reg = {}
        @reg[:ID] = docker_info['id']
        @reg[:Name] = docker_info['Config']['Labels']['com.docker.compose.service']
        @reg[:Address] = "127.0.0.1"
        @reg[:Port] = docker_info['NetworkSettings']['Ports'].values[0][0]['HostPort'].to_i

        @url = url
      end

      # Adds a new service, with an optional health check, to the agent.
      def exec
        Excon.put("#{@url}/v1/agent/service/register",
            body: @reg.to_json,
            headers: {'Content-Type' => 'application/json'})
      end

      def to_s
        @reg.to_s
      end

      def to_json
        @reg.to_json
      end

    end

    # Service deregistration command.
    class Deregister

      # Constructor.
      def initialize(docker_event, url='http://localhost:8500')
        @cid = docker_event.id
        @url = url
      end

      # Removes a service from the agent.
      def exec
        Excon.put("#{@url}/v1/agent/service/deregister/#{@cid}",
            headers: {'Content-Type' => 'application/json'})
      end

      def to_s
        @cid
      end

    end

  end

end
