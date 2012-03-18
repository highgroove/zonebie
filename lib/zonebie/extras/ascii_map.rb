require 'net/http'
require 'tempfile'
require 'chunky_png'
require 'colorize'

module Zonebie
  module Extras
    class AsciiMap
      attr_accessor :zone, :image, :ascii, :mark

      def initialize(zone)
        self.zone  = zone
        self.image = download_map
        self.ascii = map_to_ascii
        self.mark  = false
      end

      def to_s
        ascii
      end

      private

      def download_map
        request = "http://maps.googleapis.com/maps/api/staticmap?format=png8&zoom=1&maptype=roadmap&sensor=false&center=0,0&size=500x500&markers=size:large%7Ccolor:red%7C#{URI.encode(zone)}&style=feature:all%7Celement:labels%7Cvisibility:off&style=feature:all%7Celement:geometry%7Clightness:100&style=feature:water%7Celement:geometry%7Clightness:-100"
        uri = URI.parse(request)
        response = Net::HTTP.get_response(uri)

        image = Tempfile.new(['ascii_map', '.png'])
        image.write(response.body)
        image.close
        image
      end

      def map_to_ascii
        image = ChunkyPNG::Image.from_file(self.image.path)
        image.resample_nearest_neighbor!(80, 30)
        dots = image.pixels.map{ |p| colored_dot(p) }
        dots.each_slice(80).map{ |d| d.join }.join("\n")
      end

      def colored_dot(color)
        if ChunkyPNG::Color.grayscale? color
          if ChunkyPNG::Color.r(color) > (255 / 2)
            '.'
          else
            ' '
          end
        else
          if mark
            '.'
          else
            self.mark = true
            '.'.red
          end
        end
      end
    end
  end
end