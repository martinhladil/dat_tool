require "csv"
require "date"
require "openssl"
require "find"
require "zlib"

module DatTool
  class NoPayStationSelect
    def initialize(path, input, output)
      @path = path
      @input = input
      @output = output
    end

    def no_pay_station_select
      games = []
      Find.find(@path).each do |entry|
        unless File.directory?(entry)
          games << entry
        end
      end
      puts "Games Found: #{games.size}"

      csv = CSV.read(@input, headers: true, col_sep: "\t", quote_char: "\x00")

      matched_games = []
      csv.each do |row|
        if row["PKG direct link"] == "MISSING" || row["zRIF"] == "MISSING" || row["File Size"].to_i == 0
          next
        end
        if row["Content ID"]
          file_name = "#{row["Content ID"]}.pkg"
          name = row["Name"]
        else
          file_name = row["PKG direct link"].split("/").last
          parts = file_name.split("-")
          file_name = "#{parts[0..2].join("-")}_patch_#{parts[3][1..2]}.#{parts[3][3..4]}.pkg"
          name = "#{row["Name"]} #{row["Update Version"]}"
        end
        name.gsub!("\"", "")
        file_size = row["File Size"].to_i
        game = games.find{ |game| File.basename(game) == file_name }
        if game
          sha256 = nil
          sha1 = nil
          md5 = nil
          crc = nil
          File.open(game) do |file|
            sha256_digest = OpenSSL::Digest::SHA256.new
            sha1_digest = OpenSSL::Digest::SHA1.new
            md5_digest = OpenSSL::Digest::MD5.new
            buffer = ""
            while file.read(1024 * 1024, buffer)
              sha256_digest.update(buffer)
              sha1_digest.update(buffer)
              md5_digest.update(buffer)
              crc = Zlib::crc32(buffer, crc)
            end
            sha256 = sha256_digest.to_s
            sha1 = sha1_digest.to_s
            md5 = md5_digest.to_s
            crc = crc.to_s(16)
          end
          if File.size(game) == file_size
            if row["SHA256"].nil? || row["SHA256"] == "" || row["SHA256"] == sha256
              puts "Matched: #{file_name}"
              matched_games << {
                file_name: file_name,
                file_size: file_size,
                title_id: row["Title ID"],
                name: name,
                crc: crc,
                md5: md5,
                sha1: sha1
              }
            else
              puts "Invalid SHA256: #{file_name}"
            end
          else
            puts "Invalid file size: #{file_name} (#{File.size(game)}/#{file_size})"
          end
        end
      end
      puts "Games Matched: #{matched_games.size}"

      version = Date.today.to_s
      File.open(@output, "w", newline: :crlf) do |file|
        file.puts "clrmamepro ("
        file.puts %{\t version "#{version}"}
        file.puts ")"
        file.puts

        matched_games.each do |matched_game|
          file.puts "game ("
          file.puts %{\t name "#{matched_game[:title_id]} - #{matched_game[:name]}"}
          file.puts %{\t rom ( name #{matched_game[:file_name]} size #{matched_game[:file_size]} crc #{matched_game[:crc]} md5 #{matched_game[:md5]} sha1 #{matched_game[:sha1]} )}
          file.puts ")"
          file.puts
        end
      end
    end
  end
end
