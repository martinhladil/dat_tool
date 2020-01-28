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
        file_name = "#{row["Content ID"]}.pkg"
        file_size = row["File Size"]
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
          end
          if File.size(game) == file_size.to_i
            if sha256 != "" && sha256 == row["SHA256"]
              puts "Matched: #{file_name}"
              matched_games << {
                file_name: file_name,
                file_size: file_size,
                name: row["Name"],
                crc: crc,
                md5: md5,
                sha1: sha1
              }
            else
              puts "Invalid SHA256: #{file_name}"
            end
          else
            puts "Invalid file size: #{file_name}"
          end
        end
      end
      puts "Games Matched: #{matched_games.size}"

      version = Date.today.to_s
      File.open(@output, "w", newline: :crlf) do |file|
        file.puts "clrmamepro ("
        file.puts %{\t name "#{File.basename(@path)}"}
        file.puts %{\t version "#{version}"}
        file.puts ")"
        file.puts

        matched_games.each do |matched_game|
          file.puts "game ("
          file.puts %{\t name "#{matched_game[:name]}"}
          file.puts %{\t description "#{matched_game[:name]}"}
          file.puts %{\t rom ( name #{matched_game[:file_name]} size #{matched_game[:file_size]} crc #{matched_game[:crc]} md5 #{matched_game[:md5]} sha1 #{matched_game[:sha1]} )}
          file.puts ")"
          file.puts
        end
      end
    end
  end
end
