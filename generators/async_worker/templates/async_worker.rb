# Run with: merb -a runner -r this_script

# Use the same pointer (and therefore same buffer) for stdout and stderr.
$VERBOSE = nil; STDERR = $stderr = STDOUT = $stdout; $VERBOSE = false

require 'time'
require 'async_observer/worker'
AsyncObserver::Worker.new(binding).run()
