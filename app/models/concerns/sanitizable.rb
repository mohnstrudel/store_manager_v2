module Sanitizable
  extend ActiveSupport::Concern

  included do
    private

    def smart_titleize(sentence)
      sentence.split.map do |word|
        if word == word.upcase
          word
        else
          # Handle hyphenated words by capitalizing each part
          word.downcase.split("-").map(&:capitalize).join("-")
        end
      end.join(" ")
    end

    def sanitize(string)
      string
        .tr(" ", " ")
        .gsub(/—|–/, "-")
        .gsub("&amp;", "&")
        .split("<span>")[0]
        .split("|")
        .map { |s| s.strip }
        .join(" | ")
    end
  end

  class_methods do
    private

    def smart_titleize(sentence)
      sentence.split.map do |word|
        if word == word.upcase
          word
        else
          # Handle hyphenated words by capitalizing each part
          word.downcase.split("-").map(&:capitalize).join("-")
        end
      end.join(" ")
    end

    def sanitize(string)
      string
        .tr(" ", " ")
        .gsub(/—|–/, "-")
        .gsub("&amp;", "&")
        .split("<span>")[0]
        .split("|")
        .map { |s| s.strip }
        .join(" | ")
    end
  end
end
