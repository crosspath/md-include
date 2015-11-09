require_relative '../../lib/book_parser'

RSpec.describe BookParser do
  def book_parser(test_case)
    directory = "#{Dir.pwd}/spec/files/#{test_case}"
    config_path = "#{directory}/build-markdown.json"
    @book_parser = BookParser.new(config_path)
    
    config_contents = JSON.parse(File.read(config_path))
    file_name = config_contents['files'][0]
    
    @input_file = "#{directory}/#{file_name}"
    @result_file = "#{directory}/_#{file_name}"
  end
  
  it 'combines several files into one file' do
    book_parser('book')
    File.delete(@result_file) if File.exists?(@result_file)
    
    expect { @book_parser.run }.not_to raise_error
    expect(File.exists?(@result_file)).to be true
    expect(File.size(@result_file)).to be >= 40
    
    File.delete(@result_file)
  end
  
  it 'throws error on recursion' do
    book_parser('recursion')
    File.delete(@result_file) if File.exists?(@result_file)
    
    expect { @book_parser.run }.to raise_error(RuntimeError, "Recursion: include #{@input_file}")
    expect(File.exists?(@result_file)).to be false
  end
end
