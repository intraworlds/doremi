require 'singleton'
require 'logger'
require 'docker'

# This module represents namespace of the tool.
module Doremi

  # Version history.
  VERSION_HISTORY = [
    ['0.0.1',   '2017-05-23', "Initial revision"]
  ]
  # Current version.
  VERSION = VERSION_HISTORY[0][0]

  # Central logger.
  class << self
    attr_accessor :logger
  end

  autoload :ContainerFilter,   'container_filter'
  # autoload :PngLoader,         'png_loader'

  # You know: utilities...
  module Utils

    # Makes available the properly configured log for any client.
    def log
      log = Doremi::logger
      log.progname = self.class.name.split('::').last || ''
      log
    end

    # Gets a context for the process based on thread local variable.
    def context
      Thread.current[:ctx] ||= {}
    end

  end


  # This class represents the main application class and entry point.
  class App
    include ::Singleton
    include Utils

    # Service Locator.
    def service(key, with = nil)
      @services ||= {}

      return @services[key.to_sym] if with.nil? # getter

      if with.is_a? Class
        @services[key.to_sym] = with.new # setter via constructor
      else
        @services[key.to_sym] = with # setter via object
      end
      log.debug "added service '#{key}'"
    end

    # Initializes all services that the engine depends on.
    def build(&block)
        # provide access to 'this' in configuration block
        self.instance_exec(&block)
    end

    # Runs the application.
    # This method represents a template method for the process.
    def run
      log.info "starting..., version=#{VERSION}, pid=#{Process.pid}"
      trap('INT')  { shutdown }
      trap('TERM')  { shutdown }

      # preconditions
      raise 'ETL not fully initialized' if service(:extract).nil? #or service(:transfer).nil? or service(:load).nil?

      Docker::Event.stream do |event|
        Thread.new do
          etl(event)
        end
      end
    end

    # Runs the ETL process.
    def etl(event)
      log.debug "starting ETL..., type=#{event.type}, status=#{event.status}"
      input = event
      [:extract].each do |step|
    #   [:extract, :transform, :load].each do |step|
        input = service(step).exec(input)
        break if input.nil?
      end
    end

    # Shutdowns the application gracefully.
    def shutdown
      STDERR.puts '' # just new line after '^C'
      STDERR.puts 'Bye bye'
      Docker.reset!
      exit
    end
  end

end

#####################
# --== Bootstrap ==--

if ARGV[0] == '--run'

  Doremi::logger = Logger.new(STDOUT)
  Doremi::logger.level = Logger::INFO
  Doremi::logger.level = Logger::DEBUG if __FILE__ == $0 # DEVELOPMENT MODE

  Doremi::App.instance.build do
    service :extract, Doremi::ContainerFilter
    # service :sniffer,     WeatherTS::IndexSniffer
    # service :filter,      WeatherTS::DbFilter
  end

  Doremi::App.instance.run
end
