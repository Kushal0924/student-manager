# Student Manager — React + Spring Boot + MariaDB (local only)

```
student-app/
  frontend/  → React
  backend/   → Spring Boot 
```

## Prerequisites

- Java 17+, NodeJS, MariaDB running locally
  
  (Since I'm using Arch Linux, it uses MariaDB as its default drop-in replacement for MySQL)
  

## Run

```bash
./start.sh         # starts MariaDB + backend + frontend
./start.sh stop    # stop everything
```

- App: http://localhost:5173 · API: http://localhost:8080/api/students
- Logs: `.backend.log`, `.frontend.log`


## Working
```
Browser                  Spring Boot                 MariaDB
┌──────────────┐         ┌───────────────┐           ┌──────────────┐
│ React (JSX)  │ ──────► │ REST API      │ ────────► │ studentdb    │
│ fetch()      │         │ Controller    │           │ students     │
│ Gruvbox CSS  │ ◄────── │ Repository    │ ◄──────── │ (table)      │
└──────────────┘         └───────────────┘           └──────────────┘
```


## Colors — Gruvbox Dark Medium
Credits: https://github.com/morhetz/gruvbox

