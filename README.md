# 🐝 VoteHive – Secure Online Polling & Voting Hub

Full-stack voting platform: OTP authentication, AES-256 encrypted ballots,
real-time admin dashboard, complete audit trail.

---

## ⚡ Quick Start (No Docker)

```bash
bash setup_and_run.sh
```

That's it. Opens at **http://localhost:5173**

---

## 🔑 Demo Login Credentials

| Role        | Email                  | Password   | Notes                        |
|-------------|------------------------|------------|------------------------------|
| **Admin**   | admin@votehive.com     | Admin@123  | Full admin panel access      |
| **Voter**   | voter1@demo.com        | —          | OTP is printed in terminal   |
| **Voter**   | voter2@demo.com        | —          | OTP is printed in terminal   |

> **Dev mode**: OTPs are not sent via email/SMS. They print to the backend terminal like:
> ```
> ==================================================
> [DEV EMAIL] OTP for Aryan Mehta (voter1@demo.com): 483920
> ==================================================
> ```

---

## 🛠 Manual Setup (Step by Step)

### Prerequisites
- Python 3.10 or higher
- Node.js 18 or higher
- (Optional) PostgreSQL 14+ for production

### Step 1 — Backend

```bash
cd backend

# Create and activate virtual environment
python3 -m venv venv
source venv/bin/activate          # Mac/Linux
# OR: venv\Scripts\activate       # Windows

# Install dependencies
pip install -r requirements.txt

# Copy environment config
cp .env.example .env
# .env already has working SQLite config — no changes needed for local dev
```

### Step 2 — Create Database & Seed

```bash
# Still inside backend/ with venv active

# Create all tables
python3 -c "from app import create_app; from app.extensions import db; app=create_app(); app.app_context().push(); db.create_all()"

# Seed 50 demo voters + admin account
python3 seed_data/seed_voters.py

# Seed sample election with 5 candidates
python3 seed_data/seed_election.py
```

**Expected output:**
```
Created admin: admin@votehive.com / Admin@123
Seeded 50 voters.
Created election: Student Council Election 2025
Created 5 candidates.
```

### Step 3 — Start Backend

```bash
# Still inside backend/ with venv active
python3 run.py
# → Running on http://localhost:5000
```

### Step 4 — Start Frontend (new terminal)

```bash
cd frontend
npm install
npm run dev
# → Running on http://localhost:5173
```

---

## 📁 Project Structure

```
votehive/
├── setup_and_run.sh              ← ONE COMMAND to run everything
├── backend/
│   ├── .env                      ← Local config (SQLite, no email needed)
│   ├── requirements.txt
│   ├── run.py                    ← Entry point: python run.py
│   ├── app/
│   │   ├── __init__.py           ← Flask app factory
│   │   ├── config.py             ← Dev/Prod/Test config
│   │   ├── extensions.py         ← db, jwt, socketio, limiter
│   │   ├── models/
│   │   │   ├── voter.py          ← Voter (name, email, phone, govt_id_hash)
│   │   │   ├── admin.py          ← Admin (username, email, password_hash, role)
│   │   │   ├── election.py       ← Election (title, dates, status)
│   │   │   ├── candidate.py      ← Candidate (name, party, manifesto)
│   │   │   ├── vote.py           ← Vote (encrypted_blob, iv) UNIQUE(voter,election)
│   │   │   ├── otp.py            ← OTPToken (code_hash, expires_at)
│   │   │   └── audit_log.py      ← AuditLog (actor, action, ip, timestamp)
│   │   ├── routes/
│   │   │   ├── auth.py           ← /api/auth/* (register, OTP, login)
│   │   │   ├── voter.py          ← /api/voter/* (elections, vote, status)
│   │   │   ├── admin.py          ← /api/admin/* (elections CRUD, stats)
│   │   │   ├── results.py        ← /api/results/* (public results)
│   │   │   └── audit.py          ← /api/audit/* (logs, CSV export)
│   │   ├── services/
│   │   │   ├── crypto_service.py ← AES-256-CBC encrypt/decrypt (hex strings)
│   │   │   ├── otp_service.py    ← bcrypt OTP generate/verify
│   │   │   ├── vote_service.py   ← cast vote, duplicate check, live stats
│   │   │   ├── email_service.py  ← SendGrid (console fallback in dev)
│   │   │   └── sms_service.py    ← Twilio (console fallback in dev)
│   │   └── utils/
│   │       ├── decorators.py     ← @admin_required, @voter_required
│   │       └── audit.py          ← log_action() helper
│   └── seed_data/
│       ├── seed_voters.py        ← 50 voters + admin
│       └── seed_election.py      ← election + 5 candidates
│
├── frontend/
│   └── src/
│       ├── App.jsx               ← Routes + guards
│       ├── index.css             ← Design system (CSS variables, components)
│       ├── api/axiosClient.js    ← Axios + JWT interceptor + auto-refresh
│       ├── context/AuthContext.jsx
│       ├── components/
│       │   ├── Navbar.jsx
│       │   ├── OTPInput.jsx      ← 6-box OTP entry with paste support
│       │   ├── CandidateCard.jsx
│       │   └── LiveChart.jsx     ← Bar + Pie charts (Recharts)
│       └── pages/
│           ├── LandingPage.jsx
│           ├── RegisterPage.jsx
│           ├── LoginPage.jsx     ← 2-step OTP flow
│           ├── VoterDashboard.jsx
│           ├── VotingBooth.jsx   ← Select candidate + confirm modal
│           ├── ResultsPage.jsx   ← Live/final results + winner banner
│           └── admin/
│               ├── AdminLogin.jsx
│               ├── AdminDashboard.jsx
│               ├── ElectionManager.jsx
│               ├── CandidateManager.jsx
│               ├── LiveMonitor.jsx   ← Socket.IO real-time stats
│               ├── VoterManager.jsx
│               └── AuditReport.jsx   ← Color-coded logs + CSV export
│
└── database/
    └── schema.sql                ← Full PostgreSQL DDL for reference
```

---

## 🔐 Security Architecture

### Vote Encryption (AES-256-CBC)
```
Voter selects candidate
       ↓
candidate_id (string)
       ↓
AES-256-CBC encrypt with fresh random 16-byte IV
       ↓
(ciphertext_hex, iv_hex) stored in votes table
       ↓
Only server-side AES_SECRET_KEY can decrypt
       ↓
Admin closes election → server decrypts all → tallies results
```

### OTP Flow
```
Voter submits email/phone
       ↓
Generate 6-digit OTP → bcrypt hash → store in DB (10-min expiry)
       ↓
Send plaintext OTP via email/SMS (or print to console in dev)
       ↓
Voter enters OTP → bcrypt verify → JWT issued on success
       ↓
Access token (15 min) + Refresh token (7 days)
```

### Duplicate Vote Prevention (3 layers)
1. **Route check** — query votes table before accepting
2. **DB constraint** — `UNIQUE(voter_id, election_id)` at schema level
3. **JWT scope** — tokens invalidated after successful vote cast

---

## 🌐 Switch to PostgreSQL

```bash
# 1. Create database
createdb votehive

# 2. Update .env
DATABASE_URL=postgresql://youruser:yourpassword@localhost:5432/votehive

# 3. Uncomment psycopg2 in requirements.txt, reinstall
pip install psycopg2-binary

# 4. Re-run migrations
python3 -c "from app import create_app; from app.extensions import db; app=create_app(); app.app_context().push(); db.create_all()"
```

---

## 🌐 Enable Real Email/SMS

```bash
# .env — add your credentials:
SENDGRID_API_KEY=SG.xxxxxxxxxx
TWILIO_ACCOUNT_SID=ACxxxxxxxxxx
TWILIO_AUTH_TOKEN=xxxxxxxxxx
TWILIO_PHONE_NUMBER=+1234567890

# requirements.txt — uncomment:
# twilio==8.10.3
# sendgrid==6.11.0

pip install twilio sendgrid
```

---

## 🧪 Run Tests

```bash
cd backend
source venv/bin/activate
pytest tests/ -v
```

---

## 🚀 Deploy to Render (Free)

1. Push to GitHub
2. **New Web Service** → connect `backend/` folder
   - Build: `pip install -r requirements.txt`
   - Start: `gunicorn run:app`
   - Add env vars from `.env` (change AES_SECRET_KEY and JWT_SECRET_KEY!)
3. **New Static Site** → connect `frontend/` folder
   - Build: `npm install && npm run build`
   - Publish: `dist`
4. **New PostgreSQL** → copy DATABASE_URL to backend service env vars
