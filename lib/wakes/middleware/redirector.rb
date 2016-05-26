# frozen_string_literal: true
module Wakes
  module Middleware
    class Redirector
      def initialize(app)
        @app = app
      end

      def call(env)
        request = Rack::Request.new(env)

        calculate_target_and_redirect(request) || @app.call(env)
      end

      def calculate_target_and_redirect(request)
        if target = TargetCalculator.new(request).run
          redirect(request.fullpath, target)
        end
      end

      def redirect(from, to)
        puts "[Wakes::Middleware::Redirector] redirecting from #{from} to #{to}"
        [
          301,
          {'Location' => to, 'Turbolinks-Location' => to, 'Content-Type' => 'text/plain'},
          ["Memoized redirect from #{from} to #{to}"]
        ]
      end
    end

    class TargetCalculator
      attr_accessor :request

      def initialize(request)
        @request = request
      end

      # If no match is found, return so that the app can proceed down the call stack
      #
      # If a match is found, then we need to calculate the proper query string to redirect to.
      # We append to the target query string any params that are found in the request query string
      # but not in the potential query string that ended up matching to the target.
      # Thus, we pass through params that are not explicitly matched.
      #
      # For example, if the request was '/path?a=1&b=2&c=3' and the match was a redirect
      # from '/path?a=1' to '/target', then we would append the other 2 parameters to arrive
      # at the full target path of '/target?b=2&c=3'
      def run
        return unless match_found?

        target_path = potential_targets[target_index]
        target_query_string = subtract_query_strings(request.query_string, potential_query_strings[target_index])

        fullpath(target_path, target_query_string)
      end

      # THIS IS IMPORTANT
      #
      # We consider the first match in redis to be the target. In this respect, the ordering of the permutations
      # in #potential_query_strings is critical. There are potentially other matches that we disregard because
      # they are later in the array.
      #
      # Sometimes this is completely desirable. If the graph is { '/path?b=2' => '/target1', '/path' => '/target2' }
      # then you will always want '/path?b=2' to go to '/target1', not '/target2'. You will also always want
      # '/path?a=1&b=2' to go to '/target1', not '/target2'.
      #
      # Consider this graph: { '/path?b=2' => '/target1', '/path' => '/target2', '/path?a=1' => '/target3' }
      # Where should '/path?a=1&b=2' redirect to? There is no exact match ('/path?a=1&b=2' is not a key), and there
      # are two partial matches that match on the same number of params. THE REDIRECT HERE ENDS UP BEING DEPENDENT
      # ON THE IMPLEMENTATION OF #PERMUTATION, which may or may not return the same result every time (it appears to
      # in MRI2.3). It also has no "intended" result --- wakes cannot know which of these redirects is preferable.
      # Therefore, it is best to avoid creating graphs like this.
      #
      def target_index
        @target_index ||= potential_targets.index(&:present?)
      end

      # if any potential targets are found (meaning, if there is a match in redis),
      # then a match is found and this returns true
      #
      def match_found?
        potential_targets.any?
      end

      # remove one query string from another. For example:
      # 'a=1&b=2&c=3' - 'b=2' = 'a=1&c=3'
      # 'a=1&b=2&c=3' - 'c=3&b=2' = 'a=1'
      #
      def subtract_query_strings(first, second)
        (first.split('&') - second.split('&')).join('&')
      end

      # intelligently combine a path and a query string, adding '?' or '&' when appropriate
      def fullpath(path, query_string)
        return path if query_string.blank?

        conjunction = path.include?('?') ? '&' : '?'

        path + conjunction + query_string
      end

      # redis mget docs: http://redis.io/commands/mget
      #
      # For an array of potential fullpaths, return an array of redis mappings.
      #
      # The array will be mostly nils, with one or several non-nil values that correspond to
      # potential redirect targets.
      #
      # For example, say redis is populated with { '/path?b=2' => '/target1', '/path' => '/target2' }.
      # The following would be returned for a starting fullpath "/path?a=1&b=2&c=3'
      #
      # [
      #   nil, nil, nil,
      #   nil, nil, nil,
      #   nil, nil, nil,
      #   nil, nil, nil,
      #   nil, "/target1", nil,
      #   "/target2"
      # ]
      #
      def potential_targets
        @potential_targets ||= Wakes::REDIS.mget(potential_fullpaths)
      end

      # For a fullpath like "/path?a=1&b=2&c=3", an array similar to the following is returned:
      #
      # [
      #   "/path?a=1&b=2&c=3", "/path?a=1&c=3&b=2", "/path?b=2&a=1&c=3",
      #   "/path?b=2&c=3&a=1", "/path?c=3&a=1&b=2", "/path?c=3&b=2&a=1",
      #   "/path?a=1&b=2", "/path?a=1&c=3", "/path?b=2&a=1",
      #   "/path?b=2&c=3", "/path?c=3&a=1", "/path?c=3&b=2",
      #   "/path?a=1", "/path?b=2", "/path?c=3",
      #   "/path"
      # ]
      #
      def potential_fullpaths
        @potential_fullpaths ||= potential_query_strings.map do |query_string|
          fullpath(request.path, query_string)
        end
      end

      # For a query string like "a=1&b=2&c=3", an array similar to the following is returned:
      #
      # [
      #   "a=1&b=2&c=3", "a=1&c=3&b=2", "b=2&a=1&c=3",
      #   "b=2&c=3&a=1", "c=3&a=1&b=2", "c=3&b=2&a=1",
      #   "a=1&b=2", "a=1&c=3", "b=2&a=1",
      #   "b=2&c=3", "c=3&a=1", "c=3&b=2",
      #   "a=1", "b=2", "c=3",
      #   ""
      # ]
      #
      def potential_query_strings
        params = request.query_string.split('&')
        @potential_query_strings ||= (0..params.size).to_a.reverse.map do |n|
          params.permutation(n).map { |permutation| permutation.join('&') }
        end.flatten
      end
    end
  end
end
