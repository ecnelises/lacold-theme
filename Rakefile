# frozen_string_literal: true

require "rake/testtask"

Rake::TestTask.new do |task|
  task.libs << "lib"
  task.libs << "test"
  task.pattern = "test/**/*_test.rb"
end

desc "Validate palettes and generated artifacts"
task check: :test do
  ruby "bin/lacold", "check"
end

desc "Generate all theme artifacts into dist/"
task :build do
  ruby "bin/lacold", "build"
end

desc "Build the GitHub Pages site into _site/"
task :site do
  ruby "bin/lacold", "site"
end

task default: :check
