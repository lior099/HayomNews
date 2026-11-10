# היום. — Hayom News (MVP 0.1)

A Hebrew RTL iPhone news reader and Python backend. Includes: latest news, daily digest, region/category filtering, saved stories (local), source links, pull-to-refresh, RSS aggregation and optional AI summaries.

## Backend

Requires Python 3.11+.

```bash
cd backend
python -m venv .venv
source .venv/bin/activate   # Windows: .venv\\Scripts\\activate
pip install -r requirements.txt
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

Test `http://localhost:8000/health`, `http://localhost:8000/news` and `http://localhost:8000/daily`. Set `OPENAI_API_KEY` in your environment to enable AI summarization (never embed keys in the iOS app). The backend calls the AI service on each request; for production, add response caching and rate limits to control costs.

## iPhone app

1. On a Mac, open Xcode 16+ and create an **iOS App** project named `HayomNews` (SwiftUI, Swift).
2. Replace the generated app source with the four Swift files in `ios/HayomNews/` and add them to the app target.
3. In `NewsStore.swift`, replace `https://YOUR-SERVER.example.com` with your backend's reachable **HTTPS** URL.
4. Build and run on an iPhone Simulator or a signed physical iPhone (Apple developer signing required for device installation).
5. For simulator-only local HTTP testing, use `http://localhost:8000` and add an appropriate temporary App Transport Security development exception in the Xcode project. Never ship an unrestricted ATS exception.

## Current limitations / next milestones

- RSS endpoints are best-effort and may change, fail, or be subject to publisher terms. Check usage rights and reliability before production.
- The event grouping currently only merges almost-identical titles; **it does not yet reliably recognize the same event across different languages or publishers**. Source counts are not a trust score.
- The daily endpoint uses the **UTC calendar day**, not the Israel calendar day. Adjust to `Asia/Jerusalem` before production.
- The app has no background notifications, user accounts, offline cache, full-text extraction, automated tests or App Store deployment.
- Saved stories store only IDs, so they remain visible only while the server continues to return those stories.
- AI is optional and only summarizes feed headlines/excerpts, not full articles; source attribution must be checked before trusting claims.
- Do not reproduce copyrighted article bodies without permission. Provide attribution and links.

## Suggested next steps

Improve multilingual clustering, add reliable licensed feeds, move daily processing to a scheduled job, cache summaries in a database, add per-story fact checks, notifications and automated tests.
