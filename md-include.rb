Encoding.default_external = Encoding::UTF_8

module MainApp
  require_relative 'lib/book_parser'
  
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
