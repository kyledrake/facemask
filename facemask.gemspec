Gem::Specification.new do |s|
  s.name        = "facemask"
  s.version     = "1.0.1"
  s.authors     = ['Kyle Drake']
  s.email       = "kyle@stepchangegroup.com"
  s.homepage    = "http://stepchangegroup.com"
  s.summary     = "Lightweight adapter for Facebook API with hacks to improve reliability."
  s.description = "Lightweight adapter for Facebook API with hacks to improve reliability. Based on ideas from MiniFB."
  
  s.files        = Dir["{lib,test}/**/*"] + Dir["[A-Z]*"]
  s.require_path = "lib"
  
  s.rubyforge_project = s.name
  s.required_rubygems_version = ">= 1.3.4"
end
