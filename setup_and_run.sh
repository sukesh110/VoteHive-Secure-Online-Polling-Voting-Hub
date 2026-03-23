#!/usr/bin/env bash
# ============================================================
# VoteHive – One-Script Setup & Run (No Docker)
# Usage: bash setup_and_run.sh
# ============================================================
set -e

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo ""
echo -e "${CYAN}🐝  VoteHive Setup Script${NC}"
echo "=================================================="

# ── 1. Check Python ──────────────────────────────────
echo -e "\n${YELLOW}[1/6] Checking Python...${NC}"
if ! command -v python3 &>/dev/null; then
  echo -e "${RED}Python 3 not found. Install from https://python.org${NC}"; exit 1
fi
PYVER=$(python3 --version)
echo -e "${GREEN}✓ $PYVER${NC}"

# ── 2. Check Node ────────────────────────────────────
echo -e "\n${YELLOW}[2/6] Checking Node.js...${NC}"
if ! command -v node &>/dev/null; then
  echo -e "${RED}Node.js not found. Install from https://nodejs.org${NC}"; exit 1
fi
NODEVER=$(node --version)
echo -e "${GREEN}✓ Node $NODEVER${NC}"

# ── 3. Backend: venv + packages ──────────────────────
echo -e "\n${YELLOW}[3/6] Setting up Python virtual environment...${NC}"
cd backend

if [ ! -d "venv" ]; then
  python3 -m venv venv
  echo -e "${GREEN}✓ Created venv${NC}"
fi

source venv/bin/activate
pip install --upgrade pip -q
pip install -r requirements.txt -q
echo -e "${GREEN}✓ Python packages installed${NC}"

# ── 4. Backend: DB + Seed ────────────────────────────
echo -e "\n${YELLOW}[4/6] Initialising database & seeding data...${NC}"
export FLASK_APP=run.py
export FLASK_ENV=development

python3 - << 'PYEOF'
from app import create_app
from app.extensions import db
app = create_app()
with app.app_context():
    db.create_all()
    print("  ✓ Tables created")
PYEOF

python3 seed_data/seed_voters.py
python3 seed_data/seed_election.py
echo -e "${GREEN}✓ Database ready${NC}"

cd ..

# ── 5. Frontend: npm install ─────────────────────────
echo -e "\n${YELLOW}[5/6] Installing frontend packages...${NC}"
cd frontend
npm install --silent
echo -e "${GREEN}✓ npm packages installed${NC}"
cd ..

# ── 6. Launch both servers ───────────────────────────
echo -e "\n${YELLOW}[6/6] Starting servers...${NC}"
echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  Backend  → http://localhost:5000${NC}"
echo -e "${GREEN}  Frontend → http://localhost:5173${NC}"
echo ""
echo -e "${CYAN}  Demo Admin:  admin@votehive.com / Admin@123${NC}"
echo -e "${CYAN}  Demo Voter:  voter1@demo.com  (OTP prints in terminal)${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "  Press ${RED}Ctrl+C${NC} to stop both servers."
echo ""

# Start backend in background
cd backend
source venv/bin/activate
python3 run.py &
BACKEND_PID=$!
echo -e "${GREEN}  ✓ Backend started (PID $BACKEND_PID)${NC}"
cd ..

# Give backend 2 seconds to start
sleep 2

# Start frontend in foreground
cd frontend
npm run dev &
FRONTEND_PID=$!
echo -e "${GREEN}  ✓ Frontend started (PID $FRONTEND_PID)${NC}"
cd ..

# Wait / cleanup on Ctrl+C
trap "echo ''; echo 'Shutting down...'; kill $BACKEND_PID $FRONTEND_PID 2>/dev/null; exit 0" INT TERM
wait
