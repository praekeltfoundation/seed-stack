require 'puppetlabs_spec_helper/rake_tasks'
require 'metadata-json-lint/rake_task'

task :librarian_spec_prep do
  sh 'librarian-puppet install --path=spec/fixtures/modules/'
end
task :spec_prep => :librarian_spec_prep

# Override puppetlabs_spec_helper's default lint settings
# * Don't want to ignore so many tests
# * Don't want to run lint on upstream modules
Rake::Task[:lint].clear
PuppetLint::RakeTask.new(:lint) do |config|
  config.fail_on_warnings = true
  config.ignore_paths = ["vendor/**/*.pp", "spec/**/*.pp", "modules/**/*.pp"]
end

# Coverage from puppetlabs_spec_helper requires rcov which doesn't work in
# anything since Ruby 1.8.7
Rake::Task[:coverage].clear

# Remove puppetlabs_spec_helper's metadata and validate tasks
Rake::Task[:validate].clear
Rake::Task[:metadata].clear

desc "Run syntax, lint, metadata and spec tests."
task :test => [
  :syntax,
  :lint,
  :metadata_lint,
  :spec,
]
