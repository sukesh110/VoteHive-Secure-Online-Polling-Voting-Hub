@echo off
setlocal enabledelayedexpansion

echo.
echo  ==========================================
echo   VoteHive - Setup and Run (Windows)
echo  ==========================================
echo.

:: ── 1. Check Python ──
echo [1/6] Checking Python...
python --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Python not found.
    echo Install from https://python.org  (check "Add to PATH")
    pause & exit /b 1
)
python --version
echo.

:: ── 2. Check Node ──
echo [2/6] Checking Node.js...
node --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Node.js not found.
    echo Install from https://nodejs.org
    pause & exit /b 1
)
node --version
echo.

:: ── 3. Python venv + packages ──
echo [3/6] Setting up Python virtual environment...
cd backend

if not exist venv (
    python -m venv venv
    echo   Created venv
)

call venv\Scripts\activate.bat
pip install --upgrade pip -q
pip install -r requirements.txt -q
echo   Python packages installed.
echo.

:: ── 4. Database + Seed ──
echo [4/6] Creating database and seeding demo data...
python -c "from app import create_app; from app.extensions import db; app=create_app(); app.app_context().push(); db.create_all(); print('  Tables created.')"
python seed_data\seed_voters.py
python seed_data\seed_election.py
echo.

cd ..

:: ── 5. Frontend packages ──
echo [5/6] Installing frontend packages...
cd frontend
call npm install --silent
echo   npm packages installed.
cd ..
echo.

:: ── 6. Launch servers ──
echo [6/6] Starting servers...
echo.
echo  ==========================================
echo   Backend  ^>  http://localhost:5000
echo   Frontend ^>  http://localhost:5173
echo.
echo   Admin:  admin@votehive.com / Admin@123
echo   Voter:  voter1@demo.com   (OTP in backend window)
echo  ==========================================
echo.
echo  Two windows will open - keep both running.
echo  Close this window or press Ctrl+C to stop.
echo.

:: Start backend in a new window
start "VoteHive Backend" cmd /k "cd backend && call venv\Scripts\activate.bat && python run.py"

:: Wait for backend to start
timeout /t 3 /nobreak >nul

:: Start frontend in a new window
start "VoteHive Frontend" cmd /k "cd frontend && npm run dev"

echo  Both servers are starting in separate windows.
echo  Open http://localhost:5173 in your browser.
echo.
pause
