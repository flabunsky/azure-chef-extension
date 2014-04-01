require 'json'

class JSONFileReader

  public

  def initialize(file, *keys)
    @deserialized_objects = deserialize_json(file)
    @keys = *keys
  end

  def read_value()
    json_key_path = "self"

    @keys.each do |key|
      if key == "client_rb"
        return @client_rb
      end
      path_component = key

      if path_component.length > 1024
        raise ArgumentError, "Argument #{path_component.slice(0,15)}... exceeds maximum key length"
      end

      if ! is_alphanumeric(path_component)
        raise ArgumentError, "Argument '#{path_component}' must be alphanumeric"
      end

      path_component = "'#{path_component}'"  if ! is_numeric(path_component)

      json_key_path += "[#{path_component}]"
    end

    begin
      if @deserialized_objects.kind_of?(Array)
        @deserialized_objects = @deserialized_objects[0]
      end
      (@deserialized_objects.instance_eval(json_key_path)).to_s
    rescue
      STDERR.puts "Failed to deserialize the following object:\n#{@deserialized_objects}"
      raise
    end
  end

  def get_deserialized_objects
   if @deserialized_objects.kind_of?(Array)
     @deserialized_objects = @deserialized_objects[0]
   end
   @deserialized_objects
  end

  private

  def deserialize_json(file)
    normalized_content = File.read(file)
    # This is a bad hack to handle multiple lines in client_rb field of JSON file
    unless (normalized_content.match("\\\"client_rb\\\":") .nil?)
      part1 = normalized_content.split("\"client_rb\":")
      unless (part1[1].match("\\\"runlist\\\":").nil?)
        part2 = part1[1].split("\"runlist\":")
        normalized_content = part1[0] + "\"runlist\":" + part2[1]
        @client_rb = part2[0]
        @client_rb = part2[0].gsub(",\n", "").gsub("\\", "").gsub("\"", "'").gsub(" \"", "")
        @client_rb = @client_rb.strip
        @client_rb[0] = ""
      else
        normalized_content = part1[0]
        @client_rb = part1[1]
        @client_rb = part1[1].gsub(",\n", "").gsub("\\", "").gsub("\"", "'").gsub(" \"", "")
        @client_rb = @client_rb.strip
        @client_rb[0] = @client_rb[@client_rb.length-1] = ""
      end
    else
      @client_rb = ""
    end
    @client_rb = escape_unescaped_content(@client_rb)
    JSON.parse(normalized_content)
  end

  def is_alphanumeric(sequence)
    if sequence.match(/[\dA-Za-z\_]+/)
      $~[0] == sequence
    end
  end

  def is_numeric(sequence)
    if sequence.match(/[\d]+/)
      $~[0] == sequence
    end
  end
end

def escape_unescaped_content(file_content)
   lines = file_content.lines.to_a
   # convert tabs to spaces -- technically invalidates content, but
   # if we know the content in question treats tabs and spaces the
   # same, we can do this.
   untabified_lines = lines.map { | line | line.gsub(/\t/," ") }

   # remove whitespace and trailing newline
   stripped_lines = untabified_lines.map { | line | line.strip }
   escaped_content = ""
   line_index = 0

   stripped_lines.each do | line |
     escaped_line = line

     # assume lines ending in json delimiters are not content,
     # and that lines followed by a line that starts with ','
     # are not content
     if !!(line[line.length - 1] =~ /[\,\}\]]/) ||
         (line_index < (lines.length - 1) && lines[line_index + 1][0] == ',')
       escaped_line += "\n"
     else
       escaped_line += "\\n"
     end

     escaped_content += escaped_line
     line_index += 1
   end

   escaped_content

 end

def get_jsonreader_object(file_name, *keys)
  file = file_name

  if file.nil?
    puts "No file specified -- you must specify a file argument -- doing nothing."
    return
  end

  json_reader = JSONFileReader.new(file, *keys)
end

def value_from_json_file(file_name, *keys)
  json_reader = get_jsonreader_object(file_name, *keys)
  json_value = json_reader.read_value()

  if ! json_value.is_a?(String)
    raise ArgumentError, "Specified keys #{keys.to_s} retrieved an object of type #{json_value.class} instead of a String. Retrieved value was a(n) #{json_value.class.to_s}"
  end

  print json_value
end

def parse_json_file(file_name)
   json_reader = get_jsonreader_object(file_name, [])
   json = json_reader.get_deserialized_objects
   print json
end

def parse_json_contents (contents)
  deserialized_contents = JSON.parse(contents)
  if deserialized_contents.kind_of?(Array)
     deserialized_contents = deserialized_contents[0]
  end
  deserialized_contents
end

# TODO: Writes JSON file.
def write_json_file (file, contents)
  begin
    #f = File.open(file, "w")
    #f.write(contents.to_json)
    return 0
  rescue IOError => e
    #some error occur, dir not writable etc.
    print e
    return 1
  ensure
    #f.close unless f == nil
  end
end