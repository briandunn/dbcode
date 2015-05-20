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

    -- require foo_view


#### Test

Any time rails would expose a new version of a javascript file to your tests, dbcode will ensure your view declarations are up to date. That means any time you change a `db/code` file the changes will be available on your next test run.

#### Development

A request made after a change to a db/code file aught to see the newest version of the database. This could be achieved via a rack middleware that checks modification times on request start.

#### Production

1. Calculate digest of db/code hunk

2. Using that digest, look for a schema by that name

3. if the schema exists, set the connection's search path to use it first.

4. if it doesn't exist, create it with the contents of db/code

### Cleanup

Old versions of the code schema can be removed from your database with

    rake dbcode:clean

### Disclaimer

* This is only intended to be used with postgresql. Your other db is 💩..

* Booting into a raw psql connection will not configure your schema search path. Do this with the `dbcode` command.

* Can't be used to manage code in schemas intended for name spacing or permission control.
