# LiftMove Backend
## Setup
1. Copy .env.example to .env and fill your local MySQL credentials
2. Run basededatos.sql in MySQL Workbench
3. pip install -r requirements.txt
4. python import_exercises.py
5. uvicorn main:app --reload --host 0.0.0.0 --port 8000

