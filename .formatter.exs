[
  plugins: [Phoenix.LiveView.HTMLFormatter],
  import_deps: [:ecto, :phoenix],
  inputs: ["*.{heex,ex,exs}", "{config,lib,test}/**/*.{heex,ex,exs}","*.{ex,exs}", "priv/*/seeds.exs", "{config,lib,test}/**/*.{ex,exs}"],
  whitespace_trimming: [
    leading: true,
    trailing: true
  ]
  subdirectories: ["priv/*/migrations"]
]
