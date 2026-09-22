# Student Manager — React + Spring Boot + MariaDB (Gruvbox Dark Medium, local only)

```
student-app/
  frontend/  → React + Vite (:5173)
  backend/   → Spring Boot + JPA (:8080)
```

## Prereqs

- Java 17+, Node 18+, MariaDB running locally

## Run

```bash
./start.sh         # starts MariaDB + backend (:8080) + frontend (:5173)
./start.sh status  # check what's running
./start.sh stop    # stop everything
```

- App: http://localhost:5173 · API: http://localhost:8080/api/students
- Logs: `.backend.log`, `.frontend.log`
- The script uses system MariaDB if available, else a user-local server
  (`~/.local/share/student-app/mysql`, bound to 127.0.0.1).

## Run manually

```bash
# 1. DB (once) — start system MariaDB if you have permission,
# otherwise ./start.sh handles a user-local server for you
systemctl start mariadb
mariadb -u root -p -e "CREATE DATABASE IF NOT EXISTS studentdb;"

# 2. backend (terminal 1)
cd backend
DB_URL=jdbc:mariadb://localhost:3306/studentdb DB_USER=root DB_PASS=root mvn spring-boot:run
# → http://localhost:8080/api/students

# 3. frontend (terminal 2)
cd frontend
npm install
npm run dev
# → http://localhost:5173
```

Vite proxies `/api` → `localhost:8080`, so no CORS setup needed.

API: `GET/POST /api/students`, `GET/PUT/DELETE /api/students/{id}`

## Colors — Gruvbox Dark Medium
bg `#282828`, bg0_h `#1d2021`, bg1 `#3c3836`, fg `#ebdbb2`, yellow `#fabd2f`, green `#b8bb26`, blue `#83a598`, red `#fb4934`, aqua `#8ec07c`.
