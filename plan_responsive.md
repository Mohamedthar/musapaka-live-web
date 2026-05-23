# خطة جعل التطبيق متجاوب (Responsive) للموبايل والديسكتوب

## الأهداف
- دعم 3 أحجام شاشة: **موبايل (<600px)**، **تابلت (600–900px)**، **ديسكتوب (>900px)**
- جميع عمليات CRUD تعمل على الموبايل (حالياً مخفية)
- لا إضافة مكتبات حساسة — نبقى على `setState` و `Navigator 1.0`

---

## Phase 1: بنية تحتية — ملفان جديدان

### 1.1 `lib/core/constants/breakpoints.dart`
```dart
class Breakpoints {
  static const double mobile = 600;
  static const double tablet = 900;
  static const double desktop = 1200;
}
```

### 1.2 `lib/core/utils/responsive.dart`
- `ScreenType` enum: `mobile`, `tablet`, `desktop`
- `ResponsiveUtils` class:
  - `fromWidth(width)` → ScreenType
  - `isMobile(context)`, `isTablet(context)`, `isDesktop(context)`
  - `padding(type)` → EdgeInsets متجاوب

---

## Phase 2: إصلاحات سريعة — 6 ملفات

| الملف | المشكلة | الإصلاح |
|-------|---------|---------|
| `confirm_dialog.dart` | `width: 400` ثابت | `constraints: BoxConstraints(maxWidth: 420)` |
| `levels_screen.dart` | `width: 480` في تصدير Excel/PDF | `constraints: BoxConstraints(maxWidth: 500)` |
| `stats_cards.dart` | `>600 ? 2 : 2` دائمًا عمودين | `>1000 ? 4 : (>600 ? 2 : 1)` |
| `levels_stats_cards.dart` | نفس المشكلة | `>900 ? 4 : (>600 ? 2 : 1)` |
| `admin_login_screen.dart` | padding `48` أفقي كبير | `isWide ? 48 : 20` |
| `create_admin_screen.dart` | نفس المشكلة | نفس الإصلاح |

---

## Phase 3: لوحات جانبية للموبايل (CRITICAL) — 5 ملفات

### 3.1 إضافة خاصية `width?` اختيارية للوحات:
- `detail_panel.dart` ← `Container(width: widget.width ?? 400)`
- `edit_panel.dart` ← نفس الشيء
- `add_student_panel.dart` ← نفس الشيء
- `levels_side_panel.dart` ← نفس الشيء

### 3.2 عرض اللوحات كـ Bottom Sheets على الموبايل:
- `dashboard_screen.dart`: دوال `_showDetailBottomSheet()` و `_showEditBottomSheet()` تستخدم `showModalBottomSheet` + `DraggableScrollableSheet`
- `levels_screen.dart`: دالة `_showLevelsBottomSheet()`
- يتم استدعاؤها فقط عندما `ResponsiveUtils.isMobile(context)`

---

## Phase 4: Navigation للموبايل — ملف واحد

### `dashboard_screen.dart` — إعادة هيكلة الـ `build()`:

```
ديسكتوب (>900):
  Row [Sidebar (250px) | Expanded → _buildDashboardContent()]
  بدون BottomNav

موبايل/تابلت (<=900):
  Column [
    Expanded → IndexedStack [0: dashboard, 1: levels]
    NavigationBar (ثابت في الأسفل)
  ]
  Drawer [DashboardSidebar] (للوصول للـ Logout)
  FloatingActionButton (لإضافة طالب)
```

### تابلت — اختياري:
- `NavigationRail` على اليسار + `IndexedStack` للمحتوى

---

## Phase 5: جداول كـ Card List للموبايل — ملفان

### `student_table.dart`
- إضافة `ScreenType screenType` كـ parameter
- إذا موبايل: `_buildMobileCards()` باستخدام `ListView.builder` + `Card`
- كل كارد يظهر: الصورة، الاسم، رقم الهاتف، الحالة، المستوى، العمر، الدرجة، أزرار سريعة (قبول/رفض)

### `levels_table.dart`
- نفس المبدأ: كارد لكل مستوى
- يظهر: العنوان، الحالة (نشط/معطل)، المحتوى، السعة، العمر، شريط تقدم الامتلاء

---

## Phase 6: تمرير `ScreenType` عبر الشجرة

- `levels_screen.dart` يستقبل `ScreenType` ويوزعه على `LevelsTable` و `LevelsSidePanel`
- `dashboard_screen.dart` يمرر `screenType` إلى `StudentTable`, `DashboardTopBar`, إلخ

---

## ترتيب التنفيذ

| # | الملفات | الجهد | التأثير |
|---|---------|-------|---------|
| 1 | `breakpoints.dart` + `responsive.dart` | 10 د | بنية تحتية |
| 2 | `confirm_dialog.dart` | 5 د | إصلاح كسر في الموبايل |
| 3 | `stats_cards.dart` + `levels_stats_cards.dart` | 5 د | تحسين الإحصائيات |
| 4 | `admin_login_screen.dart` + `create_admin_screen.dart` | 5 د | تحسين نماذج الدخول |
| 5 | `levels_screen.dart` (تصدير) | 5 د | إصلاح كسر في التصدير |
| 6 | الـ 4 panel files (إضافة `width`) | 20 د | تمكين الـ Bottom Sheets |
| 7 | `dashboard_screen.dart` (Bottom sheets) | 45 د | **CRITICAL: CRUD موبايل** |
| 8 | `levels_screen.dart` (Bottom sheet) | 20 د | **CRITICAL: CRUD موبايل** |
| 9 | `dashboard_screen.dart` (Bottom Nav) | 30 د | تجربة تنقل موبايل |
| 10 | `student_table.dart` (Card list) | 40 د | تصفح بيانات موبايل |
| 11 | `levels_table.dart` (Card list) | 30 د | تصفح بيانات موبايل |
| 12 | تمرير `ScreenType` عبر الشجرة | 15 د | تكامل نهائي |

---

## التحقق (Testing)

### يدوي — 3 أحجام شاشة:
1. **360px (موبايل):**
   - NavigationBar في الأسفل
   - الإحصائيات في عمود واحد
   - ضغط على طالب → Bottom Sheet
   - تعديل طالب → Bottom Sheet كامل
   - إضافة طالب → FAB → شاشة تسجيل
   - تصدير/حذف → Dialog مناسب
   - تبويب المستويات → كاردات، ضغط → Bottom Sheet

2. **768px (تابلت):**
   - NavigationRail جانبي
   - الإحصائيات في عمودين
   - الجداول مع scroll أفقي أو كاردات

3. **1920px (ديسكتوب):**
   - لا تغيير — كل شيء يعمل كما كان
   - اللوحات الجانبية 400px
   - الـ Sidebar ظاهر

### أتمتة:
- `flutter analyze` — لا أخطاء
- `flutter test` — 35/35 يمر
