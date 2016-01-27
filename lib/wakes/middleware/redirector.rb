# frozen_string_literal: true
module Wakes
  module Middleware
    class Redirector
      def initialize(app)
        @app = app
      end

      def call(env)
        request = Rack::Request.new(env)
        path = request.fullpath

        if target = Wakes::REDIS.get(path)
          redirect(path, target)
        else
          @app.call(env)
        end
      end

      def redirect(from, to)
        puts "[Wakes::Middleware::Redirector] redirecting from #{from} to #{to}"
        [
          301,
          {'Location' => to, 'Content-Type' => 'text/plain'},
          ["Memoized redirect from #{from} to #{to}"]
        ]
      end
    end
  end
end
