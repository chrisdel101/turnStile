# TurnStile

To start your Phoenix server:

  * Install dependencies with `mix deps.get`
  * Create and migrate your database with `mix ecto.setup`
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Learn more

  * Official website: https://www.phoenixframework.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Forum: https://elixirforum.com/c/phoenix-forum
  * Source: https://github.com/phoenixframework/phoenix


## Steps used to build tables

1. Admin: Auth, schema, migration, auth html 
  - `mix phx.gen.auth Administrtion Admin admins`  
2. Admin: complete html, route resources 
  - `mix phx.gen.html Administrtion Admin admins --no-schema --no-context`
3. Add non-auth schema fields & migrations adds, create role type from enum
4. Employee: Auth, schema, migrtion, auth html 
  - `mix phx.gen.auth Staff Employee employees`
5. Employee: complete html, route resources 
  - `mix phx.gen.html Staff Employee employees --no-schema --no-context`
