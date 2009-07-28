require File.dirname(__FILE__) + '/../spec_helper'
require 'dm-sweatshop'

describe GoogleBase::Product do

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
  end

  GoogleBase::Product.fixture {{
    :title          => 'A Product',
    :description    => 'About me',
    :link           => 'http://example.com/products/123',
    :condition      => 'new',
    :product_type   => 'Electronics > Computers > Laptops',
    :image_link     => 'http://example.com/images/123.jpg',
    :product_id     => '123',
    :price          => '12.34 usd',
    :brand          => 'Brand Name',
    :item_type      => 'Products'
  }}

  describe "building xml" do
    def expected_xml(optional_lines = [])
      optional_lines = Array(optional_lines)

      <<-XML.compress_lines(false)
        <?xml version="1.0" encoding="UTF-8"?>
        <entry xmlns:g="http://base.google.com/ns/1.0" xmlns:gd="http://schemas.google.com/g/2005" xmlns="http://www.w3.org/2005/Atom">
          <title>A Product</title>
          <content>About me</content>
          <link rel="alternate" type="text/html" href="http://example.com/products/123"/>
          <g:condition>new</g:condition>
          <g:product_type>Electronics &gt; Computers &gt; Laptops</g:product_type>
          <g:image_link>http://example.com/images/123.jpg</g:image_link>
          <g:id>123</g:id>
          <g:price>12.34 usd</g:price>
          <g:brand>Brand Name</g:brand>
          <g:item_type>Products</g:item_type>
          #{optional_lines}
        </entry>
      XML
    end

    it "with required properties" do
      product = GoogleBase::Product.make

      @adapter.build_xml(product).should match_xml_document(expected_xml)
    end

    it 'with expiration date' do
      expires_at = Date.today + 7
      product = GoogleBase::Product.make(:expires_at => expires_at)
      xml = expected_xml("<g:expiration_date>#{expires_at.strftime}</g:expiration_date>")

      @adapter.build_xml(product).should match_xml_document(xml)
    end

    it "with quantity" do
      product = GoogleBase::Product.make(:quantity => 10)
      xml = expected_xml("<g:quantity>10</g:quantity>")

      @adapter.build_xml(product).should match_xml_document(xml)
    end

    it "with payment accepted" do
      product = GoogleBase::Product.make(:payment_accepted => 'Visa,MasterCard,American Express,Discover')
      xml = expected_xml([
        '<g:payment_accepted>Visa</g:payment_accepted>',
        '<g:payment_accepted>MasterCard</g:payment_accepted>',
        '<g:payment_accepted>American Express</g:payment_accepted>',
        '<g:payment_accepted>Discover</g:payment_accepted>'
      ])

      @adapter.build_xml(product).should match_xml_document(xml)
    end

    it "with item language" do
      product = GoogleBase::Product.make(:item_language => 'EN')
      xml = expected_xml('<g:item_language>EN</g:item_language>')

      @adapter.build_xml(product).should match_xml_document(xml)
    end

    it "with target country" do
      product = GoogleBase::Product.make(:target_country => 'US')
      xml = expected_xml('<g:target_country>US</g:target_country>')

      @adapter.build_xml(product).should match_xml_document(xml)
    end
  end

  it "parses xml" do
    received_xml = <<-XML.compress_lines(false)
      <?xml version="1.0" encoding="UTF-8"?>
      <entry xmlns="http://www.w3.org/2005/Atom" xmlns:gm="http://base.google.com/ns-metadata/1.0" xmlns:g="http://base.google.com/ns/1.0" xmlns:batch="http://schemas.google.com/gdata/batch" xmlns:gd="http://schemas.google.com/g/2005" gd:etag="W/&quot;D04FSX47eCp7ImA9WxJbFEo.&quot;">
        <id>http://www.google.com/base/feeds/items/123456789</id>
        <published>2009-07-24T22:51:58.000Z</published>
        <updated>2009-07-24T22:51:58.000Z</updated>
        <app:edited xmlns:app="http://www.w3.org/2007/app">2009-07-24T22:51:58.000Z</app:edited>
        <category scheme="http://base.google.com/categories/itemtypes" term="Products"/>
        <title>Product Title</title>
        <content type="html">About me</content>
        <link rel="alternate" type="text/html" href="http://example.com/products/123"/>
        <link rel="self" type="application/atom+xml" href="http://www.google.com/base/feeds/items/123456789"/>
        <link rel="edit" type="application/atom+xml" href="http://www.google.com/base/feeds/items/123456789"/>
        <author>
          <name>Author Name</name>
          <email>anon-123@base.google.com</email>
        </author>
        <g:payment type="text">American Express</g:payment>
        <g:payment type="text">Discover</g:payment>
        <g:payment type="text">Visa</g:payment>
        <g:payment type="text">MasterCard</g:payment>
        <g:condition type="text">new</g:condition>
        <g:product_type type="text">Electronics &gt; Computers &gt; Laptops</g:product_type>
        <g:image_link type="url">http://example.com/images/123.jpg</g:image_link>
        <g:item_language type="text">en</g:item_language>
        <g:id type="text">123</g:id>
        <g:price type="floatUnit">12.34 usd</g:price>
        <g:target_country type="text">US</g:target_country>
        <g:expiration_date type="dateTime">2009-08-23T22:51:58Z</g:expiration_date>
        <g:brand type="text">Brand X</g:brand>
        <g:customer_id type="int">123456789</g:customer_id>
        <g:item_type type="text">Products</g:item_type>
        <gd:feedLink rel="media" href="http://www.google.com/base/feeds/items/123456789/media" countHint="1"/>
      </entry>
    XML

    FakeWeb.register_uri(:get, @url, :string => received_xml)
    item = GoogleBase::Product.get(@url)

    item.id.should               == 'http://www.google.com/base/feeds/items/123456789'
    item.created_at.should       == DateTime.civil(2009,7,24,22,51,58)
    item.updated_at.should       == DateTime.civil(2009,7,24,22,51,58)
    item.category.should         == 'Products'
    item.title.should            == 'Product Title'
    item.description.should      == 'About me'
    item.link.should             == Addressable::URI.new(:scheme => 'http', :host => 'example.com', :path => 'products/123')
    item.author_name.should      == 'Author Name'
    item.author_email.should     == 'anon-123@base.google.com'
    item.payment_accepted.should == 'American Express,Discover,Visa,MasterCard'
    item.condition.should        == 'new'
    item.product_type.should     == 'Electronics > Computers > Laptops'
    item.image_link.should       == Addressable::URI.new(:scheme => 'http', :host => 'example.com', :path => 'images/123.jpg')
    item.item_language.should    == 'en'
    item.product_id.should       == '123'
    item.price.should            == '12.34 usd'
    item.target_country.should   == 'US'
    item.expires_at.should       == DateTime.civil(2009,8,23,22,51,58)
    item.brand.should            == 'Brand X'
    item.customer_id.should      == 123456789
    item.item_type.should        == 'Products'
    item.feed_link.should        == Addressable::URI.new(:scheme => 'http', :host => 'www.google.com', :path => 'base/feeds/items/123456789/media')
  end

end
