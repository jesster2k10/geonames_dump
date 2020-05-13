# frozen_string_literal: true

require File.expand_path('lib/geonames_dump/version', __dir__)

Gem::Specification.new do |gem|
  gem.authors       = ['Alex Pooley', 'Thomas Kienlen']
  gem.email         = ['thomas.kienlen@lafourmi-immo.com']
  gem.description   = 'GeonamesDump import geographic data from geonames project into your application, avoiding to use external service like Google Maps.'
  gem.summary       = 'Import data from Geonames'
  gem.homepage      = 'https://github.com/kmmndr/geonames_dump'

  gem.files         = `git ls-files`.split($OUTPUT_RECORD_SEPARATOR)
  gem.executables   = gem.files.grep(%r{^bin/}).map { |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = 'geonames_dump'
  gem.require_paths = ['lib']
  gem.version       = GeonamesDump::VERSION

  gem.add_runtime_dependency 'activerecord-reset-pk-sequence'
  gem.add_runtime_dependency 'ruby-progressbar'
  gem.add_runtime_dependency 'rubyzip', '> 1.0.0'
end
