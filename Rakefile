require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "dm-googlebase"
    gem.summary = %Q{A DataMapper adapter for Google Base}
    gem.email = "badcarl@gmail.com"
    gem.homepage = "http://github.com/badcarl/dm-googlebase"
    gem.authors = ["Carl Porth"]
    gem.add_dependency 'dm-core',        '~> 0.10.2'
    gem.add_dependency 'dm-types',       '~> 0.10.2'
    gem.add_dependency 'dm-validations', '~> 0.10.2'
    gem.add_dependency 'gdata'
    gem.add_dependency 'nokogiri'
    gem.add_development_dependency 'dm-sweatshop', '~> 0.10.0'
    gem.add_development_dependency 'fakeweb', '~> 1.2.8'
  end

  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: sudo gem install jeweler"
end

require 'spec/rake/spectask'
Spec::Rake::SpecTask.new(:spec) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.spec_files = FileList['spec/**/*_spec.rb']
end

Spec::Rake::SpecTask.new(:rcov) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

task :spec => :check_dependencies

task :default => :spec

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  if File.exist?('VERSION.yml')
    config = YAML.load(File.read('VERSION.yml'))
    version = "#{config[:major]}.#{config[:minor]}.#{config[:patch]}"
  else
    version = ""
  end

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "dm-googlebase #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
