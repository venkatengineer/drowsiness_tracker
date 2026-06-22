import os
import sqlite3
from contextlib import contextmanager, asynccontextmanager

import mysql.connector
from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException, Request
from fastapi.responses import JSONResponse
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from mysql.connector import errorcode
from pydantic import BaseModel
from typing import Optional
from werkzeug.security import check_password_hash, generate_password_hash

load_dotenv()


def _mysql_config(database=None):
    config = {
        "host": os.getenv("MYSQL_HOST", "127.0.0.1"),
        "port": int(os.getenv("MYSQL_PORT", "3306")),
        "user": os.getenv("MYSQL_USER", "root"),
        "password": os.getenv("MYSQL_PASSWORD", ""),
    }
    if database:
        config["database"] = database
    return config


DATABASE_BACKEND = os.getenv("DATABASE_BACKEND", "sqlite").lower()
DATABASE_NAME = os.getenv("MYSQL_DATABASE", "driver_assist")
SQLITE_DATABASE = os.getenv("SQLITE_DATABASE", "driver_assist.db")


@contextmanager
def db_connection(database=DATABASE_NAME):
    if DATABASE_BACKEND == "mysql":
        connection = mysql.connector.connect(**_mysql_config(database=database))
    else:
        connection = sqlite3.connect(SQLITE_DATABASE)
        connection.row_factory = sqlite3.Row
    try:
        yield connection
    finally:
        connection.close()


def _ensure_trip_columns(cursor):
    columns = {
        "start_latitude": "DOUBLE NULL" if DATABASE_BACKEND == "mysql" else "REAL NULL",
        "start_longitude": "DOUBLE NULL" if DATABASE_BACKEND == "mysql" else "REAL NULL",
        "end_latitude": "DOUBLE NULL" if DATABASE_BACKEND == "mysql" else "REAL NULL",
        "end_longitude": "DOUBLE NULL" if DATABASE_BACKEND == "mysql" else "REAL NULL",
    }

    if DATABASE_BACKEND == "mysql":
        for column, column_type in columns.items():
            cursor.execute("SHOW COLUMNS FROM trip LIKE %s", (column,))
            if cursor.fetchone() is None:
                cursor.execute(f"ALTER TABLE trip ADD COLUMN {column} {column_type}")
        return

    cursor.execute("PRAGMA table_info(trip)")
    existing_columns = {row[1] for row in cursor.fetchall()}
    for column, column_type in columns.items():
        if column not in existing_columns:
            cursor.execute(f"ALTER TABLE trip ADD COLUMN {column} {column_type}")


def init_database():
    if DATABASE_BACKEND == "mysql":
        with mysql.connector.connect(**_mysql_config()) as connection:
            cursor = connection.cursor()
            cursor.execute(f"CREATE DATABASE IF NOT EXISTS `{DATABASE_NAME}`")
            cursor.close()

    with db_connection() as connection:
        cursor = connection.cursor()
        if DATABASE_BACKEND == "mysql":
            cursor.execute(
                """
                CREATE TABLE IF NOT EXISTS users (
                  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
                  username VARCHAR(80) NOT NULL,
                  password_hash VARCHAR(255) NOT NULL,
                  email VARCHAR(255) NULL,
                  phone_number VARCHAR(32) NULL,
                  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                  PRIMARY KEY (id),
                  UNIQUE KEY users_username_unique (username)
                )
                """
            )
            cursor.execute(
                """
                CREATE TABLE IF NOT EXISTS user_details (
                  user_id BIGINT UNSIGNED NOT NULL,
                  full_name VARCHAR(255) NULL,
                  age INT NULL,
                  gender VARCHAR(50) NULL,
                  vehicle_number VARCHAR(80) NULL,
                  vehicle_type VARCHAR(50) NULL,
                  emergency_contact_name VARCHAR(255) NULL,
                  emergency_contact_number VARCHAR(32) NULL,
                  average_daily_driving_hours INT NULL,
                  PRIMARY KEY (user_id),
                  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
                )
                """
            )
            cursor.execute(
                """
                CREATE TABLE IF NOT EXISTS trip (
                  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
                  user_id BIGINT UNSIGNED NULL,
                  start_destination VARCHAR(255) NOT NULL,
                  end_destination VARCHAR(255) NOT NULL,
                  start_latitude DOUBLE NULL,
                  start_longitude DOUBLE NULL,
                  end_latitude DOUBLE NULL,
                  end_longitude DOUBLE NULL,
                  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                  PRIMARY KEY (id),
                  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
                )
                """
            )
        else:
            cursor.execute(
                """
                CREATE TABLE IF NOT EXISTS users (
                  id INTEGER PRIMARY KEY AUTOINCREMENT,
                  username TEXT NOT NULL UNIQUE,
                  password_hash TEXT NOT NULL,
                  email TEXT NULL,
                  phone_number TEXT NULL,
                  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
                )
                """
            )
            cursor.execute(
                """
                CREATE TABLE IF NOT EXISTS user_details (
                  user_id INTEGER PRIMARY KEY,
                  full_name TEXT NULL,
                  age INTEGER NULL,
                  gender TEXT NULL,
                  vehicle_number TEXT NULL,
                  vehicle_type TEXT NULL,
                  emergency_contact_name TEXT NULL,
                  emergency_contact_number TEXT NULL,
                  average_daily_driving_hours INTEGER NULL,
                  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
                )
                """
            )
            cursor.execute(
                """
                CREATE TABLE IF NOT EXISTS trip (
                  id INTEGER PRIMARY KEY AUTOINCREMENT,
                  user_id INTEGER NULL,
                  start_destination TEXT NOT NULL,
                  end_destination TEXT NOT NULL,
                  start_latitude REAL NULL,
                  start_longitude REAL NULL,
                  end_latitude REAL NULL,
                  end_longitude REAL NULL,
                  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
                )
                """
            )
        _ensure_trip_columns(cursor)
        connection.commit()
        cursor.close()


def _placeholder():
    return "%s" if DATABASE_BACKEND == "mysql" else "?"


def _is_duplicate_username_error(error):
    if DATABASE_BACKEND == "mysql":
        return isinstance(error, mysql.connector.Error) and error.errno == errorcode.ER_DUP_ENTRY
    return isinstance(error, sqlite3.IntegrityError)


def _user_to_dict(user):
    return dict(user) if isinstance(user, sqlite3.Row) else user


# Lifespan context manager for database initialization
@asynccontextmanager
async def lifespan(app: FastAPI):
    init_database()
    yield


app = FastAPI(
    title="Driver Assist API",
    version="1.0.0",
    lifespan=lifespan
)

# Configure CORS Middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# Override error handling to match the format expected by the client: {"message": "..."}
@app.exception_handler(HTTPException)
async def http_exception_handler(request: Request, exc: HTTPException):
    return JSONResponse(
        status_code=exc.status_code,
        content={"message": exc.detail},
    )


@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    errors = exc.errors()
    if errors:
        error = errors[0]
        field = error.get("loc", ["field"])[-1]
        msg = error.get("msg", "Validation error")
        message = f"Invalid input for {field}: {msg}"
    else:
        message = "Validation error"
    return JSONResponse(
        status_code=400,
        content={"message": message},
    )


# Request Schemas
class RegisterRequest(BaseModel):
    username: str
    password: str
    email: Optional[str] = None
    phone_number: Optional[str] = None


class LoginRequest(BaseModel):
    username: str
    password: str


class UserDetailsRequest(BaseModel):
    username: Optional[str] = None
    user_id: Optional[int] = None


class OnboardingRequest(BaseModel):
    user_id: int
    full_name: Optional[str] = None
    age: Optional[int] = None
    gender: Optional[str] = None
    vehicle_number: Optional[str] = None
    vehicle_type: Optional[str] = None
    emergency_contact_name: Optional[str] = None
    emergency_contact_number: Optional[str] = None
    average_daily_driving_hours: Optional[int] = None


class TripRequest(BaseModel):
    user_id: Optional[int] = None
    start_destination: str
    end_destination: str
    start_latitude: Optional[float] = None
    start_longitude: Optional[float] = None
    end_latitude: Optional[float] = None
    end_longitude: Optional[float] = None


@app.get("/")
def index():
    return {
        "name": "Driver Assist API",
        "version": "1.0.0",
        "status": "running",
        "endpoints": [
            "/health",
            "/auth/register",
            "/auth/login",
            "/trips"
        ]
    }


@app.get("/health")
def health():
    return {"status": "ok"}


@app.post("/auth/register")
def register(payload: RegisterRequest):
    username = payload.username.strip() if payload.username else ""
    password = payload.password
    email = payload.email.strip() if payload.email else None
    phone_number = payload.phone_number.strip() if payload.phone_number else None

    if not username or not password:
        raise HTTPException(status_code=400, detail="Username and password are required.")

    if len(username) < 3:
        raise HTTPException(status_code=400, detail="Username must be at least 3 characters.")

    if len(password) < 6:
        raise HTTPException(status_code=400, detail="Password must be at least 6 characters.")

    password_hash = generate_password_hash(password)
    placeholder = _placeholder()

    try:
        with db_connection() as connection:
            cursor = connection.cursor()
            cursor.execute(
                f"""
                INSERT INTO users (username, password_hash, email, phone_number)
                VALUES ({placeholder}, {placeholder}, {placeholder}, {placeholder})
                """,
                (username, password_hash, email, phone_number),
            )
            connection.commit()
            user_id = cursor.lastrowid
            cursor.close()
    except (mysql.connector.Error, sqlite3.Error) as error:
        if _is_duplicate_username_error(error):
            raise HTTPException(status_code=409, detail="Username already exists.")
        raise HTTPException(status_code=500, detail="Database error while registering user.")

    return JSONResponse(
        status_code=201,
        content={
            "message": "Registration successful.",
            "user": {"id": user_id, "username": username},
        }
    )


@app.post("/auth/login")
def login(payload: LoginRequest):
    username = payload.username.strip() if payload.username else ""
    password = payload.password

    if not username or not password:
        raise HTTPException(status_code=400, detail="Username and password are required.")

    placeholder = _placeholder()
    try:
        with db_connection() as connection:
            cursor = (
                connection.cursor(dictionary=True)
                if DATABASE_BACKEND == "mysql"
                else connection.cursor()
            )
            cursor.execute(
                f"SELECT id, username, password_hash FROM users WHERE username = {placeholder}",
                (username,),
            )
            user = _user_to_dict(cursor.fetchone())
            cursor.close()
    except (mysql.connector.Error, sqlite3.Error):
        raise HTTPException(status_code=500, detail="Database error while logging in.")

    if user is None or not check_password_hash(user["password_hash"], password):
        raise HTTPException(status_code=401, detail="Invalid username or password.")

    return {
        "message": "Login successful.",
        "user": {"id": user["id"], "username": user["username"]},
    }


def _fetch_user_details(where_clause, params):
    try:
        with db_connection() as connection:
            cursor = (
                connection.cursor(dictionary=True)
                if DATABASE_BACKEND == "mysql"
                else connection.cursor()
            )
            cursor.execute(
                f"""
                SELECT u.id, u.username, u.email, u.phone_number, u.created_at,
                       ud.full_name, ud.age, ud.gender, ud.vehicle_number, ud.vehicle_type,
                       ud.emergency_contact_name, ud.emergency_contact_number, ud.average_daily_driving_hours
                FROM users u
                LEFT JOIN user_details ud ON u.id = ud.user_id
                WHERE u.{where_clause}
                """,
                params,
            )
            user = _user_to_dict(cursor.fetchone())
            cursor.close()
    except (mysql.connector.Error, sqlite3.Error) as err:
        raise HTTPException(status_code=500, detail=f"Database error while fetching user details: {err}")

    if user is None:
        raise HTTPException(status_code=404, detail="User not found.")

    return user


@app.get("/users/{user_id}")
def get_user_details_by_id(user_id: int):
    return _fetch_user_details(f"id = {_placeholder()}", (user_id,))


@app.post("/users/details")
def post_user_details(payload: UserDetailsRequest):
    placeholder = _placeholder()

    if payload.user_id is not None:
        return _fetch_user_details(f"id = {placeholder}", (payload.user_id,))

    username = payload.username.strip() if payload.username else ""
    if username:
        return _fetch_user_details(f"username = {placeholder}", (username,))

    raise HTTPException(status_code=400, detail="Username or user_id is required.")


@app.post("/users/onboarding")
def save_onboarding_details(payload: OnboardingRequest):
    placeholder = _placeholder()
    try:
        with db_connection() as connection:
            cursor = connection.cursor()
            
            if DATABASE_BACKEND == "mysql":
                cursor.execute("SELECT 1 FROM user_details WHERE user_id = %s", (payload.user_id,))
            else:
                cursor.execute("SELECT 1 FROM user_details WHERE user_id = ?", (payload.user_id,))
            
            exists = cursor.fetchone() is not None
            
            if exists:
                cursor.execute(
                    f"""
                    UPDATE user_details
                    SET full_name = {placeholder}, age = {placeholder}, gender = {placeholder},
                        vehicle_number = {placeholder}, vehicle_type = {placeholder},
                        emergency_contact_name = {placeholder}, emergency_contact_number = {placeholder},
                        average_daily_driving_hours = {placeholder}
                    WHERE user_id = {placeholder}
                    """,
                    (
                        payload.full_name,
                        payload.age,
                        payload.gender,
                        payload.vehicle_number,
                        payload.vehicle_type,
                        payload.emergency_contact_name,
                        payload.emergency_contact_number,
                        payload.average_daily_driving_hours,
                        payload.user_id
                    ),
                )
            else:
                cursor.execute(
                    f"""
                    INSERT INTO user_details (user_id, full_name, age, gender, vehicle_number, vehicle_type,
                                             emergency_contact_name, emergency_contact_number, average_daily_driving_hours)
                    VALUES ({placeholder}, {placeholder}, {placeholder}, {placeholder}, {placeholder}, {placeholder},
                            {placeholder}, {placeholder}, {placeholder})
                    """,
                    (
                        payload.user_id,
                        payload.full_name,
                        payload.age,
                        payload.gender,
                        payload.vehicle_number,
                        payload.vehicle_type,
                        payload.emergency_contact_name,
                        payload.emergency_contact_number,
                        payload.average_daily_driving_hours
                    ),
                )
            connection.commit()
            cursor.close()
    except (mysql.connector.Error, sqlite3.Error) as err:
        raise HTTPException(status_code=500, detail=f"Database error while saving onboarding details: {err}")

    return {"message": "Onboarding details saved successfully."}


@app.post("/trips")
def create_trip(payload: TripRequest):
    start_destination = payload.start_destination.strip() if payload.start_destination else ""
    end_destination = payload.end_destination.strip() if payload.end_destination else ""

    if not start_destination or not end_destination:
        raise HTTPException(status_code=400, detail="Start and end destinations are required.")

    placeholder = _placeholder()
    try:
        with db_connection() as connection:
            cursor = connection.cursor()
            cursor.execute(
                f"""
                INSERT INTO trip (
                    user_id, start_destination, end_destination,
                    start_latitude, start_longitude, end_latitude, end_longitude
                )
                VALUES (
                    {placeholder}, {placeholder}, {placeholder},
                    {placeholder}, {placeholder}, {placeholder}, {placeholder}
                )
                """,
                (
                    payload.user_id,
                    start_destination,
                    end_destination,
                    payload.start_latitude,
                    payload.start_longitude,
                    payload.end_latitude,
                    payload.end_longitude,
                ),
            )
            connection.commit()
            trip_id = cursor.lastrowid
            cursor.close()
    except (mysql.connector.Error, sqlite3.Error) as err:
        raise HTTPException(status_code=500, detail=f"Database error while saving trip: {err}")

    return JSONResponse(
        status_code=201,
        content={
            "message": "Trip saved successfully.",
            "trip": {
                "id": trip_id,
                "user_id": payload.user_id,
                "start_destination": start_destination,
                "end_destination": end_destination,
                "start_latitude": payload.start_latitude,
                "start_longitude": payload.start_longitude,
                "end_latitude": payload.end_latitude,
                "end_longitude": payload.end_longitude,
            },
        },
    )


@app.get("/trips")
def list_trips(user_id: Optional[int] = None):
    placeholder = _placeholder()
    where_clause = ""
    params = ()
    if user_id is not None:
        where_clause = f"WHERE user_id = {placeholder}"
        params = (user_id,)

    try:
        with db_connection() as connection:
            cursor = (
                connection.cursor(dictionary=True)
                if DATABASE_BACKEND == "mysql"
                else connection.cursor()
            )
            cursor.execute(
                f"""
                SELECT id, user_id, start_destination, end_destination,
                       start_latitude, start_longitude, end_latitude, end_longitude,
                       created_at
                FROM trip
                {where_clause}
                ORDER BY created_at DESC, id DESC
                """,
                params,
            )
            rows = cursor.fetchall()
            cursor.close()
    except (mysql.connector.Error, sqlite3.Error) as err:
        raise HTTPException(status_code=500, detail=f"Database error while fetching trips: {err}")

    return {"trips": [_user_to_dict(row) for row in rows]}


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "app:app",
        host=os.getenv("FLASK_HOST", "0.0.0.0"),
        port=int(os.getenv("FLASK_PORT", "6942")),
        reload=os.getenv("FLASK_DEBUG", "1") == "1",
    )
