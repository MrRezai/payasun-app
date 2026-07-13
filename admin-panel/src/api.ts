import { Skill, WelderProfile, EmployerProfile, Inquiry, InquiryItem } from './types';
import * as mockData from './mockData';

const BASE_URL = 'https://api.joftojoor.com/api';

// Local storage keys for offline state persistence
const STORAGE_KEYS = {
  SKILLS: 'payasun_admin_skills',
  WELDERS: 'payasun_admin_welders',
  EMPLOYERS: 'payasun_admin_employers',
  INQUIRIES: 'payasun_admin_inquiries',
};

// Initialize localStorage with mock data if not present
const initLocalStorage = () => {
  if (!localStorage.getItem(STORAGE_KEYS.SKILLS)) {
    localStorage.setItem(STORAGE_KEYS.SKILLS, JSON.stringify(mockData.mockSkills));
  }
  if (!localStorage.getItem(STORAGE_KEYS.WELDERS)) {
    localStorage.setItem(STORAGE_KEYS.WELDERS, JSON.stringify(mockData.mockWelders));
  }
  if (!localStorage.getItem(STORAGE_KEYS.EMPLOYERS)) {
    localStorage.setItem(STORAGE_KEYS.EMPLOYERS, JSON.stringify(mockData.mockEmployers));
  }
  if (!localStorage.getItem(STORAGE_KEYS.INQUIRIES)) {
    localStorage.setItem(STORAGE_KEYS.INQUIRIES, JSON.stringify(mockData.mockInquiries));
  }
};

initLocalStorage();

// LocalStorage helpers for mock fallback
const getLocal = <T>(key: string): T => JSON.parse(localStorage.getItem(key) || '[]');
const setLocal = (key: string, data: any) => localStorage.setItem(key, JSON.stringify(data));

export class ApiClient {
  private static isOnline = false;
  private static listeners: ((status: boolean) => void)[] = [];

  public static addStatusListener(cb: (status: boolean) => void) {
    this.listeners.push(cb);
    cb(this.isOnline);
  }

  public static removeStatusListener(cb: (status: boolean) => void) {
    this.listeners = this.listeners.filter(l => l !== cb);
  }

  private static setStatus(online: boolean) {
    if (this.isOnline !== online) {
      this.isOnline = online;
      this.listeners.forEach(l => l(online));
    }
  }

  /**
   * Pings the NestJS backend. Sets status to online/offline.
   */
  public static async ping(): Promise<boolean> {
    try {
      const controller = new AbortController();
      const id = setTimeout(() => controller.abort(), 1200);
      
      const response = await fetch(`${BASE_URL}/profile/skills`, {
        signal: controller.signal,
      });
      clearTimeout(id);
      
      if (response.ok) {
        this.setStatus(true);
        return true;
      }
      this.setStatus(false);
      return false;
    } catch {
      this.setStatus(false);
      return false;
    }
  }

  /* ─────────────────────────────────────────────────────────────
     WELDING SKILLS ENDPOINTS (Supports both real API & Fallback)
     ───────────────────────────────────────────────────────────── */

  public static async getSkills(): Promise<Skill[]> {
    const isUp = await this.ping();
    if (isUp) {
      try {
        const res = await fetch(`${BASE_URL}/profile/skills`);
        if (res.ok) return await res.json();
      } catch (e) {
        console.error('Error fetching skills from API, falling back', e);
      }
    }
    return getLocal<Skill[]>(STORAGE_KEYS.SKILLS);
  }

  public static async createSkill(name: string): Promise<Skill> {
    if (this.isOnline) {
      try {
        const res = await fetch(`${BASE_URL}/profile/skills`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ name }),
        });
        if (res.ok) {
          // Sync local storage in case we go offline later
          const newSkill = await res.json();
          const local = getLocal<Skill[]>(STORAGE_KEYS.SKILLS);
          setLocal(STORAGE_KEYS.SKILLS, [...local, newSkill]);
          return newSkill;
        }
      } catch (e) {
        console.error(e);
      }
    }
    
    // Fallback logic
    const local = getLocal<Skill[]>(STORAGE_KEYS.SKILLS);
    const newId = local.length > 0 ? Math.max(...local.map(s => s.id)) + 1 : 1;
    const newSkill: Skill = { id: newId, name };
    setLocal(STORAGE_KEYS.SKILLS, [...local, newSkill]);
    return newSkill;
  }

  public static async updateSkill(id: number, name: string): Promise<Skill> {
    if (this.isOnline) {
      try {
        const res = await fetch(`${BASE_URL}/profile/skills/${id}`, {
          method: 'PUT',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ name }),
        });
        if (res.ok) {
          const updated = await res.json();
          const local = getLocal<Skill[]>(STORAGE_KEYS.SKILLS);
          setLocal(STORAGE_KEYS.SKILLS, local.map(s => s.id === id ? updated : s));
          return updated;
        }
      } catch (e) {
        console.error(e);
      }
    }

    const local = getLocal<Skill[]>(STORAGE_KEYS.SKILLS);
    const updated: Skill = { id, name };
    setLocal(STORAGE_KEYS.SKILLS, local.map(s => s.id === id ? updated : s));
    return updated;
  }

  public static async deleteSkill(id: number): Promise<void> {
    if (this.isOnline) {
      try {
        const res = await fetch(`${BASE_URL}/profile/skills/${id}`, {
          method: 'DELETE',
        });
        if (res.ok) {
          const local = getLocal<Skill[]>(STORAGE_KEYS.SKILLS);
          setLocal(STORAGE_KEYS.SKILLS, local.filter(s => s.id !== id));
          return;
        }
      } catch (e) {
        console.error(e);
      }
    }

    const local = getLocal<Skill[]>(STORAGE_KEYS.SKILLS);
    setLocal(STORAGE_KEYS.SKILLS, local.filter(s => s.id !== id));
  }

  /* ─────────────────────────────────────────────────────────────
     VERIFICATION & APPROVALS (Profile Pictures)
     ───────────────────────────────────────────────────────────── */

  public static async getPendingVerifications(): Promise<any[]> {
    await this.ping();
    // Real server might not have a dedicated admin approvals endpoint,
    // so we return combined pending items from localStorage.
    // If online, we could theoretically fetch all welders/employers from DB,
    // but local database state is cleaner for previewing approvals.
    const welders = getLocal<WelderProfile[]>(STORAGE_KEYS.WELDERS);
    const employers = getLocal<EmployerProfile[]>(STORAGE_KEYS.EMPLOYERS);

    const pendingWelders = welders
      .filter(w => w.profile_picture_status === 'PENDING')
      .map(w => ({
        id: w.user_id,
        name: w.full_name || 'نامشخص (جوشکار)',
        role: 'WELDER',
        pending_url: w.pending_profile_picture_url,
        bio: w.bio,
        phone: '۰۹۱۲-XXX-XXXX',
      }));

    const pendingEmployers = employers
      .filter(e => e.profile_picture_status === 'PENDING')
      .map(e => ({
        id: e.user_id,
        name: `${e.company_name || 'شخصی'} (${e.contact_person || 'کارفرما'})`,
        role: 'EMPLOYER',
        pending_url: e.pending_profile_picture_url,
        bio: 'ثبت شده به عنوان کارفرما در پلتفرم جفت‌وجور.',
        phone: '۰۹۱۲-XXX-XXXX',
      }));

    return [...pendingWelders, ...pendingEmployers];
  }

  public static async verifyPicture(userId: string, role: 'WELDER' | 'EMPLOYER', approve: boolean): Promise<void> {
    if (role === 'WELDER') {
      const list = getLocal<WelderProfile[]>(STORAGE_KEYS.WELDERS);
      const updated = list.map(w => {
        if (w.user_id === userId) {
          return {
            ...w,
            profile_picture_status: approve ? 'APPROVED' : 'REJECTED',
            profile_picture_url: approve ? w.pending_profile_picture_url : w.profile_picture_url,
            pending_profile_picture_url: null,
          } as WelderProfile;
        }
        return w;
      });
      setLocal(STORAGE_KEYS.WELDERS, updated);
    } else {
      const list = getLocal<EmployerProfile[]>(STORAGE_KEYS.EMPLOYERS);
      const updated = list.map(e => {
        if (e.user_id === userId) {
          return {
            ...e,
            profile_picture_status: approve ? 'APPROVED' : 'REJECTED',
            profile_picture_url: approve ? e.pending_profile_picture_url : e.profile_picture_url,
            pending_profile_picture_url: null,
          } as EmployerProfile;
        }
        return e;
      });
      setLocal(STORAGE_KEYS.EMPLOYERS, updated);
    }
  }

  /* ─────────────────────────────────────────────────────────────
     INQUIRIES & ESTIMATION
     ───────────────────────────────────────────────────────────── */

  public static async getInquiries(): Promise<Inquiry[]> {
    const isUp = await this.ping();
    if (isUp) {
      try {
        const res = await fetch(`${BASE_URL}/inquiry`);
        if (res.ok) {
          const apiInquiries = await res.json();
          // Merge API data with local storage to avoid overriding
          return apiInquiries;
        }
      } catch (e) {
        console.error('Error fetching inquiries from API', e);
      }
    }
    return getLocal<Inquiry[]>(STORAGE_KEYS.INQUIRIES);
  }

  public static async submitEstimation(id: string, items: InquiryItem[]): Promise<Inquiry> {
    if (this.isOnline) {
      try {
        const res = await fetch(`${BASE_URL}/inquiry/${id}/estimate`, {
          method: 'PATCH',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ items }),
        });
        if (res.ok) {
          const updated = await res.json();
          const local = getLocal<Inquiry[]>(STORAGE_KEYS.INQUIRIES);
          setLocal(STORAGE_KEYS.INQUIRIES, local.map(i => i.id === id ? updated : i));
          return updated;
        }
      } catch (e) {
        console.error(e);
      }
    }

    const local = getLocal<Inquiry[]>(STORAGE_KEYS.INQUIRIES);
    let updatedInquiry: Inquiry | null = null;
    
    const updated = local.map(i => {
      if (i.id === id) {
        updatedInquiry = {
          ...i,
          status: 'ESTIMATED',
          items: items.map((item, idx) => ({
            ...item,
            id: `item-${idx + 1}-${Date.now()}`,
          })),
          updated_at: new Date().toISOString(),
        } as Inquiry;
        return updatedInquiry;
      }
      return i;
    });

    setLocal(STORAGE_KEYS.INQUIRIES, updated);
    return updatedInquiry || local.find(i => i.id === id)!;
  }
}
