sequel-schema-sharding
======================

[![Gem Version](https://badge.fury.io/rb/sequel-schema-sharding.png)](http://badge.fury.io/rb/sequel-schema-sharding)
[![Build Status](https://travis-ci.org/wanelo/sequel-schema-sharding.png?branch=master)](https://travis-ci.org/wanelo/sequel-schema-sharding)
[![Code Climate](https://codeclimate.com/github/wanelo/sequel-schema-sharding.png)](https://codeclimate.com/github/wanelo/sequel-schema-sharding)

Horizontally shard PostgreSQL tables with the Sequel gem, where each shard
lives in its own PostgreSQL schema.

This gem allows you to configure mappings between logical and physical shards, pooling
connections between logical shards on the same physical server.


## Installation

Add this line to your application's Gemfile:

    gem 'sequel-schema-sharding'

And then execute:

    $ bundle


## Usage

See the `examples` directory for example files.

### Configuration

Create a sharding configuration file in your project, for instance at
`config/sharding.yml`. The format should match the following
conventions:

```yml
<env>:
  tables:
    <table_name>:
      schema_name: "schema_%04d"
      logical_shards:
        <shard_name>: <1..n>
        <shard_name>:<n+1..m>
  physical_shards:
    <shard_name>:
      host: <hostname>
      database: <database>
  common:
    username: <pg_username>
    password: <pg_password>
    port: <pg_port>
    connect_timeout: 2
```

In schema names `%04d` is a ```sprintf``` pattern (http://www.ruby-doc.org/core-2.0.0/Kernel.html#method-i-sprintf), where
%d is expanded by passing the shard number. Using the pattern you can zero-pad the shard number, or use another
pattern that suites your environment.

Tables can coexist in schemas, though they do not have to.

In your project, configure `sequel-schema-sharding` in a ruby file that
gets loaded before your models, for instance at `config/sharding.rb`.

```ruby
require 'sequel-schema-sharding'

Sequel::SchemaSharding.migration_path = File.expand_path('../../db/sharding_migrations', __FILE__)
Sequel::SchemaSharding.sharding_yml_path = File.expand_path('../sharding.yml', __FILE__)
```

### Migrations

Each table gets its own set of migrations. Underneath the scenes,
`sequel-schema-sharding` uses Sequel migrations, though migrations are
run using the `Sequel::SchemaSharding::DatabaseManager` class.

For instance, if you have two sharded tables, `:artists` and `:albums`,
your migration folder would look something like this:

```yml
- my_project
  - db
    - migrations
      - artists
        - 001_create_artists.rb
        - 002_add_indexes_to_artists.rb
      - albums
        - 001_create_albums.rb
```

See Sequel documentation for more info:
* (http://sequel.rubyforge.org/rdoc/files/doc/schema_modification_rdoc.html)
* (http://sequel.rubyforge.org/rdoc/files/doc/migration_rdoc.html)

TODO: rake tasks for running migrations

### Read/write splitting

Sequel supports read/write splitting, but sequel-schema-sharding needs a
few modifications in order to work with horizontal sharding. In order to
use read/write splitting across shards, the following configuration can
be used in your `sharding.yml`:

```yml
<env>:
  tables:
    <table_name>:
      schema_name: "schema_%04d"
      logical_shards:
        <shard_name>: <1..n>
        <shard_name>:<n+1..m>
  physical_shards:
    <shard_name>:
      host: <hostname>
      database: <database>
      replicas:
        <replica_name>:
          host: <hostname>
          database: <database>
          ...
  common:
    username: <pg_username>
    password: <pg_password>
    port: <pg_port>
```

Replica configuration is merged into common attributes, so are redundant
if they are not different from the master. Replica attributes take priority,
however, so if you use a proxy such as PGBouncer, you can specify a different
local database name.

See http://sequel.rubyforge.org/rdoc/files/doc/sharding_rdoc.html for more
information.

Note that `sequel-schema-sharding` depends on the `sequel-replica-failover`
gem. This means that when making queries to `:read_only` servers (i.e.
replicas), certain connection errors will be rescued and re-run against
another `:read_only` server. It may be advantageous to include each master
database among its replicas, to ensure that read failures on a replica are
re-run against the master.

### Models

Models declare their table in the class definition. This allows Sequel
to load table information from the database when the environment loads.
This is particularly important for typecasting, so empty strings can be
typecast to null, etc.

The tricky bit is that `sequel-schema-sharding` connects to the first
available shard for a table in order to read the database schema.

```ruby
require 'config/sharding'

class Artist < Sequel::SchemaSharding::Model('artists')
  set_columns [:id, :name]
  set_sharded_column :id

  def this
    @this ||= self.class.by_id(id)
  end

  def self.by_id(id)
    shard_for(id).where(id: id).first
  end
end

class Album < Sequel::SchemaSharding::Model('albums')
  set_columns [:artist_id, :name, :release_date, :created_at]
  set_sharded_column :artist_id

  def this
    @this ||= self.class.by_artist(artist_id)
  end

  def by_artist(artist_id)
    shard_for(artist_id).where(artist_id: artist_id)
  end

  def by_artist_and_name(artist_id, name)
    shard_for(artist_id).where(name: name, artist_id: artist_id)
  end
end
```

Note that logical and physical shards mapped in schema.yml need to exist
before you can load models into memory.

Read access always starts with the `:shard_for` method, to ensure that
the correct database connection and shard name is used. Writes will
automatically choose the correct shard based on the sharded column.
Never try to insert records with nil values in sharded columns.

### this

You must define a `:this` instance method on your model. `:this` must
return a dataset that is scoped to the current instance in the database,
so that Sequel can update/delete/etc the record when you call methods on
the instance that persist, ie `:destroy`, `:save`.

## Read/write splitting

When using this in conjunction with multiple replicas, you should call `read_only_shard_for`
instead of `shard_for` when running a select query. This will ensure that anything that needs
a valid connection while the query is being built will go to a `:read_only` server.

This can be helpful when combined with server failover logic, to ensure that read
queries do not try to reconnect to a downed master.

## Running tests

```bash
> bundle install
> bundle exec rake reset
> bundle exec rspec
```

The default max file descriptor limit on Macs is tragically low. If tests
fail with `too many open files`, you can run `ulimit -n 2048` to raise the
limit.

## FAQ

### How should I shard my databases?

This is entirely dependent on the access patterns of your application. A
good rule, though, is to look at your indexes. If every query goes
through an index on `:user_id`, then chances are that you should shard
on `:user_id`. If half of your queries go through `:user_id` and the
other half go through `:job_id`, then you may need to create two sets of
shards, each with its own model, and have your application write to
both. This requires additional application complexity to keep the two
sets of shards in sync—it's less complex than doing multi-shard reads to
keep everything in one model, though.

When going into database sharding, an early exercise that is very
helpful is to analyze application queries and try to reduce the number
of unique queries. If possible, try to refactor queries such that they
fit into the smallest number of shard types. For instance, if you find
Albums by release year, but every action you query from already has the
`:artist_id`, consider changing your query to find by `:artist_id` and 
release year.

### How should I generate IDs?

This is also dependent on your application and your comfort level with
various technologies, but regardless should be done outside
of `sequel-schema-sharding`. In general there are three approaches that
we've considered:

* Follow Instagram's approach and let PostgreSQL generate ids. They
  install functions into each shard, to ensure that each shard generates
  unique ids.

* Follow Twitter's approach and deploy a separate service for unique id
  generation. Their in-house solution is called Snowflake, and depends
  on maven, finagle and thrift.

* Why use ids at all? If you are sharding Like data or something that
  looks similar to a join table, you may not need a unique identifier.
  You are probably sharding on a foreign key to some other table, and
  may not ever access individual Likes by id.

### Should each table get its own set of shards/schemas?

In the early days of a project's lifetime, it may seem like less
management overhead to let multiple tables coexist in each shard.
Experience with sharding in other technologies (particularly Redis) have
shown us that in any sharded data store, you will eventually need
to redistribute shards. More data equals larger storage and RAM
requirements, and as servers fill up you will find yourself needing to
move shards onto a greater number of servers. If your project is
successful, this may come much sooner than you expect in initial
infrastructure planning meetings.

Colocating multiple data sets in individual shards makes shard
redistribution more complicated and risk-prone. More things break when
an individual shard goes down. Pages or queries that depend on an
individual data set will stop working when you take down shards to do
maintenance on other data sets.

Simply put, it's less stressful when doing operational maintenance to
require twice as many steps that are each easier and less risk-prone.
So, do whatever you feel is best, but we've chosen to make each shard
single-purpose in our infrastructure.

### Sequel does sharding. Why another gem?

The sharding plugin that ships with Sequel assumes that each shard is a
separate database. This means that each shard requires a separate
connection pool, and that each shard includes every table. When
splitting a database into thousands of shards, this means that each
application process requires thousands of connections. A proxy such as
PGBouncer could help reduce the number of connections from an individual
application server, but even then PGBouncer would need to manage thousands 
of connections.

When designing a sharded architecture similar to Instagram's approach 
(http://instagram-engineering.tumblr.com/post/10853187575/sharding-ids-at-instagram),
it may be desirable to start with thousands or tens of thousands of shards,
to delay the need for resharding as long as possible. PostgreSQL is able
to manage tens of thousands of schemas in a single database without
significant performance problems, so we can design a sharded backend of
thousands of shards living on a few physical servers. As stored data
grows, these shards can be moved onto a greater number of servers,
without the complication of resharding (i.e. changing the number of
shards while retaining the exact mapping of data into old shards).

### Why Sequel?

After both good and bad experiences with other Ruby ORMs, Sequel's
documentation, ease of use and understandable codebase made it a solid
choice for us. The fact that it already supports horizontal sharding and
was easy to adapt to our own requirements were a pleasant surprise.

### What the what?? def self.Model; ???

Yeah, this threw us for a while, too. The thing is, ORMs in Ruby tend to
load information like column info, indexes, etc directly from the
connected databases, rather than from local schema dictionaries. In
order to do this, databases need to be created and migrations run BEFORE
model files can validly loaded.

If the ORM doesn't load this info from somewhere, then it can't
correctly do things like typecast string HTTP params to integers (or
nulls).

Rather than monkeypatching our way around this requirement in Sequel, we
ride the wave and just patch in our additions.

### What could go wrong?

The thing that you never want to happen is to change the mapping of
shards to data. For instance, if you change the number of shards without
migrating data into a new database backend, the algorithm by which
schemas are chosen will start returning a different mapping for reads than
that which was used to insert data. New records will go into the new
mapping, but any attempt to read a record inserted via the old mapping
will pick the wrong shard and return an empty set. DON'T EVER DO THIS.
It's really embarrassing.

### Any problems with other services?

When integrating with NewRelic, *do not* enable the SQL query plan
instrumentation. It can grab a connection that your application is also
trying to use... libpq is thread safe, so long as two threads do not
try to manipulate the same PGonn object
(http://www.postgresql.org/docs/9.3/static/libpq-threading.html).
If you see errors such as `PG::UnableToSend: insufficient data in "T" message`
or `PG::UnableToSend: extraneous data in "T" message`, this can indicate that
multiple threads are accessing the same connection, and data (or random bytes)
may have been transposed between queries.


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

Contributors
============

* [James Hart](https://github.com/hjhart)
* [Paul Henry](https://github.com/f3nry)
* [Eric Saxby](https://github.com/sax)
* [Konstatin Gredeskoul](https://github.com/kigster)
