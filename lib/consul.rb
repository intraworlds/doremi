require 'excon'

module Doremi

  # This is a namespace for Consul specific implementation.
  module Consul

    # Data container for service registration command.
    class Register

      # Constructor.
      def initialize(docker_info)
        @reg = {}
        @reg[:ID] = docker_info['id']
        @reg[:Name] = docker_info['Config']['Labels']['com.docker.compose.service']
        @reg[:Address] = "127.0.0.1"
        @reg[:Port] = docker_info['NetworkSettings']['Ports'].values[0][0]['HostPort'].to_i
      end

      def to_s
        @reg.to_s
      end

      def to_json
        @reg.to_json
      end

    end

    # Adapter for communication with Consul.
    class Adapter

      def initialize(url)
        @url = url
      end

      # Adds a new service, with an optional health check, to the agent.
      def register(reg, hcheck=nil)
        Excon.put("#{@url}/v1/agent/service/register",
            body: reg.to_json,
            headers: {'Content-Type' => 'application/json'})
      end

    end

  end

end
