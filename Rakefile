require 'rubygems'
require 'rake'

namespace :test do
  desc 'Measure test coverage'
  task :coverage do
    rm_f "coverage"
    rcov = "rcov --text-summary --test-unit-only -Ilib"
    system("#{rcov} --no-html --no-color test/*_test.rb")
  end
  desc 'Run tests'
  task :all do
    system "ruby test/*_test.rb"
  end
end
