import { Skill, Inquiry, InquiryItem } from './types';

export const BASE_URL = 'https://api.joftojoor.com';

export class ApiClient {
  private static isOnline = false;
  private static listeners: ((status: boolean) => void)[] = [];
  private static token: string | null = localStorage.getItem('payasun_admin_token');

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

  // Token management
  public static setToken(token: string | null) {
    this.token = token;
    if (token) {
      localStorage.setItem('payasun_admin_token', token);
    } else {
      localStorage.removeItem('payasun_admin_token');
    }
  }

  public static getToken(): string | null {
    return this.token;
  }

  public static isAuthenticated(): boolean {
    return this.token !== null && this.token.length > 0;
  }

  private static getHeaders(extraHeaders: Record<string, string> = {}): Record<string, string> {
    const headers: Record<string, string> = { ...extraHeaders };
    if (this.token) {
      headers['Authorization'] = `Bearer ${this.token}`;
    }
    return headers;
  }

  private static async request(url: string, init?: RequestInit): Promise<Response> {
    try {
      const res = await fetch(url, {
        ...init,
        headers: this.getHeaders(init?.headers as Record<string, string>),
      });
      if (res.status === 401) {
        this.setToken(null);
        throw new Error('UNAUTHORIZED');
      }
      return res;
    } catch (err: any) {
      if (err.message === 'UNAUTHORIZED') {
        throw err;
      }
      throw new Error('خطا در برقراری ارتباط با سرور.');
    }
  }

  /**
   * Pings the NestJS backend admin endpoint. Sets status to online/offline.
   */
  public static async ping(): Promise<boolean> {
    try {
      const controller = new AbortController();
      const id = setTimeout(() => controller.abort(), 1200);
      
      const response = await fetch(`${BASE_URL}/admin/skills`, {
        signal: controller.signal,
        headers: this.getHeaders(),
      });
      clearTimeout(id);
      
      if (response.status === 200 || response.status === 401) {
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
     ADMIN AUTHENTICATION (Checks credentials from admin-panel env)
     ───────────────────────────────────────────────────────────── */

  public static async verifyAdminLogin(username: string, password: string): Promise<string> {
    const expectedUser = (import.meta as any).env.VITE_ADMIN_USERNAME || 'admin';
    const expectedPass = (import.meta as any).env.VITE_ADMIN_PASSWORD || 'adminpassword';

    if (username === expectedUser && password === expectedPass) {
      const token = 'payasun_admin_secret_token_12345';
      this.setToken(token);
      await this.ping();
      return token;
    } else {
      throw new Error('نام کاربری یا رمز عبور ادمین نادرست است.');
    }
  }

  /* ─────────────────────────────────────────────────────────────
     METRICS COUNTS ENDPOINTS
     ───────────────────────────────────────────────────────────── */

  public static async getWeldersCount(): Promise<number> {
    const res = await this.request(`${BASE_URL}/admin/welders-count`);
    if (!res.ok) throw new Error('خطا در دریافت آمار جوشکاران.');
    const data = await res.json();
    return data.count;
  }

  public static async getEmployersCount(): Promise<number> {
    const res = await this.request(`${BASE_URL}/admin/employers-count`);
    if (!res.ok) throw new Error('خطا در دریافت آمار کارفرمایان.');
    const data = await res.json();
    return data.count;
  }

  /* ─────────────────────────────────────────────────────────────
     WELDING SKILLS ENDPOINTS
     ───────────────────────────────────────────────────────────── */

  public static async getSkills(): Promise<Skill[]> {
    const res = await this.request(`${BASE_URL}/admin/skills`);
    if (!res.ok) throw new Error('خطا در دریافت لیست تخصص‌ها.');
    return await res.json();
  }

  public static async createSkill(name: string): Promise<Skill> {
    const res = await this.request(`${BASE_URL}/admin/skills`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ name }),
    });
    if (!res.ok) throw new Error('خطا در افزودن تخصص جدید.');
    return await res.json();
  }

  public static async updateSkill(id: number, name: string): Promise<Skill> {
    const res = await this.request(`${BASE_URL}/admin/skills/${id}`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ name }),
    });
    if (!res.ok) throw new Error('خطا در ویرایش تخصص.');
    return await res.json();
  }

  public static async deleteSkill(id: number): Promise<void> {
    const res = await this.request(`${BASE_URL}/admin/skills/${id}`, {
      method: 'DELETE',
    });
    if (!res.ok) throw new Error('خطا در حذف تخصص.');
  }

  /* ─────────────────────────────────────────────────────────────
     VERIFICATION & APPROVALS (Profile Pictures)
     ───────────────────────────────────────────────────────────── */

  public static async getPendingVerifications(): Promise<any[]> {
    const res = await this.request(`${BASE_URL}/admin/pending-verifications`);
    if (!res.ok) throw new Error('خطا در دریافت تصاویر معلق تایید.');
    return await res.json();
  }

  public static async verifyPicture(userId: string, role: 'WELDER' | 'EMPLOYER', approve: boolean): Promise<void> {
    const res = await this.request(`${BASE_URL}/admin/verify-picture/${userId}`, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ role, approve }),
    });
    if (!res.ok) throw new Error('خطا در ثبت وضعیت بررسی تصویر.');
  }

  /* ─────────────────────────────────────────────────────────────
     INQUIRIES & ESTIMATION
     ───────────────────────────────────────────────────────────── */

  public static async getInquiries(): Promise<Inquiry[]> {
    const res = await this.request(`${BASE_URL}/admin/inquiries`);
    if (!res.ok) throw new Error('خطا در دریافت لیست استعلام‌ها.');
    return await res.json();
  }

  public static async submitEstimation(id: string, items: InquiryItem[]): Promise<Inquiry> {
    const res = await this.request(`${BASE_URL}/admin/inquiry/${id}/estimate`, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ items }),
    });
    if (!res.ok) throw new Error('خطا در ثبت برآورد مالی.');
    return await res.json();
  }

  /* ─────────────────────────────────────────────────────────────
     USERS LIST ENDPOINT
     ───────────────────────────────────────────────────────────── */

  public static async getUsers(): Promise<any[]> {
    const res = await this.request(`${BASE_URL}/admin/users`);
    if (!res.ok) throw new Error('خطا در دریافت لیست کاربران.');
    return await res.json();
  }
}
