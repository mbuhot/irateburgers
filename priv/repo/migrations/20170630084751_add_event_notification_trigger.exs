defmodule Irateburgers.Repo.Migrations.AddEventNotificationTrigger do
  use Ecto.Migration

  def up do
    execute """
    CREATE OR REPLACE FUNCTION notify_events_added()
    RETURNS trigger AS $$
    BEGIN
      PERFORM pg_notify(
        'events',
        json_build_object(
          'id', NEW.id,
          'aggregate', NEW.aggregate,
          'sequence', NEW.sequence,
          'type', NEW.type
        )::text
      );
      RETURN NEW;
    END;
    $$ LANGUAGE plpgsql;
    """

    execute """
    CREATE TRIGGER tr_notify_events_added
    AFTER INSERT ON events
    FOR EACH ROW EXECUTE PROCEDURE notify_events_added();
    """
  end

  def down do
    execute """
    DROP FUNCTION IF EXISTS notify_events_added() CASCADE;
    """
  end
end
