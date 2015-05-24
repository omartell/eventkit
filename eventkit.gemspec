# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = 'eventkit'
  spec.version       = '1.0'
  spec.authors       = ['Oliver Martell']
  spec.email         = ['oliver.martell@gmail.com']
  spec.summary       = 'Experimental toolkit for asynchronous event driven applications'
  spec.description   = 'An Event Loop, a Promises A+ library, and more...'
  spec.homepage      = 'http://github.com/omartell/eventkit'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.2.0'
  spec.add_development_dependency 'pry', '~> 0.10.1'
  spec.add_development_dependency 'pry-doc', '~> 0.6.0'
  spec.add_development_dependency 'method_source', '~> 0.8.2'

  spec.add_runtime_dependency 'eventkit-promise', '~> 1.0'
  spec.add_runtime_dependency 'eventkit-eventloop', '~> 0.1.0'
end
