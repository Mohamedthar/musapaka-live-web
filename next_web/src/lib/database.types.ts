export interface CompetitionLevel {
  id?: number;
  title: string;
  content: string;
  is_active: boolean;
  level_code: string | null;
  min_age?: number | null;
  max_age?: number | null;
  max_capacity?: number | null;
  has_rewaya?: boolean | null;
  notes?: string | null;
  rewaya_max_score?: number | null;
  available_rewayas?: string[] | null;
  has_tajweed?: boolean | null;
  tajweed_max_score?: number | null;
  has_voice?: boolean | null;
  voice_max_score?: number | null;
  has_meaning?: boolean | null;
  meaning_max_score?: number | null;
  total_points?: number | null;
  branches?: string[] | null;
  require_custom_amount?: boolean | null;
  first_prize?: string | null;
  second_prize?: string | null;
  third_prize?: string | null;
  prizes?: string | null;
}

export interface StudentStatus {
  name: string;
  phone?: string;
  national_id?: string;
  age?: number;
  gender?: string;
  memorizer_name?: string;
  memorizer_phone?: string;
  memorizer_address?: string;
  level: string;
  level_id?: number;
  level_content?: string;
  location?: string;
  student_code?: string;
  profile_image_url?: string;
  exam_date?: string;
  exam_hour?: number;
  selected_rewaya?: string | null;
  branch_name?: string | null;
  memorization_amount?: number | null;
  registration_ip?: string;
  created_at?: string;
  level_has_rewaya?: boolean;
  level_rewaya_max_score?: number;
  level_has_tajweed?: boolean;
  level_tajweed_max_score?: number;
  level_has_voice?: boolean;
  level_voice_max_score?: number;
  level_has_meaning?: boolean;
  level_meaning_max_score?: number;
  level_total_points?: number;
}

export interface ExamScheduleSlot {
  date: string;
  start_hour: number;
  end_hour: number;
  students_per_hour: number;
}

export interface AppSettings {
  is_registration_open: boolean | null;
  registration_start_date: string | null;
  registration_end_date: string | null;
  exam_schedule: ExamScheduleSlot[] | null;
  faqs: { q: string; a: string }[] | null;
}

export interface RegistrationFormData {
  name: string;
  phone: string;
  nationalId: string;
  age: string;
  memorizerName: string;
  memorizerPhone: string;
  memorizerAddress: string;
  location: string;
  gender: string;
  level: string;
  selectedRewaya: string;
}
