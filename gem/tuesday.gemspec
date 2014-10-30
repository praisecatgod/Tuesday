Gem::Specification.new do |s|
  s.name        = 'tuesday'
  s.version     = '0.0.6'
  s.date        = '2014-10-19'
  s.summary     = "Fast Casual DigitalOcean Deployment"
  s.description = "Deploys Rack apps to DigitalOcean with one command."
  s.authors     = ["Yves DeSousa", "Max Rogers"]
  s.email       = 'yvonne@yvds.net'
  s.files       = ["lib/tuesday.rb", "lib/kitchen"]
  s.homepage    =
    'http://tuesdayrb.me'
  s.license       = 'WTFPL'
  s.executables << 'tuesday'
  
  s.add_runtime_dependency 'mongo'
  s.add_runtime_dependency 'pg'
end
