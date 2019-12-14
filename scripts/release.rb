#!/usr/bin/env ruby

# -- helpers ------------------------------------------------------------------

def sys(cmd)
  STDERR.puts "> #{cmd}"
  system cmd
  return true if $?.success?

  STDERR.puts "> #{cmd} returned with exitstatus #{$?.exitstatus}"
  $?.success?
end

def sys!(cmd, error: nil)
  return true if sys(cmd)
  STDERR.puts error if error
  exit 1
end

def die!(msg)
  STDERR.puts msg
  exit 1
end

ROOT = File.expand_path("#{File.dirname(__FILE__)}/..")

GEMSPEC = Dir.glob("*.gemspec").first || die!("Missing gemspec file.")

# -- Version reading and bumping ----------------------------------------------

module Version
  extend self

  VERSION_FILE = "#{Dir.getwd}/VERSION"

  def read_version
    version = File.exist?(VERSION_FILE) ? File.read(VERSION_FILE) : "0.0.1"
    version.chomp!
    raise "Invalid version number in #{VERSION_FILE}" unless version =~ /^\d+\.\d+\.\d+$/
    version
  end

  def auto_version_bump
    old_version_number = read_version
    old = old_version_number.split('.')

    current = old[0..-2] << old[-1].next
    current.join('.')
  end

  def bump_version
    next_version = ENV["VERSION"] || auto_version_bump
    File.open(VERSION_FILE, "w") { |io| io.write next_version }
  end
end

# -- check, bump, release a new gem version -----------------------------------

Dir.chdir ROOT
$BASE_BRANCH = ENV['BRANCH'] || 'master'

# ENV["BUNDLE_GEMFILE"] = "#{Dir.getwd}/Gemfile"
# sys! "bundle install"

sys! "git diff --exit-code > /dev/null", error: 'There are unstaged changes in your working directory'
sys! "git diff --cached --exit-code > /dev/null", error: 'There are staged but uncommitted changes'

sys! "git checkout #{$BASE_BRANCH}"
sys! "git pull"

Version.bump_version
version = Version.read_version

sys! "git add VERSION"
sys! "git commit -m \"bump gem to v#{version}\""
sys! "git tag -a v#{version} -m \"Tag #{version}\""

sys! "gem build #{GEMSPEC}"

sys! "git push origin #{$BASE_BRANCH}"
sys! 'git push --tags --force'

sys! "bundle exec fury push #{Dir.glob('*.gem').first} --as mediapeers"

sys! "mkdir -p pkg"
sys! "mv *.gem pkg"

STDERR.puts <<-MSG
================================================================================
Thank you for releasing a new gem version. You made my day.
================================================================================
    MSG
