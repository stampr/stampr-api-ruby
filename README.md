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

### Example of sending letters via the simple API

In this case, all mailings will be in individual batches and with default config.

```ruby
require 'stampr'

Stampr.authenticate "username", "password"

Stampr.mail my_address, dest_address_1, body1

Stampr.mail my_address, dest_address_2, body2
```

### More complex example

Managing config and grouping mailings into a single batch.

```ruby
require 'stampr'

Stampr.authenticate "username", "password"

# Config can be shared by batches.
config = Stampr::Config.new

# Batches contain one or more mailings.
Stampr::Batch.new config: config do |b|
  b.mailing do |m|
    m.address = dest_address_1
    m.return_address = my_address
    m.data = body1
  end

  b.mailing do |m|
    m.address = dest_address_2
    m.return_address = my_address
    m.data = body2
  end
end
```

And without using blocks:

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

### Browsing configs

```ruby
config = Stampr::Config[123123]
configs = Stampr::Config.all
```

### Browsing batches

```ruby
batch = Stampr::Batch[2451]

time_period = Time.new(2012, 1, 1, 0, 0, 0)..Time.now

batches = Stampr::Batch[time_period]
batches = Stampr::Batch[time_period, status: :processing]
```

### Updating batches

```ruby
batch = Stampr::Batch[2451]
batch.status = :archive
```

### Deleting batches

```ruby
Stampr::Batch[2451].delete
```

### Browsing mailings

```ruby
mailing = Stampr::Mailing[123123]

time_period = Time.new(2012, 1, 1, 0, 0, 0)..Time.now
my_batch = Stampr::Batch[1234]

mailings = Stampr::Mailing[time_period]
mailings = Stampr::Mailing[time_period, status: :processing]
mailings = Stampr::Mailing[time_period, batch: my_batch]
mailings = Stampr::Mailing[time_period, status: :processing, batch: my_batch]
```

### Deleting mailings

```ruby
Stampr::Mailing[2451].delete
```

### Using mail-merge with [Mustache template](http://mustache.github.io/)

```ruby
require 'stampr'

Stampr.authenticate "username", "password"

Stampr::Batch.new do |b|
  b.template = "<html>Hello {{name}}, would you like to buy some {{items}}!</html>"

  b.mailing do |m|
    m.address = dest_address_1
    m.return_address = my_address
    m.data = { name: "Marie", items: "electric eels" }
  end

  b.mailing do |m|
    m.address = dest_address_2
    m.return_address = my_address
    m.data = { name: "Romy", items: "scintillating hackers" }
  end
end
```


Contributing
------------

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
