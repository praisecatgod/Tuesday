
working_directory '/var/www/Tuesday'

pid '/var/www/Tuesday/pids/unicorn.pid'

stderr_path '/var/www/Tuesday/logs/unicorn.log'
stdout_path '/var/www/gitten/logs/unicorn.log'

listen '/tmp/unicorn.Tuesday.sock'

# Number of processes
# worker_processes 4
worker_processes 1

# Time-out
timeout 30



working_directory '/var/www/Tuesday'

pid '/var/www/Tuesday/pids/unicorn.pid'

stderr_path '/var/www/Tuesday/logs/unicorn.log'
stdout_path '/var/www/gitten/logs/unicorn.log'

listen '/tmp/unicorn.Tuesday.sock'

# Number of processes
# worker_processes 4
worker_processes 1

# Time-out
timeout 30


