@echo off
echo Starting VoteHive Backend...
cd backend
call venv\Scripts\activate.bat
python run.py
pause
