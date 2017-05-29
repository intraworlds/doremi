require 'logger'
require 'json'
require 'docker'
require 'consul'

# This module represents namespace of the tool.
module Doremi

  # Version history.
  VERSION_HISTORY = [
    ['0.0.2',   '2017-05-26', "Added Consul deregistration"],
    ['0.0.1',   '2017-05-23', "Initial revision"]
  ]
  # Current version.
  VERSION = VERSION_HISTORY[0][0]

  # Central logger.
  class << self
    attr_accessor :logger
  end

  # This class represents the main application class and entry point.
  class App

    # Just keys used in ETL processing.
    ETL = [:extract, :transform, :load]

    # Service Locator.
    def service(key, with = nil)
      @services ||= {}

      return @services[key.to_sym] if with.nil? # getter

      if with.is_a? Class
        @services[key.to_sym] = with.new # setter via constructor
      else
        @services[key.to_sym] = with # setter via object
      end
      Doremi::logger.debug "added service '#{key}'"
    end

    # Initializes all services that the engine depends on.
    def build(&block)
        # provide access to 'this' in configuration block
        self.instance_exec(&block)
    end

    # Runs the application.
    # This method represents a template method for the process.
    def run
      Doremi::logger.info "starting..., version=#{VERSION}, pid=#{Process.pid}"
      trap('INT')  { shutdown }
      trap('TERM')  { shutdown }
      Docker.options[:read_timeout] = 3600 # need to be made higher than 60 seconds if expecting a long time between events

      # preconditions
      ETL.each { |k| raise "invalid ETL, missing key=#{k}" if service(k).nil? }

      begin
        begin
          Docker::Event.stream do |event|
            Thread.new do
              begin
                etl(event)
              rescue Exception => e
                Doremi::logger.error e
              end
            end
          end
        rescue Docker::Error::TimeoutError => e
          Doremi::logger.warn "Docker connection timeout -> reconnect, msg=#{e.message}"
        rescue ::SystemExit
          break
        rescue ::Exception => e
          Doremi::logger.fatal e
          break
        end
      end while true
    end

    # Runs the ETL process.
    def etl(event)
      Doremi::logger.debug "starting ETL..., type=#{event.type}, status=#{event.status}"
      input = event
      ETL.each do |step|
        input = service(step).call(input)
        break if input.nil?
      end
    end

    # Shutdowns the application gracefully.
    def shutdown
      STDERR.puts '' # just new line after '^C'
      Docker.reset!
      abort('Bye bye')
    end
  end

end

#####################
# --== Bootstrap ==--

if ARGV[0] == '--run'

  Doremi::logger = Logger.new(STDOUT)
  Doremi::logger.level = Logger::INFO
  Doremi::logger.level = Logger::DEBUG if __FILE__ == $0 # DEVELOPMENT MODE

  extract = lambda do |event|
    if event.type == 'container' and (event.status == 'stop' or event.status == 'start')
      unless event.actor.attributes['name'] =~ /consul/ # do not register Consul in Consul
        Doremi::logger.info "container name=#{event.actor.attributes['name']}, status=#{event.status}, id=#{event.id}"
        return event
      end
    end
    nil
  end

  transform = lambda do |event|
    if event.status == 'start'
      info = Docker::Container.get(event.id).info
# puts JSON.pretty_generate(info['Config'])
      reg = Doremi::Consul::Register.new(event.id)
# @reg[:Name] = docker_info['Config']['Labels']['com.docker.compose.service']
      reg.params[:Name] = info['Config']['Image'].split('/')[1]
      reg.params[:Address] = "127.0.0.1"
      reg.params[:Port] = info['NetworkSettings']['Ports'].values[0][0]['HostPort'].to_i

      Doremi::logger.info "consul registration, data: #{reg}"
      reg
    elsif event.status == 'stop'
      dereg = Doremi::Consul::Deregister.new(event.id)
      Doremi::logger.info "consul deregistration, id=#{dereg}"
      dereg
    else
      nil
    end
  end

  load = lambda do |command|
    rslt = command.exec
    if 200 == rslt.status
      Doremi::logger.info 'command OK'
    else
      Doremi::logger.warn "command failed: #{rslt.status}, #{rslt.body}"
    end
  end

  app = Doremi::App.new
  app.build do
    service :extract,   extract
    service :transform, transform
    service :load,      load
  end
  app.run

end
