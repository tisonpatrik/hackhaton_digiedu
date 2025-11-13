defmodule LiveDashboard.Repo.Migrations.ChangeDocumentContentToFilePath do
  use Ecto.Migration

  def change do
    rename table("document"), :content, to: :file_path
  end
end
