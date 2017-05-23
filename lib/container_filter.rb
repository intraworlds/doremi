module Doremi

  # This class represents an extractor to filter events.
  # Only container based start/stop events remains in game.
  class ContainerFilter
    include Doremi::Utils

    def exec(event)
      return event if event.type == 'container' and (event.status == 'stop' or event.status == 'start')
      nil
    end
  end

end
