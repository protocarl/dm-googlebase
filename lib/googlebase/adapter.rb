require 'dm-core'
require 'gdata'
require 'nokogiri'

module GoogleBase
  class Adapter < DataMapper::Adapters::AbstractAdapter

    def read(query)
      records = []

      operands = query.conditions.operands

      if read_one?(operands)

        response = @gb.get(operands.first.value)
        xml = Nokogiri::XML.parse(response.body)

        each_record(xml, query.fields) do |record|
          records << record
        end

      elsif read_all?(operands)

        start    = query.offset + 1
        per_page = query.limit || 250

        url = "http://www.google.com/base/feeds/items?start-index=#{start}&max-results=#{per_page}"

        while url
          response = @gb.get(url)
          xml = Nokogiri::XML.parse(response.body).at('./xmlns:feed')

          each_record(xml, query.fields) do |record|
            records << record
          end

          break if query.limit && query.limit >= records.length
          url = xml.at("./xmlns:link[@rel='next']/@href")
        end

      else
        raise NotImplementedError
        # TODO implement query conditions
      end

      records
    end

    def token
      @gb.auth_handler.token
    end

    private

    def initialize(name, options)
      super(name, options)

      assert_kind_of 'options[:user]',     options[:user],     String
      assert_kind_of 'options[:password]', options[:password], String

      @gb = GData::Client::GBase.new
      @gb.source = 'dm-googlebase'
      @gb.clientlogin(options[:user], options[:password])
    end

    def each_record(xml, fields)
      xml.xpath('./xmlns:entry').each do |entry|
        record = fields.map do |property|
          value = property.typecast(entry.at("./#{property.field}").to_s)

          [ property.field, value ]
        end

        yield record.to_hash
      end
    end

    def read_one?(operands)
      operands.length == 1 &&
      operands.first.kind_of?(DataMapper::Query::Conditions::EqualToComparison) &&
      operands.first.subject.key?
    end

    def read_all?(operands)
      operands.empty?
    end

  end
end

DataMapper::Adapters::GoogleBaseAdapter = GoogleBase::Adapter
