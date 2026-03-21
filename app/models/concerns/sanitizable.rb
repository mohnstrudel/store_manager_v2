# frozen_string_literal: true

module Sanitizable
  extend ActiveSupport::Concern

  included do
    private :smart_titleize, :sanitize
  end

  def smart_titleize(sentence)
    Sanitizable.smart_titleize(sentence)
  end

  def sanitize(string)
    Sanitizable.sanitize(string)
  end

  class_methods do
    private

    def smart_titleize(sentence)
      Sanitizable.smart_titleize(sentence)
    end

    def sanitize(string)
      Sanitizable.sanitize(string)
    end
  end

  class << self
    def smart_titleize(sentence)
      sentence.to_s.split.map do |word|
        if word == word.upcase
          word
        else
          word.downcase.split("-").map(&:capitalize).join("-")
        end
      end.join(" ")
    end

    def sanitize(string)
      string
        .to_s
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
