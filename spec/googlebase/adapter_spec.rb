require File.dirname(__FILE__) + '/../spec_helper'
require 'googlebase/adapter'
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
      property :id, String, :key => true, :field => 'xmlns:id/text()'
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

    it "parses an atom title" do
      Item.property :title, String, :field => 'xmlns:title/text()'
      stub_get('title' => 'Product Title')
      do_read_one.title.should == 'Product Title'
    end

    it "parses an atom content" do
      Item.property :description, String, :field => 'xmlns:content/text()'
      stub_get('content' => 'The Product Description')
      do_read_one.description.should == 'The Product Description'
    end

    it "parses an atom link" do
      Item.property :alternate_link, URI, :field => "xmlns:link[@rel='alternate']/@href"
      stub_get('alternate_link' => 'http://example.com/products/123')
      do_read_one.alternate_link.should == Addressable::URI.parse('http://example.com/products/123')
    end

    it "parses an atom date" do
      Item.property :published, DateTime, :field => "xmlns:published/text()"
      stub_get('published' => '2008-06-12T02:47:04.000Z')
      do_read_one.published.should == DateTime.civil(2008, 6, 12, 2, 47, 4)
    end

    it "parses an atom author name" do
      Item.property :author_name, String, :field => 'xmlns:author/xmlns:name/text()'
      stub_get('author_name' => 'Carl Porth')
      do_read_one.author_name.should == 'Carl Porth'
    end

    it "parses a g: namespace" do
      Item.property :condition, String, :field => 'g:condition/text()'
      stub_get('g:condition' => 'used')
      do_read_one.condition.should == 'used'
    end

    it "parses a g: namespace and typecasts" do
      Item.property :customer_id, Integer, :field => 'g:customer_id/text()'
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

    it "sets atom title" do
      Item.property :title, String, :xml => lambda { |xml, value| xml.title value, :type => 'text' }
      xml = build_xml :title => 'Hai'

      xml.at('title').content.should == 'Hai'
      xml.at('title')['type'].should == 'text'
    end

    it "sets atom alternate link" do
      Item.property :link, URI, :xml => lambda { |xml, value| xml.link :href => value, :type => 'text/html', :rel => 'alternate' }
      xml = build_xml :link => 'http://example.com/products/123'

      xml.at('link')['href'].should == 'http://example.com/products/123'
      xml.at('link')['rel'].should  == 'alternate'
      xml.at('link')['type'].should == 'text/html'
    end

    it "sets atom content" do
      Item.property :description, String, :xml => lambda { |xml, value| xml.content value, :type => 'html' }
      xml = build_xml :description => 'About me'

      xml.at('content').content.should == 'About me'
      xml.at('content')['type'].should == 'html'
    end

    it "sets a g: namespace" do
      Item.property :g_id, String, :xml => lambda { |xml, value| xml.tag! 'g:id', value, :type => 'text' }
      xml = build_xml :g_id => '123'

      xml.at('./g:id').content.should == '123'
      xml.at('./g:id')['type'].should == 'text'
    end

    it "doesn't set with :xml => false" do
      Item.property :updated_at, DateTime, :xml => false
      xml = build_xml :updated_at => DateTime.now

      xml.to_s.should_not match(/updated/)
    end

    it "sets multiple tags" do
      Item.property :payment_accepted, String, :xml => lambda { |xml, values| values.split(',').each { |value| xml.tag! 'g:payment_accepted', value, :type => 'text' } }
      xml = build_xml :payment_accepted => 'Visa,MasterCard,American Express,Discover'

      xml.at('./g:payment_accepted[1]').content.should == 'Visa'
      xml.at('./g:payment_accepted[1]')['type'].should == 'text'
      xml.at('./g:payment_accepted[2]').content.should == 'MasterCard'
      xml.at('./g:payment_accepted[2]')['type'].should == 'text'
      xml.at('./g:payment_accepted[3]').content.should == 'American Express'
      xml.at('./g:payment_accepted[3]')['type'].should == 'text'
      xml.at('./g:payment_accepted[4]').content.should == 'Discover'
      xml.at('./g:payment_accepted[4]')['type'].should == 'text'
    end
  end
end
