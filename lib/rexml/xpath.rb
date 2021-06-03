# frozen_string_literal: false
require_relative 'functions'
require_relative 'xpath_parser'

module REXML
  # Wrapper class.  Use this class to access the \XPath functions.
  #
  # The public class methods in this class are:
  #
  # - REXML::XPath.first:: Returns the first node
  #                        that meets the specified criteria.
  # - REXML::XPath.match:: Returns an array of all nodes
  #                        that meet the specified criteria.
  # - REXML::XPath.each:: Calls the given block with each node
  #                       that meets the specified criteria.
  #
  # Each of these methods takes five arguments that specify those criteria:
  #
  # - +element+:: The node where the search is to begin;
  #               +element+ should be an REXML::Element object.
  # - +path+:: The optional search path, relative to that node;
  #            +path+ should be a valid xpath expression.
  # - +namespaces+::
  # - +variables+::
  # - +options+::
  #
  # These arguments work the same way in each of the methods.
  #
  # The source XML for many examples here is from file
  # {books.xml}[https://www.w3schools.com/xml/books.xml] at w3schools.com.
  # You may find it convenient to open that page in a new tab
  # (Ctrl-click in some browsers).
  #
  # All examples here use the variables +doc+ and +root_ele+ resulting from:
  #
  #   require 'rexml/document'
  #   require 'open-uri'
  #   source_string = URI.open('https://www.w3schools.com/xml/books.xml').read
  #   doc = REXML::Document.new(source_string)
  #   root_ele = doc.root
  #
  # == Call with Single Argument +element+
  #
  # A call with single argument +element+ finds the element children of +element+.
  #
  # Method +first+ returns only the the first found element:
  #
  #   REXML::XPath.first(doc)        # => <bookstore> ... </>
  #   REXML::XPath.first(root_ele)   # => <book category='cooking'> ... </>
  #   book = root_ele.elements.first # => <book category='cooking'> ... </>
  #   REXML::XPath.first(book)       # => <title lang='en'> ... </>
  #
  # Method +match+ returns all found elements:
  #
  #   REXML::XPath.match(doc)        # => [<bookstore> ... </>]
  #   REXML::XPath.match(root_ele)   # =>
  #                                  # [<book category='cooking'> ... </>,
  #                                  #  <book category='children'> ... </>,
  #                                  #  <book category='web'> ... </>,
  #                                  #  <book category='web' cover='paperback'> ... </>]
  #   book = root_ele.elements.first # => <book category='cooking'> ... </>
  #   REXML::XPath.match(book)       # =>
  #                                  # [<title lang='en'> ... </>,
  #                                  #  <author> ... </>,
  #                                  #  <year> ... </>,
  #                                  #  <price> ... </>]
  #
  # Returns +nil+ if no matching element is found, or if the given +element+
  # is not an element.
  #
  # == Call with Argument +path+
  #
  # A call with arguments +element+ and +path+ finds the element children of +element+
  # that match the given +path+.
  #
  # A path that begins with a single slash character is an _absolute_ _path_.
  #
  # Method +first+ returns only the first found element:
  #
  #   REXML::XPath.first(doc, '/')                     # => <UNDEFINED> ... </> # doc
  #   REXML::XPath.first(doc, '/bookstore')            # => <bookstore> ... </>
  #   REXML::XPath.first(doc, '/bookstore/book')       # => <title lang='en'> ... </>
  #   REXML::XPath.first(doc, '/bookstore/book/title') # => <title lang='en'> ... </>
  #
  # Method +match+ returns all found elements:
  #
  #   REXML::XPath.match(doc, '/')                     # => <UNDEFINED> ... </> # doc
  #   REXML::XPath.match(doc, '/bookstore')            # => <bookstore> ... </>
  #   REXML::XPath.match(doc, '/bookstore/book')       # => <title lang='en'> ... </>
  #   REXML::XPath.match(doc, '/bookstore/book/title') # =>
  #                                                    # [<title lang='en'> ... </>,
  #                                                    #  <title lang='en'> ... </>,
  #                                                    #  <title lang='en'> ... </>,
  #                                                    #  <title lang='en'> ... </>]
  #
  # == Call with Argument +namespaces+
  #
  # == Call with Argument +variables+
  #
  # == Call with Argument +options+
  #
  class XPath
    include Functions
    # A base Hash object, supposing to be used when initializing a
    # default empty namespaces set, but is currently unused.
    # TODO: either set the namespaces=EMPTY_HASH, or deprecate this.
    EMPTY_HASH = {}

    # Finds and returns the first node that matches the supplied xpath.
    # element::
    #   The context element
    # path::
    #   The xpath to search for.  If not supplied or nil, returns the first
    #   node matching '*'.
    # namespaces::
    #   If supplied, a Hash which defines a namespace mapping.
    # variables::
    #   If supplied, a Hash which maps $variables in the query
    #   to values. This can be used to avoid XPath injection attacks
    #   or to automatically handle escaping string values.
    #
    #  XPath.first( node )
    #  XPath.first( doc, "//b"} )
    #  XPath.first( node, "a/x:b", { "x"=>"http://doofus" } )
    #  XPath.first( node, '/book/publisher/text()=$publisher', {}, {"publisher"=>"O'Reilly"})
    def XPath::first(element, path=nil, namespaces=nil, variables={}, options={})
      raise "The namespaces argument, if supplied, must be a hash object." unless namespaces.nil? or namespaces.kind_of?(Hash)
      raise "The variables argument, if supplied, must be a hash object." unless variables.kind_of?(Hash)
      parser = XPathParser.new(**options)
      parser.namespaces = namespaces
      parser.variables = variables
      path = "*" unless path
      element = [element] unless element.kind_of? Array
      parser.parse(path, element).flatten[0]
    end

    # Iterates over nodes that match the given path, calling the supplied
    # block with the match.
    # element::
    #   The context element
    # path::
    #   The xpath to search for.  If not supplied or nil, defaults to '*'
    # namespaces::
    #   If supplied, a Hash which defines a namespace mapping
    # variables::
    #   If supplied, a Hash which maps $variables in the query
    #   to values. This can be used to avoid XPath injection attacks
    #   or to automatically handle escaping string values.
    #
    #  XPath.each( node ) { |el| ... }
    #  XPath.each( node, '/*[@attr='v']' ) { |el| ... }
    #  XPath.each( node, 'ancestor::x' ) { |el| ... }
    #  XPath.each( node, '/book/publisher/text()=$publisher', {}, {"publisher"=>"O'Reilly"}) \
    #    {|el| ... }
    def XPath::each(element, path=nil, namespaces=nil, variables={}, options={}, &block)
      raise "The namespaces argument, if supplied, must be a hash object." unless namespaces.nil? or namespaces.kind_of?(Hash)
      raise "The variables argument, if supplied, must be a hash object." unless variables.kind_of?(Hash)
      parser = XPathParser.new(**options)
      parser.namespaces = namespaces
      parser.variables = variables
      path = "*" unless path
      element = [element] unless element.kind_of? Array
      parser.parse(path, element).each( &block )
    end

    # Returns an array of nodes matching a given XPath.
    def XPath::match(element, path=nil, namespaces=nil, variables={}, options={})
      parser = XPathParser.new(**options)
      parser.namespaces = namespaces
      parser.variables = variables
      path = "*" unless path
      element = [element] unless element.kind_of? Array
      parser.parse(path,element)
    end
  end
end
