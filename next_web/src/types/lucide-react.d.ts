declare module 'lucide-react' {
  import { FC, SVGProps } from 'react';
  interface LucideProps extends SVGProps<SVGSVGElement> {
    size?: number | string;
  }
  export type Icon = FC<LucideProps>;
  export const AlertTriangle: Icon;
  export const ArrowLeft: Icon;
  export const ArrowRight: Icon;
  export const Award: Icon;
  export const BarChart3: Icon;
  export const BookOpen: Icon;
  export const Calendar: Icon;
  export const CalendarCheck: Icon;
  export const CalendarX: Icon;
  export const Camera: Icon;
  export const CheckCircle2: Icon;
  export const ChevronDown: Icon;
  export const ChevronLeft: Icon;
  export const ChevronRight: Icon;
  export const Clock: Icon;
  export const CreditCard: Icon;
  export const Download: Icon;
  export const FileImage: Icon;
  export const FilePen: Icon;
  export const FileText: Icon;
  export const Hash: Icon;
  export const HelpCircle: Icon;
  export const Layers: Icon;
  export const List: Icon;
  export const Lock: Icon;
  export const MapPin: Icon;
  export const Menu: Icon;
  export const Phone: Icon;
  export const Printer: Icon;
  export const Search: Icon;
  export const Send: Icon;
  export const ShieldCheck: Icon;
  export const Sparkles: Icon;
  export const Trophy: Icon;
  export const User: Icon;
  export const UserCircle: Icon;
  export const UserCheck: Icon;
  export const UserPlus: Icon;
  export const Users: Icon;
  export const X: Icon;
}
