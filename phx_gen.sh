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

echo "👤 Generating Users table for Apple ID authentication..."
mix phx.gen.live GraUsers GraUser users apple_id:string email:string first_name:string avatar_url:string is_active:boolean is_verified:boolean last_sign_in_at:utc_datetime sign_in_count:integer metadata:map --binary-id

echo "🚀 Generating Labels LiveView with correct schema..."
mix phx.gen.live GraLabels GraLabel labels name:string description:text category:string subcategory:string color:string icon:string priority:integer is_active:boolean is_public:boolean soft_delete:boolean metadata:map created_by:references:users updated_by:references:users --binary-id
echo "�� Updating migration to add default values..."
# This will be done manually - see instructions below

echo "✅ Setup complete! Now run:"
echo "1. Edit the migration files to add default values"
echo "2. Edit the schema files to add default values" 
echo "3. Run: mix ecto.migrate"
echo "4. Add routes to router.ex"
echo "5. Run: mix phx.server"