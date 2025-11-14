# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# This file orchestrates the seeding process by loading individual seed files
# in the correct order to maintain referential integrity.

IO.puts("Starting database seeding...")

# Load seed files in dependency order
Code.require_file("priv/repo/seeds/regions.exs")
IO.puts("✓ Regions seeded")

Code.require_file("priv/repo/seeds/municipalities.exs")
IO.puts("✓ Municipalities seeded")

Code.require_file("priv/repo/seeds/schools.exs")
IO.puts("✓ Schools seeded")

Code.require_file("priv/repo/seeds/guides_projects.exs")
IO.puts("✓ Guides and projects seeded")

Code.require_file("priv/repo/seeds/exam_results.exs")
IO.puts("✓ Exam results seeded")

IO.puts("🎉 Database seeding completed successfully!")
