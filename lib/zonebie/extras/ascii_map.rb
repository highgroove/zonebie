require 'net/http'
require 'open-uri'
require 'chunky_png'
require 'rainbow'

Sickill::Rainbow.enabled = true

module Zonebie
  module Extras
    class AsciiMap
      attr_accessor :zone, :image, :ascii, :mark

      def initialize(zone)
        self.zone  = zone
        self.mark  = false
        self.ascii = map_to_ascii
      end

      def to_s
        ascii
      end

      private

      def disable_webmock
        if defined? WebMock
          allow_net_connect_was = WebMock::Config.instance.allow_net_connect
          WebMock::Config.instance.allow_net_connect = true
          yield
          WebMock::Config.instance.allow_net_connect = allow_net_connect_was
        else
          yield
        end
      end

      def google_maps_request
        "http://maps.googleapis.com/maps/api/staticmap?format=png8&zoom=1&maptype=roadmap&sensor=false&center=0,0&size=500x500&markers=size:large%7Ccolor:red%7C#{URI.encode(zone)}&style=feature:all%7Celement:labels%7Cvisibility:off&style=feature:all%7Celement:geometry%7Clightness:100&style=feature:water%7Celement:geometry%7Clightness:-100"
      end

      def map_to_ascii
        image = nil

        disable_webmock do
          open google_maps_request do |f|
            image = ChunkyPNG::Image.from_blob(f.read)
          end
        end

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
            'X'.color(:red)
          end
        end
      end
    end
  end
end
