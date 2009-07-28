# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{dm-googlebase}
  s.version = "0.0.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Carl Porth"]
  s.date = %q{2009-07-27}
  s.email = %q{badcarl@gmail.com}
  s.extra_rdoc_files = [
    "LICENSE",
     "README.rdoc"
  ]
  s.files = [
    ".document",
     ".gitignore",
     "LICENSE",
     "README.rdoc",
     "Rakefile",
     "VERSION",
     "dm-googlebase.gemspec",
     "lib/googlebase.rb",
     "lib/googlebase/adapter.rb",
     "lib/googlebase/product.rb",
     "spec/googlebase/adapter_spec.rb",
     "spec/googlebase/product_spec.rb",
     "spec/spec_helper.rb",
     "spec/spec_matchers.rb",
     "spec/xml_helpers.rb"
  ]
  s.homepage = %q{http://github.com/badcarl/dm-googlebase}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.3}
  s.summary = %q{A DataMapper adapter for Google Base}
  s.test_files = [
    "spec/googlebase/adapter_spec.rb",
     "spec/googlebase/product_spec.rb",
     "spec/spec_helper.rb",
     "spec/spec_matchers.rb",
     "spec/xml_helpers.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<dm-core>, [">= 0.10.0"])
      s.add_runtime_dependency(%q<dm-types>, [">= 0.10.0"])
      s.add_runtime_dependency(%q<dm-validations>, [">= 0.10.0"])
      s.add_runtime_dependency(%q<gdata>, [">= 0"])
      s.add_runtime_dependency(%q<nokogiri>, [">= 0"])
      s.add_runtime_dependency(%q<builder>, [">= 0"])
      s.add_development_dependency(%q<dm-sweatshop>, [">= 0.10.0"])
    else
      s.add_dependency(%q<dm-core>, [">= 0.10.0"])
      s.add_dependency(%q<dm-types>, [">= 0.10.0"])
      s.add_dependency(%q<dm-validations>, [">= 0.10.0"])
      s.add_dependency(%q<gdata>, [">= 0"])
      s.add_dependency(%q<nokogiri>, [">= 0"])
      s.add_dependency(%q<builder>, [">= 0"])
      s.add_dependency(%q<dm-sweatshop>, [">= 0.10.0"])
    end
  else
    s.add_dependency(%q<dm-core>, [">= 0.10.0"])
    s.add_dependency(%q<dm-types>, [">= 0.10.0"])
    s.add_dependency(%q<dm-validations>, [">= 0.10.0"])
    s.add_dependency(%q<gdata>, [">= 0"])
    s.add_dependency(%q<nokogiri>, [">= 0"])
    s.add_dependency(%q<builder>, [">= 0"])
    s.add_dependency(%q<dm-sweatshop>, [">= 0.10.0"])
  end
end
