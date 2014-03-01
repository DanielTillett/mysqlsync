# Mysqlsync

This tools allow sync one way two tables one the moment, dont use BINLOG, compare
every row beetwen tables with MD5 algorithm to search changes, before create DML
sentences to equal same tables.

- Don't modify table directly, output DML in STDOUT.
- Don't use BINLOG.
- You don't need SUPER PRIVILEGES.

## You can:

- Sync table schema.
- Sync table data.
- Checksum between tables in different servers.

## Installation

Install it yourself as:

    $ gem install mysqlsync

## Usage

### Sync data:

This command permit sync data:

```SHELL
$ mysqlsync data --from h=localhost,P=3306,u=root,p=admin,d=demo_from \
                 --to h=localhost,P=3306,u=root,p=admin,d=demo_to \
                 --table foo
```

## Warning

1. Do not use this tool in production before testing it.
2. Please, use when do you need.
3. The author is NOT responsible for misuse use of this tool.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
