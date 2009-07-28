require "dm-types/uri"
require "dm-validations"

module GoogleBase
  class Product
    include DataMapper::Resource

    property :id, String, :key => true, :nullable => true, :length => 255, :from_xml => 'xmlns:id'
    property :title, String, :from_xml => 'xmlns:title', :length => 70,
      :to_xml => lambda { |xml, value| xml.title value }
    property :description, Text, :field => 'content', :from_xml => 'xmlns:content', :lazy => false
    property :link, URI, :from_xml => "xmlns:link[@rel='alternate']/@href",
      :to_xml => lambda { |xml, value| xml.link :href => value, :type => 'text/html', :rel => 'alternate' }
    property :condition, String, :field => 'g:condition', :nullable => false # :set => %w[ new used refurbished ], :default => 'new',
    property :product_type, String, :field => 'g:product_type', :length => 255
    property :image_link, URI, :field => 'g:image_link'
    property :product_id, String, :field => 'g:id', :nullable => false
    property :price, String, :field => 'g:price', :nullable => false
    property :brand, String, :field => 'g:brand'
    property :item_type, String, :field => 'g:item_type', :nullable => false, :set => %w[ Products Produkte ], :default => 'Products'

    # optional
    property :expires_at, DateTime, :field => 'g:expiration_date',
      :to_xml => lambda { |xml, value| xml.tag! 'g:expiration_date', value.strftime('%F') }
    property :quantity, Integer, :field => 'g:quantity'
    property :payment_accepted, String,
      :from_xml => lambda { |entry| entry.xpath('./g:payment').map { |e| e.content }.join(',') },
      :to_xml => lambda { |xml, values| values.split(',').each { |value| xml.tag! 'g:payment_accepted', value } }
    property :item_language, String,  :field => 'g:item_language'
    property :target_country, String, :field => 'g:target_country'

    # read only
    property :created_at,   DateTime, :field => 'xmlns:published',          :to_xml => false
    property :updated_at,   DateTime, :field => 'xmlns:updated',            :to_xml => false
    property :category,     String,   :field => 'xmlns:category/@term',     :to_xml => false
    property :author_name,  String,   :field => 'xmlns:author/xmlns:name',  :to_xml => false
    property :author_email, String,   :field => 'xmlns:author/xmlns:email', :to_xml => false
    property :customer_id,  Integer,  :field => 'g:customer_id',            :to_xml => false
    property :feed_link,    URI,      :field => 'gd:feedLink/@href',        :to_xml => false
  end
end
