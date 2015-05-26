# dbcode

## A Database Code Pipeline for ActiveRecord

### Objective

Migrations are fine for mutating table structure. Even a necessary evil given some changes require carefully preserving valuable production data.

Lately I've been taking advantage of more database features like constraints, views, and functions. Iterating on these during development via migrations is intolerable.

dbcode will borrow from a similar out of process dependency synchronization mechanism in rails: the asset pipeline. In development mode any changes to a sql view file aught to be one refresh away. A test ran after a change to a sql view file aught to execute against the latest version. In a production deploy sql views can be bundled into a migration - just like pre-compiling assets.

### Features

Database code files live in a directory structure like this:

    app
    └── db
        └── code
            ├── functions
            ├── triggers
            └── views

Interdependency of db/code elements is expressed via magic comments:

    -- require views/foo

Writing drop statements or downward migrations is not necessary.  All of your code is kept in a separate schema that is replaced when your declaration files change. Want to migrate to a previous version? Check out that revision in your SCM and connect. In test and development mode this will just work. Production is a slightly different story: read more below.

#### Test

DB Code ensures that the declarations in your test database are up to date. Any time you change a `db/code` file the changes will be available on your next test run. This happens automatically for tests that boot rails. If you have a test that integrates the database, but doesn't boot rails, call `DBCode.ensure_freshness!` in a before block.

#### Development

A request made after a change to a `db/code` file will see the latest version of that declaration.

#### Production

In production mode the automatic synchronization step is skipped. Connecting to a database that doesn't contain the latest version on the `code` schema will log a warning.

Running migrations on the production database will do the trick. Alternatively run the task `db:code:sync`

### Disclaimer

* This is only intended to be used with postgresql. Your other db is 💩..

* Booting into a raw psql connection will not configure your schema search to place `code` first. Try something like this in the repl: `set search_path to code,public;`

* Can't be used to manage code in schemas intended for name spacing or permission control. You'll need to use migrations to manage code that lives in schemas other than `code`.
