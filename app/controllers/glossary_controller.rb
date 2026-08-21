# frozen_string_literal: true

class GlossaryController < ApplicationController
  def show
    render inertia: "Glossary/Show"
  end
end
