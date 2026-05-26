<!-- BEGIN:nextjs-agent-rules -->
# This is NOT the Next.js you know

This version has breaking changes — APIs, conventions, and file structure may all differ from your training data. Read the relevant guide in `node_modules/next/dist/docs/` before writing any code. Heed deprecation notices.
<!-- END:nextjs-agent-rules -->

# مسابقة أهل القرآن الكبرى — Next.js Web

## Design System
- **Primary**: `#003527` (أخضر عميق)
- **Secondary**: `#735c00` (ذهبي داكن)
- **Secondary Fixed**: `#ffe088` (ذهبي فاتح)
- **Surface**: `#fbf9f5` (كريمي)
- **Fonts**: Cairo (body), Noto Serif (headings)
- **RTL** throughout

## Pages
| Route | Description |
|-------|-------------|
| `/` | Homepage: Hero (typewriter + word-by-word), Stats (Supabase + CountUp), Features, Journey (5 steps), FAQ (from `app_settings.faqs`), CTA, Footer |
| `/levels` | Levels grid with per-level prizes (first_prize, second_prize, third_prize) |
| `/register` | Multi-step registration form (5 steps) |
| `/status` | Inquiry: form → result OR ceremony inquiry |

## API Routes
| Route | Source | Notes |
|-------|--------|-------|
| `POST /api/register` | `students` table | Validates Egyptian phone, needs service_role_key |
| `POST /api/inquiry` | `students` table | By national_id + phone |
| `GET /api/result` | `students` + `app_settings.is_result_query_open` | needs service_role_key |
| `GET /api/ceremony` | `students` + `app_settings` | needs service_role_key |
| `GET /api/faq` | `app_settings.faqs` (JSONB) | Dynamic from admin Flutter app |

## Key Files
| File | Purpose |
|------|---------|
| `src/app/globals.css` | Colors, glass-card, islamic-pattern SVG base64, animate-title-glow |
| `src/lib/database.types.ts` | TS types for CompetitionLevel (with first_prize, second_prize, third_prize), StudentStatus, AppSettings |
| `src/lib/supabase-admin.ts` | Admin client using SUPABASE_SERVICE_ROLE_KEY |
| `.env.local` | NEXT_PUBLIC_SUPABASE_URL + NEXT_PUBLIC_SUPABASE_ANON_KEY |

## Important Notes
- `SUPABASE_SERVICE_ROLE_KEY` required for `/api/result` and `/api/ceremony` — must be added to `.env.local`
- Levels prizes (`first_prize`, `second_prize`, `third_prize`) managed from Flutter admin, displayed on web
- Country/nationality field does not exist — location is free-text address
- FAQ fetched from `app_settings.faqs` JSONB column (not separate table)

