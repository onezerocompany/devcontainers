# App with PostgreSQL

A development container template that provides a complete application development environment with PostgreSQL database running in a sidecar container.

## Features

- **Sidecar PostgreSQL**: Database runs in a separate container for production-like architecture
- **Data Persistence**: Database data persists between container restarts
- **Pre-configured VS Code**: Includes PostgreSQL extensions and connection settings
- **Development Tools**: Includes common development utilities via OneZero features
- **Multi-platform**: Supports both AMD64 and ARM64 architectures

## What's Included

### Development Container
- Based on `ghcr.io/onezerocompany/base` image
- OneZero common utilities with database clients and web development tools
- Non-root user `zero` for secure development

### PostgreSQL Container
- Configurable PostgreSQL version (13, 14, 15, 16, or latest)
- Persistent data storage via Docker volume
- Customizable database name, user, and password
- Optional sample data initialization

### VS Code Integration
- PostgreSQL extension for database management
- SQLTools with PostgreSQL driver for querying
- Pre-configured database connection

## Usage

1. **Create a new repository** using this template
2. **Customize options** in the devcontainer creation dialog:
   - PostgreSQL version
   - Database name, username, and password
   - Enable sample data (optional)
3. **Open in VS Code** with Dev Containers extension
4. **Connect to database** at `localhost:5432` or `postgres:5432` from within containers

## Database Connection

**From your application:**
- Host: `postgres` (container name)
- Port: `5432`
- Database: As configured (default: `app`)
- Username: As configured (default: `postgres`)
- Password: As configured (default: `postgres`)

**From VS Code:**
- Connection is pre-configured in SQLTools
- Or use the PostgreSQL extension

**From host machine:**
- Host: `localhost`
- Port: `5432`
- Other settings same as above

## Customization

### Database Initialization
Create `.devcontainer/init-db.sql` to add:
- Custom tables and schemas
- Sample data
- PostgreSQL extensions
- User permissions

### Application Setup
Add your application-specific setup in `postCreateCommand` within `.devcontainer/devcontainer.json`:

```json
"postCreateCommand": {
  "wait-for-db": "until pg_isready -h postgres -p 5432 -U postgres; do echo 'Waiting for PostgreSQL...'; sleep 2; done",
  "install": "npm install",
  "migrate": "npm run db:migrate",
  "seed": "npm run db:seed"
}
```

## Architecture

This template uses Docker Compose to orchestrate two containers:
- **app**: Your development environment
- **postgres**: PostgreSQL database server

Both containers share a custom network and the database uses a named volume for data persistence.