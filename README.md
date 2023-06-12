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

1. Employee: Auth, schema, auth migration, auth html 
  - `mix phx.gen.auth Staff Employee employees`  
  - half of context created here
  - in auth migration: add roles with `execute("create type employee_role as enum #{TurnStile.Utils.convert_to_parens_string(EmployeePermissionRolesEnum.get_employee_all_roles())}")` 
2. Employee: context, complete html, route resources 
  - `mix phx.gen.html Staff Employee employees --no-schema`
  - other half of context created here
3. Organization: non-auth migration, context, schema, page html, resources
- `mix phx.gen.html Company Organization organizations name:string slug:string email:string phone:string`
4. User: schema and migration
 - `mix phx.gen.schema Patient User users first_name:string last_name_string health_num:integer phone_num:integer`
5. User: context and functionality
- ` mix phx.gen.context Patient.User users first_name:string last_name_string health_num:integer phone_num:integer`
6. User: live view
-  `mix phx.gen.live Patients User users -no-schema --no-context`
7. Opertations Admin: Auth, schema, auth migration, auth html 
- `mix phx.gen.auth Operations Admin admins`
- in auth migration: add roles with ` execute("create type admin_role as enum #{TurnStile.Utils.convert_to_parens_string(AdminPermissionRolesEnum.get_admin_all_roles())}")`
  - half of context created here
8. Opertations Admin: context, complete web html, route resources 
- `mix phx.gen.html Operations Admin admins --no-schema`
- other half of context created here





# Installation

- instal[postgres](https://www.postgresql.org/)
- install [Phoenix](https://hexdocs.pm/phoenix/installation.html) 
- clone application
- `mix deps.get`
- `mix ecto.setup`
- `mix ecto.migrate`
- `mix phx.server`
-  Visit [localhost:4000](http://localhost:4000)
