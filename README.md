Stampr
======

Wrapper for the Stampr API.

Author: Bil Bas (bil.bas.dev@gmail.com)

Site: https://github.com/stampr/stampr-api-ruby

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

Stampr.authenticate "username", "password"

Stampr.mail my_address, dest_address_1, body1

Stampr.mail my_address, dest_address_2, body2
```

Using mail-merge with [Mustache template](http://mustache.github.io/):

```ruby
require 'stampr'

Stampr.authenticate "username", "password"

Stampr::Batch.new do
  template "<html>Hello {{name}}!</html>"

  mailing do
    address dest_address_1
    return_address my_address
    data name: "Marie"
  end

  mailing do
    address dest_address_2
    return_address my_address
    data name: "Romy"
  end
end

```

More complex example:

```ruby
require 'stampr'

Stampr.authenticate "username", "password"

# Config can be shared by batches.
config = Stampr::Config.new

# Batches contain one or more mailings.
Stampr::Batch.new config: config do
  mailing do
    address dest_address_1
    return_address my_address
    data body1
  end

  mailing do
    address dest_address_2
    return_address my_address
    data body2
  end
end

```

Complex example without using blocks:

```ruby
require 'stampr'

Stampr.authenticate "username", "password"

# Config can be shared by batches.
config = Stampr::Config.new
config.create

# Batches contain one or more mailings.
batch = Stampr::Batch.new config: config
batch.create

mailing1 = Mailing.new batch: batch
mailing1.address = dest_address_1
mailing1.return_address = my_address
mailing1.data = data1
mailing1.mail

mailing2 = Mailing.new batch: batch
mailing2.address = dest_address_2
mailing2.return_address = my_address
mailing2.data = data2
mailing2.mail

```


Contributing
------------

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
