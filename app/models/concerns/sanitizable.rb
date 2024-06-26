module Sanitizable
  extend ActiveSupport::Concern

  included do
    private

    def smart_titleize(sentence)
      sentence.split.map do |word|
        (word == word.upcase) ? word : word.downcase.capitalize
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
        (word == word.upcase) ? word : word.downcase.capitalize
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
