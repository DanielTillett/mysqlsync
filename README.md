# Mysqlsync

This tools allow sync one way two tables one the moment, dont use BINLOG, compare
every row beetwen tables with MD5 algorithm to search changes, before create DML
sentences to equal same tables.

- Don't modify table directly, output DML in STDOUT.
- Don't use BINLOG.
- You don't need SUPER PRIVILEGES.

## You can:

- Sync schema.
- Sync data.
- Checksum between tables in different servers.

## Installation

Install it yourself as:

    $ gem install mysqlsync

## Usage

### Sync Schema:

This command permit sync table schema:

```SHELL
$ mysqlsync schema --from h=localhost,P=3306,u=root,p=admin,d=demo_from \
                   --to h=localhost,P=3306,u=root,p=admin,d=demo_to \
                   --table foo
```

### Sync data:

This command permit sync table data:

```SHELL
$ mysqlsync data --from h=localhost,P=3306,u=root,p=admin,d=demo_from \
                 --to h=localhost,P=3306,u=root,p=admin,d=demo_to \
                 --table foo
```

### Checksum:

This command verify two tables is equal by checksum:

```SHELL
$ mysqlsync checksum --from h=localhost,P=3306,u=root,p=admin,d=demo_from \
                     --to h=localhost,P=3306,u=root,p=admin,d=demo_to \
                     --table foo
```

### Merge:

--increment-columns Son las columnas que se le aplica el valor de incremento,
                    debe ser de tipo de dato númerico, ideal aplicar unicamente
                    para claves Primarias o Foraneas.
--increment-value Es el valor que se incrementa, es obligatorio definirlo, para
                  la primera vez (importación) y la proxima vez (sync), indica
                  el punto de partida para saber que se debe sync.

### Create example:

```SQL
DROP DATABASE IF EXISTS demo_from;
DROP DATABASE IF EXISTS demo_to;

CREATE DATABASE demo_from CHARACTER SET utf8;
USE demo_from;

CREATE TABLE foo (
  id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  bar_id INT,
  data CHAR(1),
  test BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP,
  deleted_at DATETIME
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE foobar (
  foo_id INT NOT NULL,
  bar_id INT NOT NULL,
  CONSTRAINT id PRIMARY KEY id (foo_id, bar_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

INSERT INTO foo VALUES (1, 1, 'A', 1, NOW(), NULL);
INSERT INTO foo VALUES (2, 1, 'B', 0, NOW(), NULL);
INSERT INTO foo VALUES (3, 1, 'C', 1, NOW(), NOW());
INSERT INTO foo VALUES (4, 1, 'D', 0, NOW(), NULL);
INSERT INTO foo VALUES (5, 1, 'E', 1, NOW(), NULL);
INSERT INTO foo VALUES (6, 1, 'F', 0, NOW(), NULL);
INSERT INTO foo VALUES (7, 1, 'I', 1, NOW(), NOW());

INSERT INTO foobar VALUES (1, 1);
INSERT INTO foobar VALUES (1, 2);
INSERT INTO foobar VALUES (1, 3);
INSERT INTO foobar VALUES (2, 1);
INSERT INTO foobar VALUES (2, 2);
INSERT INTO foobar VALUES (2, 3);

CREATE DATABASE demo_to CHARACTER SET utf8;
USE demo_to;

CREATE TABLE foo (
  id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  bar_id INT,
  data CHAR(45),
  status INT,
  created_at TIMESTAMP,
  updated_at TIMESTAMP
);

CREATE TABLE foobar (
  foo_id INT NOT NULL,
  bar_id INT NOT NULL,
  CONSTRAINT id PRIMARY KEY id (foo_id, bar_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

INSERT INTO foo VALUES (3, 1, 'C', 2,NOW(), NOW());
INSERT INTO foo VALUES (5, 1, 'F', 2,NOW(), NOW());
INSERT INTO foo VALUES (6, 1, 'A', 3,NOW(), NOW());
INSERT INTO foo VALUES (7, 1, 'H', 2,NOW(), NOW());
INSERT INTO foo VALUES (8, 2, 'M', 5,NOW(), NOW());

INSERT INTO foobar VALUES (1, 1);
INSERT INTO foobar VALUES (1, 3);
INSERT INTO foobar VALUES (2, 4);
INSERT INTO foobar VALUES (3, 1);
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Todo:

1. Exclude by columns name, parameter: `--exclude-columns=id,data,type_id`
2. Increment value key (primary or foreign key), need the another parameter to specify column name, parameter: `--increment-value=10000`
3. Increment column name, parameter: `--increment-columns=id,type_id`
4. Test sync with junction table.
