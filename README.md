# StripeMigrant

Welcome to your new StripeMigratnt! StripeMigrant will enable you to migrate the contents of one stripe account to another stripe account.  See `./examples` to learn more or run `bin/console` for an interactive prompt.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'stripe_migrant'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install stripe_migrant

## Usage

see `./examples` on how best to use the gem

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Development TODO
Currently products/plans/coupons/customers actions are lengthly and combersome code embedded in `migrator.rb` file.  These should be refactored to individual classes, similar to the `subscription.rb` class.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/stripe_migrant. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the StripeMigrant project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/stripe_migrant/blob/master/CODE_OF_CONDUCT.md).
