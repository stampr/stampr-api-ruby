Stampr
======

TODO: Write a gem description

Author: Bil Bas (bil.bas.dev@gmail.com)

License: MIT


Installation
------------

Add this line to your application's Gemfile:

```ruby
gem 'stampr'
```

And then execute:

```bash
$ bundle
```

Or install it yourself as:

```bash
$ gem install stampr
```

Usage
-----

Example of sending a letter via the simple API:

```ruby
require 'stampr'

stampr = Stampr::Client.new "username", "password"

stampr.send my_address, dest_address_1, body

stampr.send my_address, dest_address_2, body
```

More complex example:

```ruby
require 'stampr'

config = Stampr::Config.new
config.create

batch = Stampr::Batch.new config
batch.create

Mailing.new batch: batch do |m|
  m.to = to
  m.from = from
  m.body = body
end

```


Contributing
------------

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
