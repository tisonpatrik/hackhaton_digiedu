defmodule LiveDashboard.Repo.Migrations.AddCodeToRegions do
  use Ecto.Migration

  def up do
    # Check if column exists using raw SQL
    execute """
      DO $$
      BEGIN
        IF NOT EXISTS (
          SELECT 1 FROM information_schema.columns
          WHERE table_name = 'regions' AND column_name = 'code'
        ) THEN
          ALTER TABLE regions ADD COLUMN code VARCHAR(255);
        END IF;
      END $$;
    """

    # Create index only if it doesn't exist
    create_if_not_exists index(:regions, [:code])
  end

  def down do
    drop_if_exists index(:regions, [:code])

    execute """
      DO $$
      BEGIN
        IF EXISTS (
          SELECT 1 FROM information_schema.columns
          WHERE table_name = 'regions' AND column_name = 'code'
        ) THEN
          ALTER TABLE regions DROP COLUMN code;
        END IF;
      END $$;
    """
  end
end
