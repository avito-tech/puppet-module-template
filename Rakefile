require 'metadata-json-lint/rake_task'
require 'puppetlabs_spec_helper/rake_tasks'
require 'puppet-strings'
require 'puppet-strings/tasks'
require 'puppet-syntax/tasks/puppet-syntax'
require 'puppet_blacksmith/rake_tasks' if Bundler.rubygems.find_name('puppet-blacksmith').any?
require 'github_changelog_generator/task' if Bundler.rubygems.find_name('github_changelog_generator').any?

MetadataJsonLint.options[:strict_license] = false
PuppetLint.configuration.send('disable_unquoted_node_name')

namespace :strings do
  desc 'Generate REFERENCE.md with puppet-strings'
  task :reference do
    patterns = PuppetStrings::DEFAULT_SEARCH_PATTERNS
    options = {
      markdown: true,
      path: 'REFERENCE.md',
    }
    PuppetStrings.generate(patterns, options)
  end
end

# extends syntax:hiera target
namespace :syntax do
  task :hiera do
    unless Dir.glob('data/**/*.yml').empty?
      puts('Found *.yml files in data directory. Only *.yaml files are accepted by hiera.')
      exit(1)
    end
  end
end

namespace :check do
  task :git_tags do
    tags = `git tag -l`.split()
    module_version = JSON.parse(File.read('metadata.json'))['version']
    unless tags.include? module_version
      puts("Missing git tag for module version #{module_version}")
      exit(1)
    end
  end
end

def changelog_user
  return unless Rake.application.top_level_tasks.include? "changelog"
  returnVal = nil || JSON.load(File.read('metadata.json'))['author']
  raise "unable to find the changelog_user in .sync.yml, or the author in metadata.json" if returnVal.nil?
  puts "GitHubChangelogGenerator user:#{returnVal}"
  returnVal
end

def changelog_project
  return unless Rake.application.top_level_tasks.include? "changelog"
  returnVal = nil || JSON.load(File.read('metadata.json'))['name']
  raise "unable to find the changelog_project in .sync.yml or the name in metadata.json" if returnVal.nil?
  puts "GitHubChangelogGenerator project:#{returnVal}"
  returnVal
end

def changelog_future_release
  return unless Rake.application.top_level_tasks.include? "changelog"
  returnVal = JSON.load(File.read('metadata.json'))['version']
  raise "unable to find the future_release (version) in metadata.json" if returnVal.nil?
  puts "GitHubChangelogGenerator future_release:#{returnVal}"
  returnVal
end

PuppetLint.configuration.send('disable_relative')

