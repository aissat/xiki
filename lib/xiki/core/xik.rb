# Sample usage:
#
# x = Xik.new "
#   fish/
#     tuna/
#     shark/
#   mammals/
#   "
#
# puts x['fish']
#   tuna/
#   shark/
#
# puts x['']
#   fish/
#   mammals/


module Xiki
  # Wraps a xiki tree.  Kind of like a hash.  Primarily just wraps text
  # and passes to .children method.
  class Xik

    # Has text of menu
    #   - Usually an array version, for optimization
    #     - (either ["a", "  b"] or [[0, "a"], [2, "b"]]
    #   - Could be a string, for optimization
    #     - maybe if a bunch of searching and replacing is going on, for example
    # Should there be methods for converting?
    #   - .
    attr_accessor :txt
    # number of characters from left - 0-based?
    attr_accessor :line
    attr_accessor :column

    # Can take a string, hash, or array
    # Shit > when hash, how to distinguish between > options hash and data structure.
    #   - That is, an "options" hash is for storing the internal state
    #     of a Xik instance in a hash, for portability and convenience.
    #       =- See) :t/> xik > keys for hash representation!:
    #     - Maybe I can check whether the hash has certain keys?
    #       - that's tricky, because it could have just :txt, or just :txt, etc.
    #         - probably make 2 args > Xik.new(:state, options)
    def initialize *args

      @line, @column, @txt = 1, 1, []

      return if args.blank?

      # 1st arg is string, so store as txt...

      if args[0].is_a? String
        options = args[1]
        parse_string args[0], options||{}
        return
      end

      return @txt = self.class.parse_hash_or_array(args[0]) if args[0].is_a?(Array) || args[0].is_a?(Hash)

      raise "Don't know how to parse: #{args[0].class}"
    end

    def parse_string txt, options={}
      txt = txt.unindent if txt =~ /\A\s/ && ! options[:leave_indent]
      @txt = txt.split("\n", -1)
    end

    # txt as array
    def lines
      @txt
    end

    def txt
      @txt.join("\n") #+"\n"
    end

    def txt_without_code
      txt.gsub(/^ *\!( .*|)\n/, '')
    end

    def current
      @txt[@line-1]
    end

    # Returns a sample prepopulated Xik instance to mess around and test with.
    def self.foo
      self.new "
        a/
          - b/
        c/
          - d/
            - e/
        "
    end

    def self.animals
      self.new "
        dogs/
          - lab/
          - terrior/
        cats/
          - lion/
          - tiger/
        "
    end

    def self.math
      self.new "
        add/
          ! 3 + 1
        subtract/
          ! n = 3
          ! 3 - 1
        "
    end

    def []= path, value, options={}
      raise "- not implemented yet > is there code we can pull from to do this? > I don't think so yet!
        - To implement, maybe step through using .next, or search through using .search (maybe .next should take a regex arg (or just full line string arg?),
          - which can amount to the same thing as .search would do?)
        - Step through to find it
          - then move to next sibling or end, and insert it one indent lower
          - if not found, just add at end
            - but be careful, will need to match partial path matches, like
              | a/
              |   b/
              |     z/
              | a['b/c'] = 'd'
              | a/
              |   b/
              |     z
              |     c/
              |       d

              | # Side-note > hypothetical xikiscript syntax for > a['b/c'] = 'd'
              | a/b/c/<=d
              | # - wait, would this invoke =d, or just add the string 'd'?
        "
    end

    def [] path=nil, options={}
      self.expand path, options
    end

    def expand path=nil, options={}

      return current if ! path

      return nil if ! @txt
      result = Tree.children @txt, path
      if result
        result.strip!
      end

      # MenuHandler.eval_exclamations result, options if options
      if eval_options = options[:eval]

        # :eval means to eval the exclamations.
        # We're setting :nest=>1 (in the main options, which is the expected value) in case it's this Xiki is used for a dropdown menu
        #   - Is this the best place to do that?
        #   - Does it make sense to only do it when :eval?

        eval_options[:nest] = 1 if eval_options.is_a?(Hash) && result !~ /^ *! /

        MenuHandler.eval_exclamations result, options
      end

      result
    end

    def to_s
      @txt
    end

    def inspect
      txt
    end

    # Moves cursor to last line
    def to_bottom
      @line = @txt.length
    end

    def at_top?
      @line == 1
    end

    # Indent of current line
    def indent
      (current||"")[/^ */]
    end

    def =~ regex
      current =~ regex
    end

    def at_bottom?
      @line == @txt.length && @column >= current.length
    end

    def at_last_line?
      @line >= @txt.length
    end

    def previous
      return if @line == 1
      @line -= 1
    end

    def cursor

      # Add up the length of each line, up intil line...

      i = 1
      count = 1   # They're always on the 1st char to begin with
      while i < @line
        count += @txt[i-1].length + 1
        i += 1
      end
      count + (@column-1)   # Subtract one if we decide to do columns an 1-based

      # Calculate from @line and @column
    end

    def next
      # Do nothing if at end
      return if @line >= @txt.length

      @line += 1
      # Calculate from @line and @column
    end

    def self.parse_hash_or_array structure, options=nil

      # If 1st time called, initialize state

      options ||= {
        :indent=>-1,
        :txt=>[],
      }

      options[:indent] += 1

      # Hash, so go through each key...

      if structure.is_a? Hash
        structure.each do |k, v|
          options[:txt] << "#{"  "*options[:indent]}- #{k}/"
          self.parse_hash_or_array v, options
        end

      elsif structure.is_a? Array
        structure.each do |i|
          options[:txt] << "#{"  "*options[:indent]}- ./"
          self.parse_hash_or_array i, options
        end

      else   # Recursive call found string in hash or array, so just store
        options[:txt] << "#{"  "*options[:indent]}- #{structure}/"

      end

      # Array, so go through each item, with "." as key...

      options[:indent] -= 1   # For recursive call
      options[:txt]
    end

  end
end
