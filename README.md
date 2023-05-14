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


# Development Notes

### Generators used to build tables and get pages

1. Employee: context, Auth, schema, migration, auth html 
  - `mix phx.gen.auth Staff Employee employees`  
2. Employee: complete html, route resources 
  - `mix phx.gen.html Staff Employee employees --no-schema`
3. Add non-auth schema fields & migrations adds, create role type from enum
4. User: migration
 - `mix phx.gen.context Patient User users first_name:string last_name_string health_num:integer phone_num:integer`

5. User: context

- ` mix phx.gen.schema Patient.User users first_name:string last_name_string health_num:integer phone_num:integer`
6. User: live view
-  `mix phx.gen.live Patients User users -no-schema --no-context`
7. Opertations Admin 



# Installation

- instal[postgres](https://www.postgresql.org/)
- install [Phoenix](https://hexdocs.pm/phoenix/installation.html) 
- clone application
- `mix deps.get`
- `mix ecto.setup`
- `mix ecto.migrate`
- `mix phx.server`
-  Visit [localhost:4000](http://localhost:4000)
