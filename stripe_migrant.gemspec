# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'stripe_migrant/version'

Gem::Specification.new do |spec|
  spec.name          = 'stripe_migrant'
  spec.version       = StripeMigrant::VERSION
  spec.authors       = ['Andrew Conrad']
  spec.email         = ['andrew@codetree.com']

  spec.summary       = 'Automate Stripe Account Migrations'
  spec.description   = 'Automate the migration from one Stripe account to another account'
  spec.homepage      = 'https://www.github.com/codetree/stripe_migrant'
  spec.license       = 'MIT'

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  unless spec.respond_to?(:metadata)
    raise 'RubyGems 2.0 or newer is required to protect against public gem pushes.'
  end

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = spec.homepage

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'logger', '~> 1.3'
  spec.add_dependency 'stripe', '~> 4.4'

  spec.add_development_dependency 'bundler',      '~> 1.16'
  spec.add_development_dependency 'dotenv',       '~> 2.5'
  spec.add_development_dependency 'guard',        '~> 2.15'
  spec.add_development_dependency 'guard-rspec',  '~> 4.7'
  spec.add_development_dependency 'guard-rubocop', '~> 1.3'
  spec.add_development_dependency 'rake',         '~> 10.0'
  spec.add_development_dependency 'rspec',        '~> 3.0'
end
