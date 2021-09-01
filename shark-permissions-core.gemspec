# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'shark/version'

Gem::Specification.new do |spec|
  spec.name = 'shark-permissions-core'
  spec.version = Shark::Permissions::Core::VERSION
  spec.authors = ['Joergen Dahlke']
  spec.email = ['joergen.dahlke@gmail.com']

  spec.summary = 'Core classes for Shark permissions'
  spec.description = 'Basic functionality to work with shark permissions'
  spec.homepage = 'https://github.com/jdahlke/shark-permissions-core'
  spec.license = 'MIT'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/jdahlke/shark-permissions-core'
  spec.metadata['changelog_uri'] = 'https://github.com/jdahlke/shark-permissions-core/blob/develop/CHANGELOG.md'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(.github|bin|spec)/}) }
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']
  spec.required_ruby_version = '>= 2.3'

  spec.add_dependency 'activesupport'

  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec', '~> 3.9.0'
  spec.add_development_dependency 'rubocop', '0.81.0'
end
