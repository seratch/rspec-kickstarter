# frozen_string_literal: true

require 'singleton'

module RSpecKickstarter
  # Global configuration affecting all threads.
  class Config
    include Singleton

    attr_accessor :behaves_like_exclusions

    def initialize
      @behaves_like_exclusions = []
    end
  end
end
