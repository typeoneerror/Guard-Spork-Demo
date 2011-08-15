Getting set up to test a Rails app with [Rspec](https://github.com/dchelimsky/rspec-rails) is relatively straightforward. One of the troubles is the length of time it takes for the tests to run when issuing either the `rspec spec` from the command line. My current tests for example take about **¡16 seconds!** to complete. Also, who wants to switch back to the command line to run the tests. What if we could automating the tests and speed them up at the same time? Enter [**Guard**](https://github.com/guard/guard) and [**Spork**](https://github.com/timcharper/spork).

Guard is a command line tool that, when running, responds to events when files are modified. We can start Guard and have it observe certain files for changes, then run the Rspec commands in response. Using Spork, we can in effect pre-load the Rails environment into the Spork test server. Spork manages a pool of test processes for you so each test is clean (but fast because of the pre-load).

You can add these items to your existing rails app, but I'm going to take us through doing this from scratch (mainly so I can have documentation for this myself for future apps!).

## Get Started

I've created a demo app to go along with this article. You can grab it on github at <https://github.com/typeoneerror/Guard-Spork-Demo> or create your own.

Start by creating a Rails project and moving into it:

    $ rails new guard-spork
    $ cd guard-spork

We only need a handful of gems and a config file or too to get this going. Let's start by editing our *Gemfile* to add Rspec for Rails and Spork (this file shown with the initial comments removed):

<pre>
source 'http://rubygems.org'

gem 'rails', '3.0.9'

gem 'sqlite3'

group :development, :test do
  <strong># Rspec
  gem 'rspec-rails', '~> 2.6'

  # Spork
  gem 'spork'</strong>
end
</pre>

Add the gems to your Gemfile and then run

    bundle install

The `~>` syntax is an interesting one. Essentially, this is equivalent to `>= 2.6 AND < 2.7`. So it'll install the latest version of the 2.6 (so 2.6.5 would install if that was the latest, but it would not update to 2.7).

Anyway, now that the gems are installed, we need to bootstrap Rspec. Command line again:

    $ rails generate rspec:install
          create  .rspec
          create  spec
          create  spec/spec_helper.rb

I then add the following snippet to *config/application.rb* to tell the Rails app to use Rspec as my test generator:

    config.generators do |g|
      g.test_framework :rspec
    end

Running `rake -T spec` at this point should display a series of rake task for `rspec`. You can skip the rake way of doing it and use Rspec directly though. Let's create a sample model to test.

    $ rails g model Article title:string
          invoke  active_record
          create    db/migrate/20110814231432_create_articles.rb
          create    app/models/article.rb
          invoke    rspec
          create      spec/models/article_spec.rb

Note that it generated (`g` is an alias for `generate`) the model, a database migration and automatically added a spec for testing that model. Neat!

Let's create our database (sqlite3 since we're just doing a demo which is the default Rails database):

    $ rake db:migrate
    ==  CreateArticles: migrating ================
    -- create_table(:articles)
       -> 0.0011s
    ==  CreateArticles: migrated (0.0012s) =======

Great, we've got our initial database. Let's add a simple validation for that model:

    # app/models/article.rb
    class Article < ActiveRecord::Base
      validates :title, :presence => true
    end

Just for example's sake, let's add a two simple (and largely pointless) tests to our spec in *spec/models/article_spec.rb*:

    require 'spec_helper'

    describe Article do

      it 'should test some silly thing that will pass' do
        @article = Article.new(:title => 'The Title')
        @article.should be_valid
      end

      it 'should test some silly thing that will fail' do
        @article = Article.new
        @article.should be_valid
      end

    end

Now you can run

    $ rpsec spec

to test your app (this will run all your specs). Even with just these ridiculously simple tests, we can run

    $ time rpsec spec
    real	0m3.017s

and this thing is taking 3 seconds already! Imagine what happens when you've got hundreds of tests.


## Spork

So let's see what Spork can do for us. Start by bootstrapping Spork from the command line:

    $ spork --bootstrap
    ...
    Using RSpec
    Bootstrapping spec/spec_helper.rb.
    Done. Edit spec/spec_helper.rb now with your favorite text editor and follow the instructions.

Looks like we should edit *spec/spec_helper.rb* with our favorite text editor. Spork added a few blocks.  In summary, anything in the `Spork.prefork` block gets pre-loaded and anything in the `Spork.each_run` block will be done on each test run.

I'm basically going to grab everything that was previously in this file (the Rspec stuff that should not be towards the bottom of this file) and drop it into the `prefork` block:

    require 'rubygems'
    require 'spork'

    Spork.prefork do

      # This file is copied to spec/ when you run 'rails generate rspec:install'
      ENV["RAILS_ENV"] ||= 'test'
      require File.expand_path("../../config/environment", __FILE__)
      require 'rspec/rails'

      # Requires supporting ruby files with custom matchers and macros, etc,
      # in spec/support/ and its subdirectories.
      Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

      RSpec.configure do |config|
        # Mock Framework
        config.mock_with :rspec

        # If you're not using ActiveRecord, or you'd prefer not to run each of your
        # examples within a transaction, remove the following line or assign false
        # instead of true.
        config.use_transactional_fixtures = true
      end

    end

    Spork.each_run do
      # This code will be run each time you run your specs.
    end

We're also going to set up Rspec to use Spork DRB server. Open up .rspec and add the following:

    --colour
    --drb
    --format documentation

Next start Spork in a new Terminal window (in your project directory):

    $ spork
    ...
    Using RSpec
    Loading Spork.prefork block...
    Spork is ready and listening on 8989!

Basically, now we've got Spork DRB running and now when we run Rspec, it's configured to use the running DRB server. With Spork running, switch back to your project and run Rspec again:

    $ time rspec spec
    real	0m0.499s

Wow. We've basically decreased our test runtime by ~85%. You can just leave Spork running until you're finished working then send it a ^C command to quit.

Should we take a break? Nah, let's get this testing thing automated so we can *can* take more breaks. A lazy developer is a good developer, right?


## Guard

Next, let's add Guard and some of its really cool "extensions" that allow us to "guard" (or watch and respond to changes in) resources. Edit your Gemfile (this is where our Gemfile starts to get kinda wordy):

<pre>
source 'http://rubygems.org'

gem 'rails', '3.0.9'

gem 'sqlite3'

group :development, :test do
  # Rspec
  gem 'rspec-rails', '~> 2.6'

  # Spork
  gem 'spork'

  # Guard
  gem 'growl'
  <strong>gem 'rb-fsevent', :require => false if RUBY_PLATFORM =~ /darwin/i
  gem 'guard-bundler'
  gem 'guard-rspec'
  gem 'guard-spork'</strong>
end
</pre>

Taking a look at our Guard includes now, you can see I've added `guard-rspec`. This gem bundles `guard` as a dependency, so there's no need to include the `guard` gem itself. I've also included the "guards" for `bundler` and `spork`. `rb-fsevent` is required to respond to <a href="http://en.wikipedia.org/wiki/FSEvents" title="FSEvents - Wikipedia, the free encyclopedia">changes in a directory tree</a>. Keep in mind, this is how to do this on Mac OSX, so if you need a different platform, the <a href="https://github.com/guard/guard">install instructions for Windows and Linux on Github</a> are quite straightforward.

> Growl can be added as well if you want to show Growl messages when your tests finish running. I find this pretty useful, but a lot of people can't stand Growl. Keep in mind you have to install the <a href="http://growl.info/extras.php" title="Growl - Extras">growlnotify extra</a> from the Growl .dmg for this gem to work. Note that it took me awhile to get growl going. guard-rpsec notes using the growl gem and guard recently changed this to growl_notify, so it seems pretty volatile. Growl seems to work great if you're just running the Rspec guard, but I haven't been able to get it to notify me when running Rspec through Spork. Please message me on [Twitter](https://twitter.com/#!/typeoneerror) if you have a way of doing this.

Back to command line; let's install the next set of gems:

    $ bundle install

Next generate a Guardfile via the command:

    $ guard init
    Writing new Guardfile to guard-spork/Guardfile

Staring guard is easy, but first we have to create some guards in our Guardfile. Here's a starter file for you that I am using:

    guard 'spork', :cucumber => false, :test_unit => false do

      watch('config/application.rb')
      watch('config/environment.rb')
      watch(%r{^config/environments/.+\.rb$})
      watch(%r{^config/initializers/.+\.rb$})
      watch('spec/spec_helper.rb')

    end


    guard 'bundler' do

      watch('Gemfile')
      # Uncomment next line if Gemfile contain `gemspec' command
      # watch(/^.+\.gemspec/)

    end


    guard 'rspec' do

      watch(%r{^spec/.+_spec\.rb$})
      watch(%r{^app/(.+)\.rb$})                           { |m| "spec/#{m[1]}_spec.rb" }
      watch(%r{^lib/(.+)\.rb$})                           { |m| "spec/lib/#{m[1]}_spec.rb" }
      watch(%r{^spec/factories/(.+)\.rb$})                { "spec" }
      watch(%r{^spec/models/.+\.rb$})                     { "spec/models" }
      watch(%r{^spec/routing/.+\.rb$})                    { "spec/routing" }

      watch('spec/spec_helper.rb')                        { "spec" }
      watch('config/routes.rb')                           { "spec/routing" }
      watch('app/controllers/application_controller.rb')  { "spec/controllers" }

    end

The above configures each guard (remember we installed the -rspec, -spork and -bundler guard gems?) to watch certain files (by path or regular expression matching) and perform actions when those files change. For example, in our Rspec guard, we're watching *spec/spec_helper.rb* and when it changes "spec" is going to be called. So basically, save a spec and your tests will be run automatically.

The bundler guard file watches your Gemfile for changes and <code>bundle install</code>'s when it is saved. And now the Spork server is restarted any time we make configuration file changes. Guard even starts Spork for us so we no longer have to issue the <code>spork</code> command at the command line, just:

    $ guard
    ...
    Using RSpec
    Loading Spork.prefork block...
    Spork is ready and listening on 8989!
    Spork server for RSpec successfully started
    ...
    Refresh bundle
    Your bundle is complete!
    ...
    Guard::RSpec is running, with RSpec 2!
    Running all specs
    ...
    Finished in 0.10119 seconds
    2 examples, 1 failure

So there you have it, guard is running, listening for changes and Spork has started and has our Rspec/Rails stuff pre-loaded. If you go an edit spec/models/article_spec.rb now...

<pre>
require 'spec_helper'

describe Article do

  it 'should test some silly thing that will pass' do
    @article = Article.new(:title => 'The Title')
    @article.should be_valid
  end

  it 'should test some silly thing that will <strong>now pass</strong>' do
    @article = Article.new
    <strong>@article.should_not be_valid</strong>
  end

end
</pre>

...guard will note the changes and run spec to run your tests. Everything should now pass.

So there you have it. Your tests should now run pretty damn fast. Full disclosure, this is my first time working with Rails and gems so I may have done some things somewhat ass-backwards. I'd appreciate any comments you might have to that effect on my [Twitter](https://twitter.com/#!/typeoneerror) account. Please don't hesitate to [send me feedback](https://twitter.com/intent/tweet?text=@typeoneerror) there.