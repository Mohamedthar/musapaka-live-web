# Quran Contest Management Website — Complete Design Specification

## Overview

A bilingual (Arabic-first) web application for managing a Quran memorization competition. The site allows public users to register, check results, and get ceremony invitations. The admin dashboard is a separate Flutter app (not part of this design).

**Direction:** RTL (Arabic)  
**Font:** Cairo (Google Fonts) — weights: 400, 600, 700, 800, 900  
**Platform:** Next.js 16 + React 19 + Tailwind CSS 4  

---

## Design System

### Colors
```
Primary (Navy):     #0F172A   — headings, primary buttons, dark sections
Primary Light:      #334155   — secondary text
Primary Muted:      #94A3B8   — muted text, placeholders
Gold (Accent):      #D4A853   — CTA buttons, active states, decorative elements
Gold Light:         #FEF9EF   — gold badge backgrounds
Gold Dark:          #B8943A   — gold hover states
Blue (Secondary):   #4A6CF7   — links, focus rings, accent highlights
Success (Green):    #059669   — success states, positive results
Warning (Amber):    #D97706   — warning states, closed sections
Danger (Red):       #DC2626   — errors, delete actions

Backgrounds:
  Page:             #FFFFFF
  Section:          #F8FAFC   — alternating section backgrounds
  Card:             #FFFFFF
  Input:            #F8FAFC

Borders:            #E2E8F0
Border Light:       #F1F5F9

Dark Theme (Header only):
  Background:       #0B1120 (92% opacity + backdrop blur 20px)
  Border:           rgba(255,255,255,0.06)
  Text:             white / rgba(255,255,255,0.6)
  Active:           #D4A853 (gold)
  Hover bg:         rgba(255,255,255,0.04)
```

### Typography Scale
```
Hero Title:      clamp(32px, 6vw, 56px)  weight:900  color:white (on dark) / navy (on light)
Page Title:      28-32px                  weight:900  color:navy
Section Title:   24-28px                  weight:900  color:navy
Card Title:      16-18px                  weight:800  color:navy
Body:            14px                     weight:600  color:secondary
Small/Caption:   11-12px                  weight:600-700  color:muted
Button:          13-14px                  weight:700
```

### Spacing
```
Section padding:    80px 0
Card padding:       24px (desktop), 20px (mobile)
Input padding:      12px 48px 12px 16px (right icon + left text for RTL)
Button padding:     12px 24px (medium), 16px 32px (large)
Gap between cards:  20px
Gap between items:  12px
```

### Border Radius
```
Cards:      18px (rounded-2xl)
Buttons:    14px
Inputs:     14px
Badges:     9999px (full round)
Tabs:       18px
```

### Shadows
```
Card:       0 1px 2px rgba(0,0,0,0.04)
Card Hover: 0 8px 30px rgba(0,0,0,0.06)
Button:     0 2px 8px rgba(0,0,0,0.08)
Large:      0 12px 40px rgba(0,0,0,0.08)
```

---

## Component Library

### 1. Button
```
Variants:
  - btn-primary: bg-navy, white text, hover:darkens
  - btn-gold: bg-gold, navy text, hover:gold-dark
  - btn-outline: transparent, navy text, 1.5px border, hover:bg-gray-50
  - btn-danger: bg-red, white text
Sizes: medium (12px 24px), large (16px 32px)
State: normal, hover (-translateY 1px), active, disabled (opacity 0.4)
Animation: 200ms ease transition
```

### 2. Card
```
Structure: white background, 1px border, 18px radius, subtle shadow
Hover: shadow increases, card lifts -2px
Variants:
  - Default card
  - Elevated card (more shadow on hover)
  - Interactive card (cursor pointer, full hover effects)
```

### 3. Input Field
```
Structure: relative container with icon
  - Icon: absolute positioned, right 14px, centered vertically
  - Field: 14px radius, 2px border, bg-input, padding 12px 48px 12px 16px
States:
  - Default: border-light, bg-input
  - Focus: border-accent(blue), bg-white, 4px blue glow ring
  - Error: border-red-300, bg-red-50
  - Disabled: opacity 0.5, cursor not-allowed
  - Read-only: bg-blue-50, border-blue-200 (auto-calculated values)
Label: 13px, weight 800, color navy, 6px margin bottom
Required mark: red asterisk
Error message: 11px, weight 700, color red, 4px margin top
Helper text: 11px, color muted, 4px margin top
```

### 4. Badge/Tag
```
Structure: inline-flex, gap 6px, padding 4px 14px, full radius
Variants:
  - Default: bg-section, border, text-secondary
  - Gold: bg-gold-light, border-gold, text-gold-dark
  - Success: bg-green-50, border-green-200, text-green-700
  - Warning: bg-amber-50, border-amber-200, text-amber-700
  - Danger: bg-red-50, border-red-200, text-red-600
Size: 11px font
```

### 5. Tab Navigation
```
Container: inline-flex, bg-gray-100, 18px radius, 4px padding, 2px gap
Tab Button: 10px 20px padding, 14px radius, font 13px weight 700
States:
  - Active: white bg, navy text, subtle shadow
  - Inactive: transparent, muted text
  - Hover: text-secondary
Icons: 16px, shown before text
Responsive: On mobile, show icon + short label
Animation: 200ms ease transition
```

### 6. Stepper (Multi-step form progress)
```
Structure: horizontal row, centered
Step: circle (32px) + label below
  - Active: gold border, gold-light bg, gold text
  - Done: green bg, white checkmark
  - Future: gray border, muted text
Connector: 40px line, 2px height, gray (turns green when done)
Responsive: On mobile, hide labels, reduce connector width to 20px
```

### 7. Table
```
Structure: full width, 18px radius, 1px border, overflow hidden
Header: bg-section, 12px padding 16px, text-right, font 12px weight 800, text-secondary
Row: 13px font, weight 600, 12px padding 16px, border-top light
Total row: border-top 2px, weight 900, font 15px, bg-section
Hover row: bg-gray-50
```

### 8. Grade Display
```
Structure: inline-flex, gap 8px, padding 8px 24px, 18px radius, font 20px weight 900
Variants:
  - Pass (≥50%): green-50 bg, green-200 border, green-700 text
  - Honors (≥95%): amber-50 bg, amber-200 border, amber-700 text
  - Fail (<50%): red-50 bg, red-200 border, red-600 text
```

### 9. Closed State Card
```
Structure: max-width 420px, centered, white card with 3px amber gradient top bar
Icon: 64px amber-50 square, amber-500 icon, 20px margin
Status: inline amber pill with pulsing dot animation
Title: 18px, weight 900, navy
Description: 13px, muted, line-height 1.8
Bottom: border-top, hint text 11px muted
Animation: fade-in 400ms
```

### 10. Spinner / Loading
```
Structure: 24-32px circle, 3px border gray-200, border-top navy
Animation: spin 700ms linear infinite
Container: centered in viewport, column layout with "جاري التحميل..." text below
```

### 11. Header / Navbar (DARK THEME)
```
Background: rgba(11,17,32,0.92) + backdrop-blur 20px
Border bottom: 1px rgba(255,255,255,0.06)
Height: 64px
Sticky: top 0, z-index 100

Logo: gold circle with "ق" character + white "مسابقة القرآن الكريم" text
Nav links:
  - Color: rgba(255,255,255,0.6), font 12px weight 800
  - Hover: gold, bg rgba(255,255,255,0.04)
  - Active: gold color + 2px gold bottom line (scale animation)
  - Padding: 8px 12px, 8px radius
CTA button: gold bg, navy text, weight 800, font 13px, 10px radius, 8px 16px padding

Mobile: hamburger menu icon, navigation hidden (shown as dropdown when toggled)
Animation: fade-in on load (translateY -20px → 0)
```

### 12. Footer (DARK THEME)
```
Background: #0F172A (navy)
Padding: 60px 0 30px
Grid: auto-fit, minmax(200px, 1fr), gap 32px
Columns:
  1. Quick links (vertical list, gold hover)
  2. Contact info (email, phone, address with icons)
  3. About text
Section titles: 12px, weight 900, white/40 opacity, uppercase, letter-spacing 1px
Links: 13px, weight 600, white/50 opacity, gold hover
Contact text: 13px, white/50, flex column, gap 8px
Bottom: border-top white/6, 40px margin top, centered text 11px white/25
```

---

## Page-by-Page Specification

---

## PAGE 1: Homepage (`/`)

### Layout (top to bottom)

**1. Header (dark navbar)**

**2. Hero Section**
```
Background: Gradient 135deg from #0B1120 → #0F172A → #131C31
Full width, 100px top padding, 80px bottom
Decorative elements:
  - Large radial gradient blob (gold, 8% opacity, top-right, 600px)
  - Dot pattern overlay (3% opacity, 60px grid)
Content (centered, z-index 2):
  - Badge: "✨ الموسم الأول — 2026" (gold pill)
  - Title: "منصة مسابقة القرآن الكريم" (white, 32-56px, weight 900)
    With "مسابقة القرآن" in gold span
  - Description: 16px, white/50, max-width 600px, line-height 1.8
  - Two CTA buttons: Gold "سجل الآن في المسابقة" (large) + 
    Outline "استعلم عن نتيجتك" (white border, large)
```

**3. Features Section**
```
Background: White, 80px padding
Section header:
  - Gold badge "مميزات المنصة"
  - Title "كل ما تحتاجه لإدارة المسابقة" (24-32px, weight 900)
  - Description (14px, muted, max 500px)
4 cards in responsive grid (auto-fit, minmax 260px):
  Each card:
    - 56px icon square (bg-section, rounded, icon center)
    - Title (16px, weight 800)
    - Description (13px, muted, line-height 1.7)
  Card hover: shadow increases, translates -4px up, 300ms ease
  Staggered fade-in animation (0.1s delay each)

Icons/Content:
  Card 1: 📝 — "تسجيل إلكتروني" — "نموذج تسجيل متكامل مع رفع المستندات والصور بشكل آمن وسهل"
  Card 2: 🎯 — "جدولة تلقائية" — "توزيع المتسابقين على لجان الاختبار تلقائياً حسب المستويات والمواعيد"
  Card 3: 📊 — "تقييم وتحكيم" — "نظام تقييم متعدد المعايير: التلاوة، التجويد، الصوت، والتفسير"
  Card 4: 🏆 — "نتائج وتكريم" — "إعلان النتائج فورياً مع شهادات تقدير وبطاقات دعوة للحفل الختامي"
```

**4. Statistics Section**
```
Background: #F8FAFC (section bg), 80px padding
4 stat cards in grid (4 columns desktop, 2 tablet, 1 mobile):
  Each: white card, 24px padding, centered text
    Number: 28px, weight 900, gold
    Label: 12px, weight 700, muted
Stats: "١٢ مستوى تنافسي", "٥٠٠+ متسابق مسجل", "٤ معايير تقييم", "٥٠+ لجنة تحكيم"
```

**5. Journey Steps Section**
```
Background: White, 80px padding
Section header: Gold badge "كيف تشارك", title, description
4 step cards (auto-fit grid, minmax 240px):
  Each: centered, 32px padding
    - Circle number (48px, navy bg, white text)
    - Title (16px, weight 800)
    - Description (13px, muted)
    - Connector line between steps (2px gray, hidden on last step, right-top)
Steps:
  1: "سجل بياناتك" — "املأ نموذج التسجيل بالبيانات الشخصية وارفع صورتك الشخصية وشهادة الميلاد"
  2: "اختر مستواك" — "حدد المستوى المناسب لعدد الأجزاء التي تحفظها والرواية المفضلة لديك"
  3: "احضر الاختبار" — "سيتم إعلامك بموعد ومكان الاختبار عبر بطاقة الاستمارة بعد التسجيل"
  4: "استلم نتيجتك" — "استعلم عن نتيجتك إلكترونياً فور اعتمادها من لجنة التحكيم"
```

**6. Footer**
```
Dark footer as described in component section
```

---

## PAGE 2: Levels & Prizes (`/levels`)

### Layout

**Header**

**Page Title Section**
```
Background: white, 80px padding
Centered:
  - Gold badge "المستويات"
  - Title "مستويات المسابقة وجوائزها" (28-32px, weight 900)
  - Description "اختر المستوى المناسب لقدراتك وتنافس على الجوائز القيمة" (14px, muted)
```

**Level Cards Grid** (auto-fit, minmax 300px, gap 20px)
```
Each card:
  - Top gradient bar (3px, gold-to-blue)
  - Level code square (40px, navy bg, white, 10px radius) — e.g. "A", "B", "C"
  - Title (18px, weight 900)
  - Content description (12px, muted) — e.g. "حفظ القرآن الكريم كاملاً (30 جزء)"
  - Features list (flex wrap, 8px gap)
    Each: 6px gold dot + 11px text secondary
    e.g. "جميع القراءات", "الأعمار: 8-18", "تلاوة + تجويد + صوت + تفسير"
  - Divider line (border-top)
  - Prizes: gold badges
    "🥇 5000 ج.م"  "🥈 3000 ج.م"  "🥉 1500 ج.م"
  - Age range badge
  - Max capacity badge (if applicable)
  - "سجل الآن" CTA link at bottom

Hover: shadow increases, card lifts -2px
Animation: stagger fade-in
```

**Empty State** (if no levels)
```
Centered card:
  - Icon (64px, gray-100 bg, muted icon)
  - Title "لا توجد مستويات نشطة حالياً"
  - Description "لم يتم إضافة مستويات المسابقة بعد. يرجى المتابعة لاحقاً."
```

**Loading State**
```
Centered spinner with "جاري تحميل المستويات..."
```

**Footer**

---

## PAGE 3: Registration Form (`/register`)

### Layout

**Header**

**Page Title Section**
```
Centered:
  - Icon square (64px, gold-light bg, gold icon — 📝)
  - Title "تسجيل متسابق جديد" (28-32px, weight 900)
  - Description "املأ البيانات بدقة للتسجيل في مسابقة القرآن الكريم"
```

**Stepper (Progress Indicator)**
```
Horizontal row, centered, margin bottom 32px
5 steps:
  1. البيانات الشخصية
  2. المستندات الرسمية
  3. اختيار المستوى
  4. مراجعة البيانات
  5. تأكيد التسجيل

Active step: gold circle + label
Done step: green checkmark + label
Future step: gray circle + muted label
Connector lines between steps: 40px, 2px height
```

**Step 1: Personal Data**
```
White card form:
Fields:
  - Full name (required) — text input with 👤 icon, placeholder "أدخل الاسم الرباعي كاملاً"
    Validation: min 10 chars (4 names in Arabic)
  - National ID (required) — text input, 14 digits max, numeric keyboard
    Auto-extracts: birth date, age, gender, governorate
    Shows calculated fields as read-only (blue bg):
      - Birth date
      - Age
      - Gender
  - Phone number (required) — tel input, 11 digits, Egyptian format
    Prefixes: 010, 011, 012, 015
    Validation: regex check
  - Memorizer name (required)
  - Memorizer phone (optional)
  - Memorizer address (optional)
  - Location/residence (optional)
Bottom: "التالي ←" button (gold)
```

**Step 2: Documents**
```
White card:
  - Profile photo upload area
    Square zone, dashed border, click to upload
    Shows preview after selection
    Accepts: jpg, jpeg, png
    Max size: 5MB
  - Birth certificate upload area
    Same style as profile photo
Bottom: "السابق" + "التالي ←" buttons
```

**Step 3: Level Selection**
```
White card:
  - Level dropdown selector
    Shows active levels with: title + content + age range
    Filtered by student's age
  - Rewaya/Reading style selector (if applicable to level)
  - Branch name (if applicable)
  - Memorization amount (dropdown: 1-30 parts)
Bottom: "السابق" + "التالي ←" buttons
```

**Step 4: Review**
```
White card:
  - Summary of all entered data in a clean layout
  - Profile image preview
  - Birth certificate preview
  - Level info
  - Turnstile CAPTCHA widget
  - Terms checkbox: "أوافق على شروط المسابقة وأتعهد بصحة البيانات"
Bottom: "السابق" + "تأكيد التسجيل" button (gold, large)
```

**Step 5: Success**
```
Full-width receipt/application form:
  - Header with competition logo and title
  - Student info grid (name, code, level, age, gender, rewya)
  - Exam schedule (day, date, time) — red/bold if waitlist
  - Official info grid (national ID, phone, memorizer details, address)
  - Profile photo
  - Download as image button
  - Print button
  - New search button (returns to step 1)

Waitlist mode: If no exam slot assigned yet, show orange warning:
  "تنبيه: أنت حالياً على قائمة الانتظار!"
  "لم يتم تحديد موعد اختبار لك بعد. سيتم إعلامك فور توفر موعد."
```

**States:**
- Loading: spinner while submitting
- Duplicate name error: red alert "هذا الاسم مسجل مسبقاً"
- Duplicate ID error: red alert "هذا الرقم القومي مسجل مسبقاً"
- Level full error: red alert "المستوى ممتلئ — اختر مستوى آخر"
- Network error: red alert "فشل الاتصال — حاول مرة أخرى"
- Tour guide (onboarding): react-joyride highlighting form fields step by step

**Footer**

---

## PAGE 4: Status / Inquiry (`/status`)

### Layout

**Header**

**Tab Navigation** (centered, margin top 32px, margin bottom 40px)
```
Pill container: gray-100 bg, 18px radius, 4px padding, 2px gap
3 tabs:
  1. 📋 الاستمارة (Form)
  2. 🏆 النتيجة (Result)
  3. 🎖️ حفل التكريم (Ceremony)

Each tab: 10px 20px padding, 14px radius
Active: white bg, navy text, subtle shadow
Inactive: transparent, muted text
Icon: 16px, shown before label
Responsive mobile: icon + short label ("استمارة", "نتيجة", "الحفل")
200ms transition
```

---

### Tab 1: Form Inquiry (الاستمارة)

```
Centered layout, max-width 480px

Header area:
  - Icon square (64px, blue-50 bg, blue-500 icon — shield check)
  - Title "استعلام الاستمارة وموعد الاختبار" (28-32px, weight 900)
  - Description "أدخل الرقم القومي ورقم الهاتف المستخدمين أثناء التسجيل..." (14px, muted)

Form card:
  - National ID input (14 digits, 🪪 icon)
  - Phone input (11 digits, 📱 icon)
  - Error area (red background, border, centered text)
  - Submit button: gold gradient, full width, "عرض الاستمارة" with arrow icon

Success state: Shows the full registration receipt (same as Step 5 Success from registration)
  - With "بحث جديد" button at top to return to form

Error states: 
  - "لم يتم العثور علي متسابق بهذه البيانات"
  - "رقم الهاتف غير صحيح"
  - "الرقم القومي يجب أن يكون 14 رقماً"

Loading: spinner inside button while fetching

Footer hint: "في حالة نسيان البيانات، يرجى التواصل مع إدارة المسابقة"
```

### Tab 2: Result Inquiry (النتيجة)

**Checking Status (on mount)**
```
API call: GET /api/result → checks is_result_query_open setting
```

**Closed State** (if is_result_query_open = false)
```
Closed card (as described in component #9):
  - Amber top bar gradient
  - Lock icon on amber-50 square
  - Amber pulsing status pill "مغلق مؤقتاً"
  - Title "نتائج المسابقة"
  - Description "نتائج المسابقة لم تُعلن بعد..."
  - Bottom hint "تابع الصفحة الرسمية لمعرفة المواعيد"
```

**Open State — Form View**
```
Centered, max-width 480px

Header:
  - Icon square (64px, amber-50 bg, amber-500 trophy icon)
  - Title "استعلام النتيجة وبيان الدرجات" (28-32px, weight 900)
  - Description (14px, muted)

Form card:
  - National ID input (14 digits, 🪪 icon)
  - Error area
  - Submit button: amber gradient, "استعلام عن النتيجة" with search icon

Footer hint: "النتائج معتمدة من لجنة التحكيم ولا تقبل الطعون بعد إعلانها"
```

**Open State — Result View** (after successful query)
```
Action bar (top, print:hidden):
  - Left: "بحث جديد" link button (gray, hover:darkens)
  - Right: Print button (gray) + Download as image button (amber)

Result card (white, 24px radius, shadow-lg):
  - Top gradient bar (amber, 4px)
  - Body padding 40px
  
  Header (centered):
    - Trophy icon in amber-50 square (64px)
    - "وثيقة نتيجة المتسابق" title
    - "مسابقة القرآن الكريم — الموسم الأول" subtitle
  
  Student info grid (4 columns desktop, 2 tablet, 1 mobile):
    Each cell: gray-50 bg, 16px padding, 14px radius, border
      - Label (11px, muted, with icon)
      - Value (14px, weight 800)
    Fields: Name, Student Code, Level + Content, Rewaya
  
  Grade display (centered):
    - Large pill with percentage + grade label
    - Color based on result: honors (amber), pass (green), fail (red)
    Example: "🏅 96.5% — ممتاز مع مرتبة الشرف"
  
  Scores table (full width):
    Columns: المعيار | الدرجة | الدرجة القصوى | النسبة
    Rows (each shown if applicable):
      - الدرجة الأساسية
      - التلاوة والتجويد (if has_rewaya)
      - أحكام التجويد (if has_tajweed)
      - جمال الصوت والأداء (if has_voice)
      - تفسير ومعاني الكلمات (if has_meaning)
    Total row: bold, larger font, bg-section, border-top 2px
  
  Footer:
    - "هذه الوثيقة رسمية ومعتمدة من إدارة مسابقة القرآن الكريم"
    - "المشرف العام: أ/ مصطفى عبدالرحمن محمد سالم"

Print styles: Clean A4, no backgrounds, no shadows, full width
```

---

### Tab 3: Ceremony Inquiry (الحفل)

**Checking Status (on mount)**
```
API call: GET /api/ceremony → checks is_ceremony_query_open setting
```

**Closed State** (same pattern as result closed state)
```
Title "حفل التكريم"
Description "قسم الاستعلام عن حضور حفل التكريم غير متاح حالياً..."
```

**Open State — Form View**
```
Centered, max-width 480px

Header:
  - Icon square (64px, emerald-50 bg, emerald-500 calendar-check icon)
  - Title "استعلام حضور الحفل الختامي" (28-32px, weight 900)
  - Description (14px, muted)

Form card:
  - National ID input (14 digits, 🪪 icon)
  - Phone input (11 digits, 📱 icon) — two-factor verification
  - Error area
  - Submit button: emerald gradient, "استخراج بطاقة الدعوة"

Footer hint: "يرجى إحضار البطاقة المطبوعة أو صورة منها يوم الحفل"
```

**Open State — Ceremony Ticket View** (after successful query)
```
Action bar (top):
  - Left: "بحث جديد" link button
  - Right: Print + Download buttons (shown only if eligible)

Ticket card (white, shadow-lg):
  - Top gradient bar (emerald, 4px)
  - Body padding 40px
  
  Header (centered):
    - Calendar-check icon in emerald-50 square
    - "بطاقة دعوة حفل التكريم" title
    - "مسابقة القرآن الكريم" subtitle
  
  Profile photo (if available):
    - 80px circle, 3px emerald border, centered
    - Fallback: gold gradient circle with initial letter
  
  Student info grid:
    Fields: Name, Level, Ceremony Code, Gender
  
  Eligibility status (centered):
    If eligible:
      - Green pill "🎉 مؤهل للحضور — مبروك!"
      - "يسرنا دعوتكم لحضور حفل التكريم الختامي"
    If NOT eligible:
      - Red pill "غير مؤهل للحضور"
      - Explains why
  
  Congratulations message (only if eligible):
    - Gray-50 bg, 20px padding, rounded, centered
    - "تهانينا القلبية! لقد اجتزت اختبارات المسابقة بتفوق..."
  
  Supervisor info (centered, border-top):
    - "المشرف العام على المسابقة"
    - "أ/ مصطفى عبدالرحمن محمد سالم"
    - Address details
  
  Footer hint:
    - Map pin icon + "يرجى إحضار هذه البطاقة يوم الحفل"
```

---

## States for ALL Pages

### Loading States
```
Design: Centered spinner + "جاري التحميل..." text
Placement: Full page center or inline (in button)
Color: Navy spinner on white/light bg, gold spinner on dark bg
Size: 24-32px
```

### Error States
```
Design: Red background (#FEF2F2), red border (#FECACA), red text (#DC2626)
Content: Error message centered, font 12px weight 700
Placement: Below the relevant input or at top of form
With retry button when applicable
```

### Empty States
```
Design: Centered card with icon, title, description
Icon: 64px, gray-100 bg, gray-400 icon
Title: "لا توجد بيانات" or contextual
Description: Helpful message guiding user
Action button (optional): "العودة" or "تحديث"
```

### Not Found (404)
```
Centered page:
  - Large "404" text (gold, 80px+, weight 900)
  - "الصفحة غير موجودة" title
  - "الصفحة التي تبحث عنها غير موجودة أو تم نقلها" description
  - "العودة للرئيسية" button (primary)
```

### Success States
```
Toast notification (react-hot-toast):
  - Top-right (RTL), emerald bg, white text
  - Auto-dismiss after 3 seconds
  - Checkmark icon + message
```

---

## Responsive Breakpoints

```
Mobile:     < 640px
Tablet:     640px - 1024px
Desktop:    > 1024px

Mobile adjustments:
  - Single column grids
  - Reduced padding (20px → 16px)
  - Smaller fonts (hero: 26px, titles: 20px)
  - Tabs: icons + short labels only
  - Stepper: hide labels, reduce connector width
  - Cards: reduced padding (20px)
  - Header: hamburger menu instead of nav links
  - Footer: single column, centered text
  - Form cards: full width, reduced padding

Tablet adjustments:
  - 2-column grids where possible
  - Medium padding
  - Full labels in tabs
  - Stepper shows labels
```

---

## Animations & Micro-interactions

```
Page load: fade-in (opacity + translateY 10px → 0, 400ms)
Stagger items: each card delays 100ms more
Hover cards: lift -2px to -4px, shadow increases, 300ms ease
Hover buttons: lift -1px, 200ms ease
Focus inputs: border color transition + glow ring, 200ms ease
Tab switch: tab pill slides, 200ms ease
Stepper progress: step fills from gray to gold/green, 300ms
Closed state pulse: dot opacity animation 1.5s infinite
Spinner: continuous rotate 700ms linear
Dropdown: slide down + fade, 180ms ease-out

Reduced motion: All animations disabled when user prefers-reduced-motion
```

---

## Accessibility Requirements

```
- All interactive elements have focus states (visible focus rings)
- ARIA labels on icon-only buttons
- Semantic HTML (header, nav, main, footer, section)
- Sufficient color contrast (WCAG AA minimum)
- Keyboard navigation for all forms and tabs
- RTL support with dir="rtl"
- Form labels properly associated with inputs
- Error messages linked to inputs via aria-describedby
- Skip-to-content link
- Alt text on all images
```

---

## Print Styles

```
When printing (result card, ceremony ticket, application form):
  - White background
  - No shadows
  - No rounded corners
  - Full width (100%)
  - Black text
  - Hide navigation, buttons, footer
  - Page breaks where appropriate
  - A4 size
  - margin: 0
```

---

## Technical Notes

```
Framework: Next.js 16 (App Router)
Styling: Tailwind CSS 4 (utility-first) + CSS custom properties
Font: Cairo via next/font/google (variable weight)
Icons: Lucide React
Animations: Framer Motion (complex), CSS animations (simple)
Toast: react-hot-toast
CAPTCHA: Cloudflare Turnstile
Image export: html2canvas-pro
Tour guide: react-joyride
Database: Supabase (PostgreSQL)

All text is Arabic (RTL)
Numbers are Arabic-Indic (١٢٣) where culturally appropriate
Dates in Arabic format
```

---

## Complete User Flows

### Flow 1: Registration
```
Homepage → Click "سجل الآن" → Register page
→ Step 1: Enter personal data → Next
→ Step 2: Upload documents → Next
→ Step 3: Select level → Next
→ Step 4: Review + CAPTCHA + Accept terms → Submit
→ Step 5: View receipt + download/print
```

### Flow 2: Result Inquiry
```
Homepage → Click "استعلم عن نتيجتك" → Status page (Result tab)
→ If closed: See closed state card
→ If open: Enter national ID → Submit
→ If found: View full result card with scores, grade, download/print
→ If not found: See error message
```

### Flow 3: Ceremony Inquiry
```
Status page → Ceremony tab
→ If closed: See closed state card
→ If open: Enter national ID + phone → Submit
→ If eligible: View invitation ticket with code, download/print
→ If not eligible: See explanation
→ If not found: See error message
```

### Flow 4: Form Inquiry
```
Status page → Form tab
→ Enter national ID + phone → Submit
→ View application receipt with exam schedule
→ Download or print if needed
```

### Flow 5: Browse Levels
```
Homepage → Click "المستويات والجوائز" → Levels page
→ Browse all active levels with prizes
→ Click "سجل الآن" on a level → Registration page (pre-filled level)
```
