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

### Sync all:

This command permit sync table schema and data:

```SHELL
$ mysqlsync all --from h=localhost,P=3306,u=root,p=admin,d=demo_from \
                --to h=localhost,P=3306,u=root,p=admin,d=demo_to \
                --table foo
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Todo:

1. Add where to filter data.
2. Ignore columns or Primary Key's.
