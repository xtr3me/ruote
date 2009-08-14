#--
# Copyright (c) 2005-2009, John Mettraux, jmettraux@gmail.com
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
# Made in Japan.
#++


require 'uri'
require 'open-uri'
require 'ruote/engine/context'
require 'ruote/util/json'
require 'ruote/parser/ruby_dsl' # just making sure it's loaded
require 'ruote/parser/xml'


module Ruote

  #
  # A process definition parser.
  #
  class Parser

    include EngineContext

    def parse (definition)

      return definition if definition.is_a?(Array) and definition.size == 3

      # TODO : yaml (maybe)

      (return XmlParser.parse(definition)) rescue nil
      (return Ruote::Json.decode(definition)) rescue nil
      (return ruby_eval(definition)) rescue nil

      if definition.index("\n") == nil

        u = URI.parse(definition)

        raise ArgumentError.new(
          "remote process definitions are not allowed"
        ) if u.scheme != nil && @context[:remote_definition_allowed] != true

        return parse(open(definition).read)
      end

      raise ArgumentError.new(
        "doesn't know how to parse definition (#{definition.class})")
    end

    protected

    def ruby_eval (s)

      treechecker.check(s)
      eval(s)

    rescue Exception => e
      #puts e
      #e.backtrace.each { |l| puts l }
      raise ArgumentError.new('probably not ruby')
    end
  end
end
