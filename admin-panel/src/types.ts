export type UserRole = 'EMPLOYER' | 'WELDER';

export type ProfilePictureStatus = 'PENDING' | 'APPROVED' | 'REJECTED' | 'NONE';

export type InquiryStatus = 'PENDING_ESTIMATION' | 'ESTIMATED' | 'BROADCASTED' | 'CLOSED' | 'EXPIRED' | 'REJECTED';

export interface Skill {
  id: number;
  name: string;
  created_at?: string;
  updated_at?: string;
}

export interface User {
  id: string;
  phoneNumber: string;
  role: UserRole;
  created_at: string;
}

export interface WelderProfile {
  id: number;
  user_id: string;
  full_name: string | null;
  home_city: string | null;
  active_cities: string[];
  bio: string | null;
  profile_picture_url: string | null;
  pending_profile_picture_url: string | null;
  profile_picture_status: ProfilePictureStatus;
  is_setup_completed: boolean;
  base_price_list: any[];
  skills: Skill[];
}

export interface EmployerProfile {
  id: number;
  user_id: string;
  company_name: string | null;
  contact_person: string | null;
  profile_picture_url: string | null;
  pending_profile_picture_url: string | null;
  profile_picture_status: ProfilePictureStatus;
  is_setup_completed: boolean;
}

export interface InquiryItem {
  id?: string;
  title: string;
  unit: string;
  quantity: number;
  price?: number;
}

export interface Inquiry {
  id: string;
  employer_id: string;
  title: string;
  description: string;
  province: string;
  city: string;
  has_blueprint: boolean;
  blueprint_url: string | null;
  status: InquiryStatus;
  rejection_reason?: string | null;
  items: InquiryItem[];
  created_at: string;
  updated_at: string;
  employer_name?: string; // hydrated/joined UI fields
  employer_phone?: string;
}
