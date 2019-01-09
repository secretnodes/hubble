BASE_PATH = '/hubble/app'
CURRENT = File.join(BASE_PATH, 'current')

run_task = "NO_PROGRESS=1 /usr/bin/nice -n 10 bin/rake :task --silent :output"
abort_task = 'echo "Not running, release is old."'

def log_path( name )
  File.join( BASE_PATH, 'shared/log', name+'.log' )
end

job_type :rake, [
  'cd :path', 'source ~/.env', 'sleep :sleep',
  %{ [ $(pwd) = $(readlink "#{CURRENT}") ] && #{run_task} || #{abort_task} }
].join( ' && ' )

every '* * * * *' do
  rake 'sync:cosmos:all alerts:users:instant', sleep: 0, output: log_path('main-sync')
  rake 'sync:cosmos:all alerts:users:instant', sleep: 30, output: log_path('main-sync')

  # Faucet is a WIP
  # rake 'faucet:cosmos:send', sleep: 0, output: log_path('faucet')
  # rake 'faucet:cosmos:send', sleep: 15, output: log_path('faucet')
  # rake 'faucet:cosmos:send', sleep: 30, output: log_path('faucet')
  # rake 'faucet:cosmos:send', sleep: 45, output: log_path('faucet')
end

every '3 * * * *' do
  rake 'stats:cosmos:all', sleep: 0, output: log_path('stats')
end

every '5 0 * * *' do
  rake 'common:clean_daily_sync_logs alerts:users:daily', sleep: 0, output: log_path('clean-logs')
end
