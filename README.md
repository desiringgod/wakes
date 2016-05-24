# Wakes

Welcome to your new gem! In this directory, you'll find the files you need to be able to package up your Ruby library into a gem. Put your Ruby code in the file `lib/wakes`. To experiment with that code, run `bin/console` for an interactive prompt.

TODO: Delete this and the text above, and describe your gem

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'wakes'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install wakes

## Usage

TODO: Write usage instructions here

### Social metrics updating

Wakes can query Google Analytics and Facebook to get updated pageview and share counts, respectively, for wakes locations. Wakes relies on several environment variables:

- `ENV['DEFAULT_HOST']`
- `ENV['FACEBOOK_API_TOKEN']`
- `ENV['GOOGLE_ANALYTICS_START_DATE']` - the date from which you wish to start pageview counts
- `ENV['GOOGLE_PRIVATE_KEY']`
- `ENV['GOOGLE_CLIENT_EMAIL']`
- `ENV['GOOGLE_ANALYTICS_PROFILE_ID']`

In addition, if you are using Wakes to query Google Analytics data across multiple GA profiles, you should specify these profile IDs by hostname in a `configure` block. This can be helpful if you are using Wakes to aggregate metrics for resources accessible across multiple hosts. Each host will have its own GA profile, but Wakes will still aggregate the social metrics to a single wakes resource.

Here is an example `config/initializers/wakes.rb`:

```ruby
Wakes.configure do |config|
  config.ga_profiles = {
    'default' => ENV['GOOGLE_ANALYTICS_PROFILE_ID'],
    'some-other-subdomain.myhost.com' => ENV['GOOGLE_ANALYTICS_SJ_PROFILE_ID']
  }
end
```

During metrics updating, Wakes will look up the GA profile, using the host of the wakes location as the key. If the wakes location's `host` is blank or if it matches `ENV['DEFAULT_HOST']`, then wakes will use the `default` profile from the configure block.

Note that Wakes locations with a non-default, non-blank host _must_ have a corresponding Google Analytics profile in the configuration block in order to update.


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/wakes.

