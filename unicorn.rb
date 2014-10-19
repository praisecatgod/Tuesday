
working_directory '/var/www/web'

pid '/var/www/web/pids/unicorn.pid'

stderr_path '/var/www/web/logs/unicorn.log'
stdout_path '/var/www/web/logs/unicorn.log'

listen '/tmp/unicorn.web.sock'

# Number of processes
# worker_processes 4
worker_processes 1

# Time-out
timeout 30


