class PSD
  class LayerStyles
    class ColorOverlay
      def self.should_apply?(data)
        data.has_key?('SoFi') && data['SoFi']['enab']
      end

      def self.for_canvas(canvas)
        data = canvas.node.object_effects
        return nil if data.nil?
        return nil unless should_apply?(data.data)

        styles = LayerStyles.new(canvas)
        self.new(styles)
      end

      def initialize(styles)
        @canvas = styles.canvas
        @node = styles.node
        @data = styles.data
      end

      def apply!
        # TODO - implement CMYK color overlay
        return if @node.header.cmyk?
        return if PSD::Renderer::VectorShape.can_render?(@canvas)

        width = @canvas.width
        height = @canvas.height
        overlay_color = ChunkyPNG::Color.rgba(r, g, b, a)

        PSD.logger.debug "Layer style: layer = #{@node.name}, type = color overlay, blend mode = #{blending_mode}"

        height.times do |y|
          width.times do |x|
            pixel = @canvas[x, y]
            next if ChunkyPNG::Color.a(pixel) == 0

            @canvas[x, y] = Compose.send(blending_mode, overlay_color, pixel)
          end
        end
      end

      def r
        @r ||= color_data['Rd  '].round
      end

      def g
        @g ||= color_data['Grn '].round
      end

      def b
        @b ||= color_data['Bl  '].round
      end

      def a
        @a ||= (overlay_data['Opct'][:value] * 2.55).ceil
      end

      private

      def blending_mode
        @blending_mode ||= BlendMode::BLEND_MODES[BLEND_TRANSLATION[overlay_data['Md  ']].to_sym]
      end

      def overlay_data
        @data['SoFi']
      end

      def color_data
        overlay_data['Clr ']
      end
    end
  end
end