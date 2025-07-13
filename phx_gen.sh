#!/bin/bash

echo "🔄 Resetting repository to remote..."
git reset --hard origin/main
git clean -fd

echo "🐳 Stopping and removing Docker containers..."
docker-compose down -v

echo "🐳 Starting fresh PostgreSQL container..."
docker-compose up -d

echo "⏳ Waiting for PostgreSQL to be ready..."
sleep 5

echo "🗄️ Dropping and recreating database..."
mix ecto.drop
mix ecto.create

echo "🚀 Generating Labels LiveView with correct schema..."
mix phx.gen.live Labels Label labels category:string subcategory:string soft_delete:boolean is_public:boolean --binary-id

echo "�� Updating migration to add default values..."
# This will be done manually - see instructions below

echo "✅ Setup complete! Now run:"
echo "1. Edit the migration file to add default values"
echo "2. Edit the schema file to add default values" 
echo "3. Run: mix ecto.migrate"
echo "4. Add routes to router.ex"
echo "5. Run: mix phx.server"