Spec::Matchers.define :match_xml_document do |expected|
  match do |actual|
    actual_doc   = Nokogiri.XML(actual)   { |cfg| cfg.noblanks }
    expected_doc = Nokogiri.XML(expected) { |cfg| cfg.noblanks }

    actual_doc.encoding.should == expected_doc.encoding
    actual_doc.root.should match_xml_node(expected_doc.root)
  end
end

class MatchXMLNode
  def initialize(expected)
    @expected = expected
  end

  def matches?(actual)
    @actual = actual

    if @expected.namespace
      return false if @actual.namespace.nil?
      return false if @actual.namespace.prefix != @expected.namespace.prefix
    else
      return false if not @actual.namespace.nil?
    end

    return false if @actual.name != @expected.name
    return false if @actual.attributes.map { |k,v| [k,v.to_s] }.to_hash !=
      @expected.attributes.map { |k,v| [k,v.to_s] }.to_hash

    @actual.children.each_with_index do |child, i|
      if child.text?
        return false if @expected.children[i].nil?
        return false if child.text != @expected.children[i].text
      else
        child.should match_xml_node(@expected.children[i])
      end
    end

    true
  end

  def failure_message_for_should
    @actual_part = @actual.dup
    @actual_part.content = nil if @actual_part.child && !@actual_part.child.text?

    @expected_part = @expected.dup
    @expected_part.content = nil if @expected_part.child && !@expected_part.child.text?

    "expected:\n#{@actual_part.inspect}\n to match node:\n#{@expected_part.inspect}\n but it didn't"
  end

  def failure_message_for_should_not
    "expected:\n#{@actual_part.inspect}\n not to match node:\n#{@expected_part.inspect}\n but it did"
  end
end

def match_xml_node(expected)
  MatchXMLNode.new(expected)
end
