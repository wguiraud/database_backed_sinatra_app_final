# Database-Backed Todo Sinatra Application 
The application is set up to be deployed on [Render](https://render.com/), which only requires a single YAML file (`render.yaml`) for defining, deploying and managing resources. 
A Blueprint (yaml file) acts as the single source of truth for configuring an interconnected set of services, databases, and environment groups.

## Step One
1. Create a new PostgreSQL database. 
2. Give it a unique name, which is going to be referenced in the Blueprint.

## Step two 
1. Create a new web service to host the application project.
2. Set the Git repository used by the web service (by default, the main branch is
  used).
3. Set the build command to `bundle install`.
4. Set the start command to `bundle exec puma -C config/puma.rb`.

## Step Three
1. Create the `render.yaml` file using the following template:

```YAML
services:
  - type: web
    name: database_backed_sinatra_app
    runtime: ruby
    plan: free
    # This is the command executed during the build phase.
    # By calling 'bundle install' we can include all of the necessary dependencies
    buildCommand: bundle install
    # The command that will start the application
    startCommand: bundle exec puma -C config/puma.rb
    # Setting the necessary environment variables
    envVars:
      - key: APP_ENV # Set the environment the app should run in
        value: production
      - key: DATABASE_URL
        fromDatabase:
          name: postgresql_test
          # Render generates the string needed for the app to connect to the database
          property: connectionString
      - key: SESSION_SECRET
        generateValue: true # Generate a base64-encoded 256-bit value

databases:
  - name: postgresql_test
    databaseName: postgresql_test_xezo
    user: postgresql_test_xezo_user
    plan: free
```
2. Save this file into the git repository.

## Step Four
1. In the setting section of the application page, set the two environment variables `DATABASE_URL` and `APP_ENV`. The URL for the database can be found in the "Internal Database URL" section of
the database page. Set the `APP_ENV` variable to `production`. 

## Step Five
1. Create a new Blueprint by connecting to the corresponding Git repository. 
2. Start the database. 
3. Start the application. 
4. Enjoy your todo list application!
