module XmlHelpers
  def xml_feed(entries, options = {})
    start    = options[:start]    || 1
    per_page = options[:per_page] || 250
    total    = options[:total]    || entries.length

    next_link = if total >= start + per_page
      "<link rel='next' type='application/atom+xml' href='http://www.google.com/base/feeds/items?start-index=#{start + per_page}&amp;max-results=#{per_page}'/>"
    else
      ""
    end

    <<-XML.compress_lines(false)
      <?xml version='1.0' encoding='UTF-8'?>
      <feed xmlns='http://www.w3.org/2005/Atom' xmlns:openSearch='http://a9.com/-/spec/opensearch/1.1/' xmlns:gm='http://base.google.com/ns-metadata/1.0' xmlns:g='http://base.google.com/ns/1.0' xmlns:batch='http://schemas.google.com/gdata/batch' xmlns:gd='http://schemas.google.com/g/2005' gd:etag='W/&quot;Dk4BRHc5cSp7ImA9WxJWFkw.&quot;'>
      <id>http://www.google.com/base/feeds/items</id>
      <updated>2009-06-21T20:09:15.929Z</updated>
      <title>Items matching query: [customer id(int):123456789]</title>
      <link rel='alternate' type='text/html' href='http://base.google.com'/>
      <link rel='http://schemas.google.com/g/2005#feed' type='application/atom+xml' href='http://www.google.com/base/feeds/items'/>
      <link rel='http://schemas.google.com/g/2005#post' type='application/atom+xml' href='http://www.google.com/base/feeds/items'/>
      <link rel='http://schemas.google.com/g/2005#batch' type='application/atom+xml' href='http://www.google.com/base/feeds/items/batch'/>
      <link rel='self' type='application/atom+xml' href='http://www.google.com/base/feeds/items?start-index=#{start}&amp;max-results=#{per_page}'/>
      #{next_link}
      <author>
        <name>Google Inc.</name>
        <email>base@google.com</email>
      </author>
      <generator version='1.0' uri='http://base.google.com'>GoogleBase</generator>
      <openSearch:totalResults>#{total}</openSearch:totalResults>
      <openSearch:startIndex>#{start}</openSearch:startIndex>
      <openSearch:itemsPerPage>#{per_page}</openSearch:itemsPerPage>
      <g:customer_id type='int'>123456789</g:customer_id>
      #{entries.join}
    XML
  end

  def xml_entry(updated_options = {})
    options = Hash.new { |hash, key| raise "Don't know #{key}" }

    id   = updated_options.delete('id')   || 'http://www.google.com/base/feeds/items/123456789'
    g_id = updated_options.delete('g:id') || '123'

    options.merge!({
      'id' => id,
      'published' => '2008-06-12T02:47:04.000Z',
      'updated'   => '2009-06-19T23:42:07.000Z',
      'edited'    => '2009-06-19T23:42:07.000Z',

      'title'   => 'MacBook Pro',
      'content' => 'A computer',

      'alternate_link' => "http://example.com/products/#{g_id}",
      'self_link'      => id,
      'edit_link'      => id,

      'author_name' => 'Store Name',

      'g:condition'       => 'new',
      'g:product_type'    => 'Electronics &gt; Computers &gt; Laptops',
      'g:customer'        => 'Store Name',
      'g:image_link'      => "http://example.com/images/#{g_id}.jpg",
      'g:item_language'   => 'EN',
      'g:id'              => g_id,
      'g:price'           => '12.34 usd',
      'g:target_country'  => 'US',
      'g:expiration_date' => '2009-07-19T23:42:07Z',
      'g:brand'           => 'Apple Inc.',
      'g:customer_id'     => '123456789',
      'g:item_type'       => 'Products',

      'gd:feedLink' => "#{id}/media"
    })

    options.merge!(updated_options)

    <<-XML.compress_lines(false)
      <?xml version='1.0' encoding='UTF-8'?>
      <entry xmlns='http://www.w3.org/2005/Atom' xmlns:gm='http://base.google.com/ns-metadata/1.0' xmlns:g='http://base.google.com/ns/1.0' xmlns:batch='http://schemas.google.com/gdata/batch' xmlns:gd='http://schemas.google.com/g/2005' gd:etag='W/&quot;CEEFRn47eCp7ImA9WxJWGE8.&quot;'>
        <id>#{options['id']}</id>
        <published>#{options['published']}</published>
        <updated>#{options['updated']}</updated>
        <app:edited xmlns:app='http://www.w3.org/2007/app'>#{options['edited']}</app:edited>
        <category scheme='http://base.google.com/categories/itemtypes' term='Products'/>
        <title>#{options['title']}</title>
        <content type='html'>#{options['content']}</content>
        <link rel='alternate' type='text/html' href='#{options['alternate_link']}'/>
        <link rel='self' type='application/atom+xml' href='#{options['self_link']}'/>
        <link rel='edit' type='application/atom+xml' href='#{options['edit_link']}'/>
        <author>
          <name>#{options['author_name']}</name>
          <email>anon-123@base.google.com</email>
        </author>
        <g:condition type='text'>#{options['g:condition']}</g:condition>
        <g:product_type type='text'>#{options['g:product_type']}</g:product_type>
        <g:customer type='text'>#{options['g:customer']}</g:customer>
        <g:image_link type='url'>#{options['g:image_link']}</g:image_link>
        <g:item_language type='text'>#{options['g:item_language']}</g:item_language>
        <g:id type='text'>#{options['g:id']}</g:id>
        <g:price type='floatUnit'>#{options['g:price']}</g:price>
        <g:target_country type='text'>#{options['g:target_country']}</g:target_country>
        <g:expiration_date type='dateTime'>#{options['g:expiration_date']}</g:expiration_date>
        <g:brand type='text'>#{options['g:brand']}</g:brand>
        <g:customer_id type='int'>#{options['g:customer_id']}</g:customer_id>
        <g:item_type type='text'>#{options['g:item_type']}</g:item_type>
        <gd:feedLink rel='media' href='#{options['gd:feedLink']}' countHint='1'/>
      </entry>
    XML
  end

  def http_response(content, options = {})
    <<-HTTP.margin
      HTTP/1.1 200 OK
      Content-Type: text/plain
      Cache-control: no-cache, no-store
      Pragma: no-cache
      Expires: Mon, 01-Jan-1990 00:00:00 GMT
      Date: Sat, 20 Jun 2009 22:04:48 GMT
      X-Content-Type-Options: nosniff
      Content-Length: #{content.length}
      Server: GFE/2.0

      #{content}
    HTTP
  end
end
