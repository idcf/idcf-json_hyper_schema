# Idcf::JsonHyperSchema

Analysis of json-hyper-schema

## Supported Draft Version(s)
  - draft-4

## Installation

Note: requires Ruby 2.2.7 or higher.

```
gem 'idcf-json_hyper_schema'
```

And then execute:

```
$ bundle
```

Or install it yourself as:

```
$ gem install idcf-json_hyper_schema
```

## Usage

### How to Expand 
```
bin/json_expand [path] > [output path]
```

### load
```
require 'idcf/json_hyper_schema'

path = File.expand_path('./sample.json')
p Idcf::JsonHyperSchema::Analyst.new.load(path)
```

### expand
```
require 'idcf/json_hyper_schema'

path       = File.expand_path('./sample.json')
j          = JSON.parse(File.read(path))
expand_obj = Idcf::JsonHyperSchema::Analyst.new.expand(j)
p expand_obj.schema
```

### expand options

| name | type | default | description |
| ---- | ---- | ---- | ---- |
| global_access | boolean | true | '$ref' but when showing outside, is it acquired?  |


### links
```
require 'idcf/json_hyper_schema'

path    = File.expand_path('./sample.json')
p Idcf::JsonHyperSchema::Analyst.new.load(path).links
```

or

```
require 'idcf/json_hyper_schema'

path = File.expand_path('./sample.json')
j    = JSON.parse(File.read(path))
p Idcf::JsonHyperSchema::Analyst.new.schema_links(j)
```

## How to Use the Link Object

| Q | example | note |
|:---|:---|:---|
| description | link.description |  |
| title | link.title |  |
| method | link.method | Returned in lower case |
| How do I know the right method to use? | link.method?('get') | Case insensitive |
| How can I get a replaceable URL? | link.href |  |
| Can I get a list of replacement parameters for URLs? | link.url_param_names | /api/{name}/{sec}{?hoge} : ["name", "sec"] |
| Can I get a list of get parameters? | link.query_param_names | /api/{name}/{sec}{?hoge} : ["hoge"] |
| Can I get a parameter information? | link.properties |  |
| What can I do when I want to know what are required information? | link.required |  |
| How can I create a URL by handing over parameters? | link.make_uri(['aaa'], { 'hoge' => 'h_param' }) | api/{name}{?hoge} -> api/aaa?hoge=h_param |
| How can I create a POST parameter by handing over parameters? | link.make_params({ 'hoge' => 'h_param' }) | { 'hoge' => 'h_param' } |

## shema example

### post
```post example
{
  "$schema": "http://json-schema.org/draft-04/schema#",
  "title": "sample",
  "description": "",
  "definitions": {},
  "properties": {
    "test": {
      "links": [
        {
          "title": "sample",
          "description": "",
          "href": "/api/{name}",
          "method": "post",
          "rel": "self",
          "schema": {
            "properties": {
              "hoge": {
                "type": "string"
              }
            }
          },
          "targetSchema": {
            "example": {},
            "properties": {}
          }
        }
      ]
    }
  }
}
```

### get

```get example
{
  "$schema": "http://json-schema.org/draft-04/schema#",
  "title": "sample",
  "description": "",
  "definitions": {},
  "properties": {
    "test": {
      "links": [
        {
          "title": "sample",
          "description": "",
          "href": "/api/{name}{?hoge,piyo}",
          "method": "post",
          "rel": "self",
          "schema": {
            "properties": {}
          },
          "targetSchema": {
            "example": {},
            "properties": {}
          }
        }
      ]
    }
  }
}
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

1. Fork it ( https://github.com/idcf/idcf-json_hyper_schema/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
