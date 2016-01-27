# frozen_string_literal: true
class TestResponderApp
  def self.call(*_args)
    [200, {}, ['target']]
  end
end

Rails.application.routes.draw do
  mount TestResponderApp, :at => '/target'
end
