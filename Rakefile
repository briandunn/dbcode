require 'bundler'
require 'rspec/core/rake_task'
Bundler::GemHelper.install_tasks

RSpec::Core::RakeTask.new :spec do |spec|
  spec.verbose = false
  spec.pattern = FileList['spec/**/*_spec.rb']
end

task default: :spec
