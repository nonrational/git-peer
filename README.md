# Git::Peer

Peer into your release diffs--between git refs--with the greatest of ease.

JIRA be damned. `git peer` is here to list PRs that were merged&mdash;and their [trello.com]() card links if available&mdash;from a tag ref to HEAD.

## Installation

Install it yourself as:

    $ gem install git-peer

## Command Line Usage

```bash
git peer $FROM_TAG..HEAD

git peer $FROM_TAG..$TO_TAG --print

git peer $FROM_TAG..$TO_TAG --output-file ./path/to/output.html
```

## Contributing

1. Fork it ( https://github.com/nonrational/git-peer/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
