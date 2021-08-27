module Emerald
  module Files
    class File
      attr_reader :path, :contents
      def length
        contents.length
      end

      def inspect
        "<file: #{path}>"
      end

      def context_around(offset)
        LineContext.new(
          file: self,
          line_number: line_number(offset),
          offset: offset,
        ).to_s
      end

      def line_number(offset)
        number = 1
        contents.each_char.with_index do |char, index|
          number += 1 if char == "\n"
          break if index >= offset
        end
        number
      end

      def start_of_line(offset)
        offset -= 1 if contents[offset] == "\n"
        while offset > 0 && contents[offset] != "\n"
          offset -= 1
        end
        offset += 1 if contents[offset] == "\n"
        offset
      end

      def end_of_line(offset)
        return offset if contents[offset] == "\n"
        while offset < contents.length && contents[offset] != "\n"
          offset += 1
        end
        offset -= 1 if contents[offset] == "\n"
        offset
      end

      private

      class LineContext
        def initialize(file:, line_number:, offset:)
          @file = file
          @line_number = line_number
          @offset = offset
          @line = Line.from_offset(file, offset)
          @previous_line = Line.from_offset(file, line.start_offset - 2)
        end

        CONTEXT_SIZE = 40
        def to_s
          str = previous_line_text
          str << current_line_text
          str << context_pointer_text
          str
        end

        private
        attr_reader :file, :line, :offset, :previous_line, :line_number, :padding

        def previous_line_text
          return "" if line_number == 1
          padded_line_number(line_number - 1) + "| " + previous_line_context + "\n"
        end

        def current_line_text
          padded_line_number(line_number) + "| " + current_line_context  + "\n"
        end

        def context_pointer_text
          prefix_length = offset - current_line_context_bounds.first
          empty_prefix_space = " " * prefix_length
          arrow_up = empty_prefix_space + "^"
          here_text = empty_prefix_space + "here"

          padded_line_number("") + "| " + arrow_up  + "\n" +
          padded_line_number("") + "  " + here_text + "\n"
        end

        def current_line_context
          file.contents[current_line_context_bounds].chomp
        end

        def current_line_context_bounds
          line.context_bounds(offset, CONTEXT_SIZE)
        end

        def previous_line_context
          file.contents[previous_line_context_bounds].chomp
        end

        def previous_line_context_bounds
          previous_line.context_bounds(
            previous_line.start_offset + line.line_offset(offset),
            CONTEXT_SIZE
          )
        end

        def line_number_padding_size
          @line_number_padding_size ||= ((line_number - 1)..(line_number + 1)).map { _1.to_s.length }.max
        end

        def padded_line_number(number)
          pad_left(number.to_s, line_number_padding_size)
        end

        def pad_left(str, length)
          while str.length < length
            str = " " + str
          end
          str
        end

        class Line
          class << self
            def from_offset(file, offset)
              new(file.start_of_line(offset), file.end_of_line(offset))
            end
          end

          attr_reader :start_offset, :end_offset
          def initialize(start_offset, end_offset)
            @start_offset = start_offset
            @end_offset = end_offset
          end

          def context_bounds(offset, size)
            line_offset = offset - start_offset
            min = [start_offset, offset - size].max
            max = [end_offset, offset + size].min
            (min..max)
          end

          def line_offset(absolute_offset)
            absolute_offset - start_offset
          end
        end
      end
    end

    class ScriptFile < File
      def initialize(contents)
        @contents = contents
        @path = "<script>"
      end
    end

    class RealFile < File
      def initialize(path)
        @path = path
        @contents = ::File.read(path)
      end
    end
  end
end
