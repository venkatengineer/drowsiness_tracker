# Driver Assist Backend

Python Flask backend for user authentication. It uses a local SQLite database by
default and can be switched to MySQL with environment variables.

## Setup

1. Create a virtual environment:

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
```

2. Install dependencies:

```powershell
pip install -r requirements.txt
```

3. Copy `.env.example` to `.env` if you want to change the defaults.

4. Run:

```powershell
python app.py
```

The server listens on `http://0.0.0.0:6942` by default.

## Database

The default configuration is:

```powershell
DATABASE_BACKEND=sqlite
SQLITE_DATABASE=driver_assist.db
```

To use MySQL instead, set:

```powershell
DATABASE_BACKEND=mysql
MYSQL_HOST=127.0.0.1
MYSQL_PORT=3306
MYSQL_USER=root
MYSQL_PASSWORD=your_mysql_password
MYSQL_DATABASE=driver_assist
```

Make sure MySQL is running before starting the backend when using
`DATABASE_BACKEND=mysql`.

## Endpoints

- `GET /health`
- `POST /auth/register`
- `POST /auth/login`
- `GET /users/{user_id}`
- `POST /users/details`

Register payload:

```json
{
  "username": "driver1",
  "password": "secret123",
  "email": "driver@example.com",
  "phone_number": "9999999999"
}
```

Login payload:

```json
{
  "username": "driver1",
  "password": "secret123"
}
```

User details payload:

```json
{
  "username": "driver1"
}
```

or:

```json
{
  "user_id": 1
}
```
