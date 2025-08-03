defmodule RaBackend.Repo.Migrations.AddObanJobs do
  use Ecto.Migration

  def change do
    Oban.Migration.up()
  end
end
