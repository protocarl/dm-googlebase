require 'spec'
require 'rubygems'
require 'fakeweb'

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'xml_helpers'
require 'spec_matchers'

Spec::Runner.configure do |config|

  config.include(XmlHelpers)

  config.before(:all) do
    FakeWeb.allow_net_connect = false
  end

  config.before(:each) do
    FakeWeb.clean_registry
  end

  config.after(:each) do
    DataMapper::Model.descendants.to_a.should == []
  end

end
