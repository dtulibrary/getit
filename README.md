# GetIt

GetIt is a document delivery microservice for FindIt built using Sinatra. Its role is to query multiple services and create an aggregate response which FindIt can use to present users with different document access options.

## Installation

Clone the repository and run `bundle install`. Run the server using `thin start`. If you want to run FindIt against your local version you can use the mother-docker FindIt and change the url in FindIt's `application.rb`. You can then run your local GetIt on a specific port, e.g. `thin start -p 3003`.

## API

GetIt consumes an [OpenURL](https://en.wikipedia.org/wiki/OpenURL) which it parses and uses to query third party services such as Aleph, SFX, Metastore and NAL. A sample query might look like this:
```
http://getit.findit.dtu.dk/resolve?url_ver=Z39.88-2004&url_ctx_fmt=info:ofi/fmt:kev:mtx:ctx&ctx_ver=Z39.88-2004&ctx_tim=2016-02-26T10:52:46+01:00&ctx_id=&ctx_enc=info:ofi/enc:UTF-8&rft.genre=thesis&rft.atitle=Computational+and+Parametric+Design+for+Irregular+Column+Distribution&rft.au=Andersen,+Daniel+Kolling&rft.date=2016&rft_val_fmt=info:ofi/fmt:kev:mtx:thesis&rft_dat={"id":"275583250"}&rfr_id=info:sid/findit.dtu.dk&req_id=dtu_staff&svc_dat=fulltext&lastEventId=&r=8160476074684977
```
Responses are formatted as [Server Sent Events](https://html.spec.whatwg.org/multipage/comms.html#server-sent-events), for example:
```
data: {"url":"http://dtu-ftc.cvt.dk/cgi-bin/fulltext/sorbit?pi=%2F35600.769321.pdf&key=466544362","service_type":"fulltext","source":"metastore","subtype":"license_local","short_name":"Download","type":"Online","short_explanation":"Download from DTU Library for immediate reading","button_text":"Download","tool_tip":"Parametric Modelling for Point Support Optimisation of Plate and Shell Structures.pdf","icon":"icon-download","list_text":"Download"}

event: close
data: none

```
## Tests

Tests are written in Minitest using Webmock to stub HTTP requests. You can run all tests by simply using the `m` command. You can also run individual tests by line number as you would in rspec, for example: `m spec/models/services/metastore_spec.rb:32` where the line number refers to the start of an `it` block.

Note that running tests against ResolveController gives some curious multithreading errors. If you need to test against ResolveController, remove the EventMachine iterator and replace with a simpler iterator as described in the comments.

### Refactoring
GetIt is a crucial application in the FindIt infrastructure but it is unfortunately quite complex and difficult to understand. Some of this complexity is caused by the use of multithreading which is probably necessary for an application of its nature, but some complexity is a result of design decisions.

 - FindIt view logic should be extracted from this app. Translations have no place here. The API response should thus be simplified considerably. Instead of returning texts and icon names, we should instead return simplistic status codes, which FindIt can convert into views. 
 - The Service classes are confusing in that they are maintained before and after requests. Services should instead be functional with a static Client class for building the query and a static Response class for parsing the response. For example instead of a single `Metastore` class, we should have a `Metastore::Client` class and a `Metastore::Response` class. We might also have a `Metastore::Rules` class which would contain the business logic that makes decisions based on a combination of Metastore responses and the original request parameters.
 - There is too much business logic embedded in `if;else;end` clauses. It would be better to refactor these as methods in order to make the business logic clearer. For example:
  ```ruby
  if response.subtype.start_with?("license") && @reference.user_type == "public"
    response.url = "http://www.dtic.dtu.dk/english/servicemenu/visit/opening#lyngby"
  end
  ```

  Could be refactored as follows:
  ```ruby
  if Metastore::Rules.inaccessible_to_user?(response.subtype, @reference.user_type); ... end
  ```
  By making the business logic explicit in method names, we ease the maintenance cost. Static methods separate the logic from external state and make it easier.
