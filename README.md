# SIIT-Rental-Service

A web-based equipment rental system for SIIT. Students can borrow equipment (cameras, laptops, audio gear, electronics, accessories), staff manage the inventory, and admins oversee the system. Built with Node.js, Express, and MySQL, with business logic handled by MySQL stored procedures.

## Features

- **Role-based access**: separate areas for `student`, `staff`, and `admin` users
- **Authentication**: sign-up, login, and logout with server-side sessions
- **Password security**: passwords hashed with bcrypt (cost factor 12)
- **Rate limiting**: sign-up (10 requests) and login (20 requests) limited per IP per 15 minutes
- **Equipment catalogue**: categories and equipment with quantity and condition notes
- **Soft delete**: equipment uses a `deleted_at` column instead of being removed
- **Stored procedures**: user creation and equipment management run inside the database

## Tech Stack

| Layer     | Technology                                     |
| --------- | ---------------------------------------------- |
| Runtime   | Node.js                                        |
| Server    | Express 5, express-session, express-rate-limit |
| Database  | MySQL (via `mysql2` connection pool)           |
| Security  | bcrypt, httpOnly + sameSite session cookies    |
| Frontend  | Static files in `public/` (GSAP for animation) |
| Dev tools | nodemon                                        |

## Project Structure

```
.
├── server.js            # Express app: session, rate limits, auth routes, role routes
├── db.js                # MySQL connection pool (reads .env)
├── createUsers.js       # Creates a sample student, staff, and admin account
├── seedEquipment.js     # Seeds categories and equipment
├── controllers/         # e.g. authController (sign-up logic)
├── middleware/          # e.g. wrap (async error wrapper)
├── routes/              # studentRoutes, staffRoutes, adminRoutes
├── public/              # Static pages (login.html, etc.)
├── package.json
└── README.md
```

## Prerequisites

- [Node.js](https://nodejs.org/) 18 or newer
- MySQL 8 or newer
- The project database schema (tables and stored procedures) loaded into MySQL

## Getting Started

### 1. Clone and install

```bash
git clone https://github.com/Austinkle/SIIT-Rental-Service.git
cd SIIT-Rental-Service
npm install
```

### 2. Configure environment variables

Create a `.env` file in the project root:

```env
DB_HOST=localhost
DB_USER=your_mysql_user
DB_PASS=your_mysql_password
DB_NAME=your_database_name
SESSION_SECRET=a-long-random-string
```

> Never commit `.env`. Make sure it is listed in `.gitignore`.

### 3. Set up the database

Load your schema into MySQL. The application expects:

- Tables: `user`, `category`, `equipment` (with a `deleted_at` column)
- Stored procedures:
  - `sp_create_student(first_name, last_name, email, password_hash, <nullable>, student_id, major, year)`
  - `sp_create_staff(first_name, last_name, email, password_hash, <nullable>, staff_id)`
  - `sp_create_admin(first_name, last_name, email, password_hash, <nullable>, admin_id)`
  - `sp_add_equipment(staff_user_id, name, category_id, description, total_quantity, condition_note)`

### 4. Create sample users

```bash
node createUsers.js
```

This creates a student, a staff member, and an admin, each with the demo password `1234`. **Change or remove these accounts before any real deployment.**

### 5. Seed equipment

```bash
node seedEquipment.js
```

Adds 5 categories and 11 equipment items. It is safe to run more than once: existing categories and equipment names are skipped. Items are recorded as added by the staff account whose email is set in `STAFF_EMAIL` at the top of `seedEquipment.js`.

> **Heads up:** `seedEquipment.js` looks for `staff1@example.com`, but `createUsers.js` creates `staff2@example.com`. Update one of them so they match, otherwise seeding will stop with "Staff user not found".

### 6. Run the app

```bash
npm start        # production
npm run dev      # development with auto-reload (nodemon)
```

The app runs at <http://localhost:3000>.

## Routes

| Method | Path       | Description                                            |
| ------ | ---------- | ------------------------------------------------------ |
| GET    | `/`        | Redirects to the user's role page, or to `/login.html` |
| POST   | `/signup`  | Create an account (rate limited)                       |
| POST   | `/login`   | Log in with email and password (rate limited)          |
| GET    | `/logout`  | Destroy the session and return to the login page       |
| \*     | `/student` | Student routes                                         |
| \*     | `/staff`   | Staff routes                                           |
| \*     | `/admin`   | Admin routes                                           |

## Sample Equipment

| Category    | Items                                  |
| ----------- | -------------------------------------- |
| Camera      | Canon EOS R50, GoPro Hero 11, Tripod   |
| Laptop      | Dell Latitude 5420, MacBook Air M1     |
| Audio       | Rode Wireless GO II, Bluetooth Speaker |
| Electronics | Arduino Uno Kit, Raspberry Pi 4        |
| Accessories | HDMI Cable 2m, USB-C Hub               |

## Security Notes

- Set a strong `SESSION_SECRET`; the built-in fallback is for local development only.
- Enable `secure: true` on the session cookie when serving over HTTPS.
- Login returns the same response for an unknown email and a wrong password to avoid revealing which accounts exist.
- Replace the demo `1234` passwords before deploying.

## Repository

<https://github.com/Austinkle/SIIT-Rental-Service>

## License

ISC
