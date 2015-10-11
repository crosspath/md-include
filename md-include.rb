require 'json'
require 'set'

Encoding.default_external = Encoding::UTF_8

module MainApp
  class BookParser
    RE_INCLUDE = /^\s*#include\s+(.*?)\s*$/
    RE_INCLUDE_QUOTES = /^\"(.*?)\"$/
    LOCALE_ENCODING = Encoding.find('locale')
    FS_ENCODING = Encoding.find('filesystem')
    
    attr_reader :all_parsed_files, :target_files, :config_dir
    attr_accessor :config
    
    def initialize(config = nil)
      @config = config
    end
    
    def run
      config = JSON.parse(File.read(@config))
      files = config['files']
      raise 'tuple "files" has no value' unless files
      
      @config_dir = File.dirname(@config)
      @target_files = []
      
      files.each do |target|
        @all_parsed_files = Set.new
        @target_files << target
        new_contents = parse_file(target)
        
        realpath = fix_encoding(target) { |filename| File.realpath(filename, @config_dir) }
        directory_path = File.dirname(realpath)
        basename = File.basename(target).encode(LOCALE_ENCODING)
        File.open(directory_path+'/_'+basename, 'w') { |f| f << new_contents.join }
      end
    end
    
    def parse_file(file)
      realpath = fix_encoding(file) { |filename| File.realpath(filename, @config_dir) }
      raise "Recursion: include #{file}" if @all_parsed_files.include?(realpath)
      @all_parsed_files << realpath
      directory_path = File.dirname(realpath)
      contents = File.read(realpath)
      new_contents = []
      
      contents.each_line do |line|
        matches = line.match(RE_INCLUDE)
        if matches
          with_quotes = matches[1].match(RE_INCLUDE_QUOTES)
          relative_name = with_quotes ? with_quotes[1] : matches[1]
          if relative_name.size > 0
            include_file = directory_path+'/'+relative_name.encode(LOCALE_ENCODING)
            # empty strings should separate texts
            new_contents << "\n"
            new_contents << "\n"
            new_contents += if @target_files.include?(include_file)
              File.read(include_file).split(/\r?\n/)
            else
              parse_file(include_file)
            end
          else
            raise "Empty #include in #{realpath}"
          end
        else
          new_contents << line
        end
      end
      
      new_contents
    rescue => e
      STDERR.puts(realpath ? "File on stack: #{realpath} (#{file})" : "File not found: \"#{file}\"")
      raise e
    end
    
    def fix_encoding(string)
      if RUBY_PLATFORM =~ /win32|mingw32/
        s = string.encode(FS_ENCODING)
        s = yield(s) if block_given?
        s.encode(LOCALE_ENCODING)
      else
        block_given? ? yield(string) : string
      end
    end
  end
  
  CONFIG_FILE = 'build-markdown.json'
  
  module_function
  
  def help
    puts "USAGE: ruby #{File.basename(__FILENAME__)} directory"
    puts "directory should contain #{CONFIG_FILE}"
  end
  
  def run(directory)
    # По неведомой мне причине Ruby принимает от Windows
    # аргументы в кодировке 1251 под видом 866.
    if RUBY_PLATFORM =~ /win32|mingw32/
      directory = directory.dup.force_encoding(Encoding.find('filesystem'))
    end
    
    config = "#{directory}/#{CONFIG_FILE}"
    raise 'Config file not found' unless File.exists?(config)
    
    parser = BookParser.new(config)
    parser.run
    
    puts "Finish"
  rescue => e
    STDERR.puts 'Error!', e.message
    STDERR.puts e.backtrace
    exit(1)
  end
end

if ARGV.size == 1
  MainApp.run(ARGV[0])
else
  MainApp.help
end
