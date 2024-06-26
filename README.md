# TurnStile

TurnStile is a client managment system that allows providers to send emails and text to clients. This could be used to eliminate in-person waiting. 

Current implementation is the customer facing web application. The next phase of development would be implemenating a digital queueing system to keep clients in line. 

### This is a rough draft README for assising in development.
To start your Phoenix server:
  * run `create extension fuzzystrmatch` in psql. This is required to run levenstein distance queries.
  * Install dependencies with `mix deps.get`
  * Create and migrate your database with `mix ecto.setup`
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

To set enviromnent:
  * MIX_ENV=dev iex -S mix phx.server
  * [see link](https://elixirforum.com/t/where-how-does-the-mix-environment-variable-get-set/3805/3?u=chrisdel101)

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).
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
* `mix phx.gen.html Operations Admin admins --no-schema`
- other half of context created here

### Handle Receiving Alerts
__Developement__
- [Using CLI](https://www.twilio.com/docs/twilio-cli/examples/explore-sms#have-your-phone-number-respond-to-incoming-sms) (must be installed), or from the dashboard under the phone number, set the system to "listen" for incoming requests on the webhook. 
  1. In router expose api route outside the app flow: 
    - i.e. `POST /sms_messages`
  2. Exposed a public, non-local, access URL to the app: 
    - i.e. `ngrok http 4000`
  3. Use this URL in the webhook to allow twilio application access:
    - i.e. `https://7114-108-60-178-251.ngrok-free.app/sms_messages`
  4. Use the CLI command to set the webhook to listen. 
  - This `sid` is phone number sid. This is found in the dashboard under the active phone number -> properties -> `Phone Number SID`
      ``` 
      twilio api:core:incoming-phone-numbers:update \
      --sid PN3ae43ff9946669eeeb7d41deba57fac4 \
      --sms-url "https://7114-108-60-178-251.ngrok-free.app/sms_messages"
      ```
  5. Using TwinML and this [tutorial](https://www.blakedietz.me/blog/2022-03-30/phoenix-twilio/) we immideatlely resonsd to incoming messages.

### Handle Flash Messages
- For Flash messages to appear in child components, the `put_flash` must be called in the child component.

# Installation

- instal[postgres](https://www.postgresql.org/)
- install [Phoenix](https://hexdocs.pm/phoenix/installation.html) 
- clone application
- `mix deps.get`
- `mix ecto.setup`
- `mix ecto.migrate`
- `mix phx.server`
-  Visit [localhost:4000](http://localhost:4000)


# Notes

#### Elixir

Ternary operator syntax

`disable_input = if action && action === :select, do: true, else: false`

### Phoenix 

Temlating syntax notes:

- `attribue: variable`: this works as valid elixir
- always use `get_field`. Checks all parts of the changeset for values
- readonly, title, and value usage
```
<%= text_input f, :phone, value:  Ecto.Changeset.get_field(@changeset, :phone), readonly: @disable_input, title: @disabled_hover_info %>
      <%= error_tag f, :phone %>
```
- radio button usage
```
 <%= radio_button(f, :alert_format_set, :sms, phx_change: "radio_click", checked: Ecto.Changeset.get_field(@changeset, :alert_format_set) == AlertFormatTypesMap.get_alert("SMS"), disabled: @disable_input, title: @disabled_hover_info)%>
```

LiveView Messaging Methods
- PUBSUB: subscrber in the liveView mount and broadcaster in the outer process.
- send: 
 - Process.send used to send from child to parent and is caught in handle_info
 - Kernel.send
- send_update: Liveview.send_update used to update component

#### Handling Associations

__1-Many__

Schema
- `belongs_to` singular in child:   
   - i.e. `belongs_to(:employee, Employee)`
- `has_many` plural in parent: 
  - i.e. `has_many(:alerts, Alert)`

Migration
- `references` appears only in child: 
  - i.e. ` add :employee_id, references("employees"), null: false`

Business Logic
