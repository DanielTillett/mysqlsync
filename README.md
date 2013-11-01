# Mysqlsync

This tools allow sync one way two tables one the moment, dont use BINLOG, compare
every row beetwen tables with MD5 algorithm to search changes, before create DML
sentences to equal same tables.

- Don't modify table directly, output DML in STDOUT.
- Don't use BINLOG.
- You don't need SUPER PRIVILEGES.

## Installation

Install it yourself as:

    $ gem install mysqlsync

## Usage

### Create example data:

```SQL

```

Usage:

```SHELL
$ mysqlsync
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Todo:

3. Permitir condiciones en la busqueda de datos.
4. Ignorar columnas o pk a comparar.
6. Validar que una tabla tenga la clave primaria.
7. Sera necesario re ajustar los PK "ALTER TABLE AUTO_INCREMENT=n;"?
