module Generators
  class RdocInsideGenerator

    TYPE        = {:file => 1, :class => 2, :module => 3 }
    VISIBILITY  = {:public => 1, :private => 2, :protected => 3 }

    def self.for(options)
      new(options)
    end

    def initialize(options) #:not-new:
      @options = options

      # set up a hash to keep track of all the classes/modules we have processed
      @already_processed = {}

      # set up a hash to keep track of all of the objects to be output
      @output = {
        :files => [],
        :classes => [],
        :modules => [],
        :attributes => [],
        :methods => [],
        :aliases => [],
        :constants => [],
        :requires => [],
        :includes => []
      }
    end

    # Rdoc passes in TopLevel objects from the code_objects.rb tree (all files)
    def generate(files)
      # Each object passed in is a file, process it
      files.each { |file| process_file(file) }
    end

    private

    # process a file from the code_object.rb tree
    def process_file(file)
      @output[:files].push(file)

      puts "#{file.comment}"

      # Process all of the objects that this file contains
      file.method_list.each { |child| process_method(child) }
      file.aliases.each { |child| process_alias(child) }
      file.constants.each { |child| process_constant(child) }
      file.requires.each { |child| process_require(child) }
      file.includes.each { |child| process_include(child) }
      file.attributes.each { |child| process_attribute(child) }

      # Recursively process contained subclasses and modules
      file.each_classmodule do |child|
        process_class_or_module(child)
      end
    end

    # Process classes and modiles
    def process_class_or_module(obj)
      obj.is_module? ? type = :modules : type = :classes

      # One important note about the code_objects.rb structure. A class or module
      # definition can be spread a cross many files in Ruby so code_objects.rb handles
      # this by keeping only *one* reference to each class or module that has a definition
      # at the root level of a file (ie. not contained in another class or module).
      # This means that when we are processing files we may run into the same class/module
      # twice. So we need to keep track of what classes/modules we have
      # already seen and make sure we don't create two INSERT statements for the same
      # object.
      if(!@already_processed.has_key?(obj.full_name)) then
        @output[type].push(obj)
        @already_processed[obj.full_name] = true

        # Process all of the objects that this class or module contains
        obj.method_list.each { |child| process_method(child) }
        obj.aliases.each { |child| process_alias(child) }
        obj.constants.each { |child| process_constant(child) }
        obj.requires.each { |child| process_require(child) }
        obj.includes.each { |child| process_include(child) }
        obj.attributes.each { |child| process_attribute(child) }
      end

      id = @already_processed[obj.full_name]
      # Recursively process contained subclasses and modules
      obj.each_classmodule do |child|
      	process_class_or_module(child)
      end
    end

    def process_method(obj)
      obj.source_code = get_source_code(obj)
       puts "#{obj.name}#{obj.param_seq}"
       puts "#{obj.source_code}" # Source code, unformatted

       puts "====================================="

      @output[:methods].push(obj)
    end

    def process_alias(obj)
      @output[:aliases].push(obj)
    end

    def process_constant(obj)
      @output[:constants].push(obj)
    end

    def process_attribute(obj)
      @output[:attributes].push(obj)
    end

    def process_require(obj)
      @output[:requires].push(obj)
    end

    def process_include(obj)
      @output[:includes].push(obj)
    end


    # get the source code
    def get_source_code(method)
      src = ""
	  if(ts = method.token_stream)
	    ts.each do |t|
	    next unless t    			
	      src << t.text
	    end
      end
      return src
    end

  end


   # dynamically add a source code attribute to the base oject of code_objects.rb
   class RDoc::AnyMethod
     attr_accessor :source_code	
   end

end
