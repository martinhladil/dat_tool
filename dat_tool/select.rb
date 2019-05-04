module DatTool
  class Select
    def initialize(path, input, output)
      @path = path
      @input = input
      @output = output
    end

    def select
      games = []
      Dir.entries(@path).each do |entry|
        unless entry.start_with?(".")
          games << File.basename(entry, File.extname(entry))
        end
      end
      puts "Games Found: #{games.size}"

      xml = File.open(@input) do |file|
        Nokogiri::XML(file) do |config|
          config.strict.noblanks
        end
      end
      matched = 0
      name = xml.at_css("datafile > header > name")
      name.content = "#{name.content} (Custom)"
      xml.css("datafile > game").each do |element|
        if games.include?(element["name"])
          matched += 1
          element.remove_attribute("cloneof")
        else
          element.remove
        end
      end
      puts "Games Matched: #{matched}"
      File.write(@output, xml.to_xml)
    end
  end
end
