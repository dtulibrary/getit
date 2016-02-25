# GetIt

GetIt is a document delivery microservice for FindIt built using Sinatra.

# Installation

Clone the repository and run `bundle install`. Run the server using `thin start`. If you want to run FindIt against your local version you can use the mother-docker FindIt and change the url in FindIt's `application.rb`. You can then run your local GetIt on a specific port, e.g. `thin start -p 3003`.

# Tests

Tests are written in Minitest using Webmock to stub HTTP requests. You can run all tests by simply using the `m` command. You can also run individual tests by line number as you would in rspec, for example: `m spec/controllers/resolve_controller_spec.rb:32` where the line number refers to the start of an `it` block.

## Gotchas

Running tests against ResolveController gives some curious multithreading errors. If you need to test against ResolveController, remove the EventMachine iterator and replace with a simpler iterator as described in the comments.
