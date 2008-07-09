# For easy merb compatability, just alias the logger.
RAILS_DEFAULT_LOGGER = Merb.logger unless defined?(RAILS_DEFAULT_LOGGER)

require 'async_observer/extend'
