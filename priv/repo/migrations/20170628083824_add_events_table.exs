defmodule Irateburgers.Repo.Migrations.AddEventsTable do
  use Ecto.Migration

  def change do
    create table(:events) do
      add :aggregate, :uuid, null: false
      add :sequence, :integer, null: false
      add :type, :string, null: false
      add :payload, :jsonb, null: false
    end

    create unique_index(:events, [:aggregate, :sequence], name: :events_aggregate_sequence_index)
  end
end
