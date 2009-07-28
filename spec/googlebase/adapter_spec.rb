require File.dirname(__FILE__) + '/../spec_helper'
require 'dm-types'

describe GoogleBase::Adapter do

  before(:each) do
    FakeWeb.register_uri(:post, 'https://www.google.com:443/accounts/ClientLogin',
      :response => http_response(<<-CONTENT.margin))
        SID=#{'x' * 182}
        LSID=#{'y' * 182}
        Auth=#{'z' * 182}
      CONTENT

    @adapter = DataMapper.setup(:default, :adapter => :google_base, :user => 'carl', :password => 'secret')
    @repository = DataMapper.repository(@adapter.name)

    @url = 'http://www.google.com:80/base/feeds/items/123456789'

    Object.const_defined?(:Item).should be_false

    class ::Item
      include DataMapper::Resource
      property :id, String, :key => true, :field => 'xmlns:id', :nullable => true
    end
  end

  after(:each) do
    DataMapper::Model.descendants.delete(Item)
    Object.send(:remove_const, :Item)
  end

  describe "setup" do
    before(:each) do
      @config = { :adapter => :google_base, :user => 'carl', :password => 'secret' }
    end

    it "accepts dry_run" do
      adapter = DataMapper.setup(:default, @config.merge(:dry_run => true))
      adapter.dry_run.should == true
    end
  end

  describe 'authenticating' do

    # TODO ensure user and password are used

    it "authenticates before the first request" do
      FakeWeb.register_uri(:get, @url, :string => xml_entry(options))
      Item.get(@url).id
      @adapter.token.should == 'z' * 182
    end

  end

  shared_examples_for 'parsing an xml entry' do

    before(:each) do
      raise 'do_read_one undefined' unless defined?(:do_read_one)
      raise 'stub_get undefined' unless defined?(:stub_get)
    end

    it "parses the id" do
      @url = 'http://www.google.com/base/feeds/items/1337'
      stub_get('id' => @url)
      do_read_one.id.should == @url
    end

    it "parses an element via :field" do
      Item.property :title, String, :field => 'xmlns:title'
      stub_get('title' => 'Product Title')
      do_read_one.title.should == 'Product Title'
    end

    it "parses an element via :from_xml string" do
      Item.property :alternate_link, URI, :from_xml => "xmlns:link[@rel='alternate']/@href"
      stub_get('alternate_link' => 'http://example.com/products/123')
      do_read_one.alternate_link.should == Addressable::URI.parse('http://example.com/products/123')
    end

    it "parses an element via :from_xml proc" do
      Item.property :alternate_link, URI, :from_xml => lambda { |entry| entry.at("./xmlns:link[@rel='alternate']")['href'] }
      stub_get('alternate_link' => 'http://example.com/products/123')
      do_read_one.alternate_link.should == Addressable::URI.parse('http://example.com/products/123')
    end

    it "parses and typecasts a date via :from_xml string" do
      Item.property :published, DateTime, :from_xml => "xmlns:published"
      stub_get('published' => '2008-06-12T02:47:04.000Z')
      do_read_one.published.should == DateTime.civil(2008, 6, 12, 2, 47, 4)
    end

    it "parses a nested element via :from_xml string" do
      Item.property :author_name, String, :from_xml => 'xmlns:author/xmlns:name'
      stub_get('author_name' => 'Carl Porth')
      do_read_one.author_name.should == 'Carl Porth'
    end

    it "parses a g: namespaced element via :field" do
      Item.property :condition, String, :field => 'g:condition'
      stub_get('g:condition' => 'used')
      do_read_one.condition.should == 'used'
    end

    it "parses a g: namespace and typecasts via :field" do
      Item.property :customer_id, Integer, :field => 'g:customer_id'
      stub_get('g:customer_id' => '1234')
      do_read_one.customer_id.should == 1234
    end
  end

  describe "read one" do

    def do_read_one
      Item.get(@url)
    end

    def stub_get(options = {})
      FakeWeb.register_uri(:get, @url, :string => xml_entry(options))
    end

    it_should_behave_like 'parsing an xml entry'

  end

  describe "read many" do

    it 'reads each entry of the feed' do
      FakeWeb.register_uri(:get,
        'http://www.google.com/base/feeds/items?start-index=1&max-results=250',
        :string => xml_feed(Array.new(3) { xml_entry })
      )

      Item.all.length.should == 3
    end

    it 'makes multiple requests when necessary' do
      options = { :total => 501 }

      # entries 1..250
      FakeWeb.register_uri(:get,
        'http://www.google.com/base/feeds/items?start-index=1&max-results=250',
        :string => xml_feed(Array.new(250) { xml_entry }, options)
      )

      # entries 251..500
      FakeWeb.register_uri(:get,
        'http://www.google.com/base/feeds/items?start-index=251&max-results=250',
        :string => xml_feed(Array.new(250) { xml_entry }, options.merge(:start => 251))
      )

      # entry 501
      FakeWeb.register_uri(:get,
        'http://www.google.com/base/feeds/items?start-index=501&max-results=250',
        :string => xml_feed(Array.new(1) { xml_entry }, options.merge(:start => 501))
      )

      Item.all.length.should == 501
    end

    it 'obeys offset and limit' do
      FakeWeb.register_uri(:get,
        'http://www.google.com/base/feeds/items?start-index=2&max-results=10',
        :string => xml_feed((1..10).map { xml_entry }, { :start => 2, :per_page => 10, :total => 20 })
      )

      Item.all(:offset => 1, :limit => 10).length.should == 10
    end

    describe "parsing" do

      def do_read_one
        Item.all.first
      end

      def stub_get(options = {})
        FakeWeb.register_uri(:get,
          'http://www.google.com/base/feeds/items?start-index=1&max-results=1',
          :string => xml_feed([ xml_entry(options) ])
        )
      end

      it_should_behave_like 'parsing an xml entry'

    end

  end

  describe "building xml" do

    def build_xml(options = {})
      item = Item.new(options)

      doc = Nokogiri::XML.parse(@adapter.build_xml(item))
      doc.at('./xmlns:entry')
    end

    it "sets namespaces" do
      xml = build_xml

      xml.namespaces['xmlns'].should    == 'http://www.w3.org/2005/Atom'
      xml.namespaces['xmlns:g'].should  == 'http://base.google.com/ns/1.0'
      xml.namespaces['xmlns:gd'].should == 'http://schemas.google.com/g/2005'
    end

    it "builds an element" do
      Item.property :some_field, String
      xml = build_xml(:some_field => 'value')

      xml.at('some_field').content.should == 'value'
    end

    it "builds an element via :field" do
      Item.property :some_field, String, :field => 'another_name'
      xml = build_xml(:some_field => 'value')

      xml.at('another_name').content.should == 'value'
    end

    it "builds an element via :to_xml" do
      Item.property :some_link, String,
        :to_xml => lambda { |xml, value| xml.tag! 'some_link_here', :href => value, :type => 'text/html', :rel => 'alternate' }
      xml = build_xml :some_link => 'http://example.com/something'

      xml.at('some_link_here')['href'].should == 'http://example.com/something'
      xml.at('some_link_here')['rel'].should  == 'alternate'
      xml.at('some_link_here')['type'].should == 'text/html'
    end

    it "doesn't build an element with :to_xml => false" do
      Item.property :ignore_me, String, :to_xml => false
      xml = build_xml :ignore_me => 'Hai'

      xml.to_s.should_not match(/ignore_me/)
      xml.to_s.should_not match(/Hai/)
    end
  end

  describe "create" do

    before(:each) do
      @response = GData::HTTP::Response.new
      @response.status_code = 201
      @matching_xml = /<title>hai<\/title>/
    end

    def do_create
      Item.property :title, String
      item = Item.new(:title => 'hai')
      item.save.should be_true
    end

    it "creates a resource" do
      @adapter.gb.should_receive(:post).with("http://www.google.com/base/feeds/items", @matching_xml).and_return(@response)

      do_create
    end

    it "creates a resource with dry run" do
      @adapter.gb.should_receive(:post).with("http://www.google.com/base/feeds/items?dry-run=true", @matching_xml).and_return(@response)
      @adapter.dry_run = true

      do_create
    end

  end

  describe "update" do

    before(:each) do
      Item.property :title, String

      get_response = GData::HTTP::Response.new
      get_response.status_code = 200
      get_response.body = xml_entry('title' => 'foo', 'id' => 'http://www.google.com/base/feeds/items/123456789')

      @adapter.gb.stub(:get).and_return(get_response)

      @put_response = GData::HTTP::Response.new
      @put_response.status_code = 200
    end

    def do_update
      item = Item.get(1)
      item.title = 'bar'
      item.save
    end

    it "updates a resource" do
      @adapter.gb.should_receive(:put).with("http://www.google.com/base/feeds/items/123456789", /<title>bar<\/title>/).and_return(@put_response)

      do_update
    end

    it "updates a resource with dry run" do
      @adapter.gb.should_receive(:put).with("http://www.google.com/base/feeds/items/123456789?dry-run=true", /<title>bar<\/title>/).and_return(@put_response)
      @adapter.dry_run = true

      do_update
    end
  end

  describe "delete" do

    before(:each) do
      get_response = GData::HTTP::Response.new
      get_response.status_code = 200
      get_response.body = xml_entry('id' => 'http://www.google.com/base/feeds/items/123456789')

      @adapter.gb.stub(:get).and_return(get_response)

      @delete_response = GData::HTTP::Response.new
      @delete_response.status_code = 200
    end

    def do_delete
      Item.get(1).destroy
    end

    it "deletes a resource" do
      @adapter.gb.should_receive(:delete).with("http://www.google.com/base/feeds/items/123456789").and_return(@delete_response)

      do_delete
    end

    it "deletes a resource with dry run" do
      @adapter.gb.should_receive(:delete).with("http://www.google.com/base/feeds/items/123456789?dry-run=true").and_return(@delete_response)
      @adapter.dry_run = true

      do_delete
    end

  end

end
