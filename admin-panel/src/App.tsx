import React, { useState, useEffect } from 'react';
import { ApiClient } from './api';
import { Skill, Inquiry, InquiryItem } from './types';

// Simple toast notifications type
interface Toast {
  id: number;
  message: string;
  type: 'success' | 'warning';
}

export default function App() {
  const [activeTab, setActiveTab] = useState<'overview' | 'approvals' | 'estimations' | 'skills' | 'settings'>('overview');
  const [isOnline, setIsOnline] = useState(false);
  const [toasts, setToasts] = useState<Toast[]>([]);
  
  // Data lists
  const [skills, setSkills] = useState<Skill[]>([]);
  const [pendingVerifications, setPendingVerifications] = useState<any[]>([]);
  const [inquiries, setInquiries] = useState<Inquiry[]>([]);
  
  // Modals & Selected states
  const [selectedVerification, setSelectedVerification] = useState<any | null>(null);
  const [selectedInquiry, setSelectedInquiry] = useState<Inquiry | null>(null);
  const [estimationItems, setEstimationItems] = useState<InquiryItem[]>([
    { title: '', unit: 'متر', quantity: 1, price: 0 }
  ]);
  
  // Skill form state
  const [newSkillName, setNewSkillName] = useState('');
  const [editingSkillId, setEditingSkillId] = useState<number | null>(null);
  const [editingSkillName, setEditingSkillName] = useState('');
  
  // Server settings mock config
  const [dbHost, setDbHost] = useState('localhost');
  const [dbPort, setDbPort] = useState('5432');
  const [dbName, setDbName] = useState('joftojoor_db');

  // Trigger Toast helper
  const showToast = (message: string, type: 'success' | 'warning' = 'success') => {
    const id = Date.now();
    setToasts(prev => [...prev, { id, message, type }]);
    setTimeout(() => {
      setToasts(prev => prev.filter(t => t.id !== id));
    }, 4000);
  };

  // Status and data sync
  useEffect(() => {
    const handleStatusChange = (status: boolean) => {
      setIsOnline(status);
      if (status) {
        showToast('اتصال به سرور NestJS برقرار شد.', 'success');
      } else {
        showToast('سرور متصل نیست. حالت شبیه‌ساز محلی فعال شد.', 'warning');
      }
    };
    
    ApiClient.addStatusListener(handleStatusChange);
    
    // Initial fetch
    refreshAllData();

    // Ping check every 5 seconds
    const interval = setInterval(() => {
      ApiClient.ping();
    }, 5000);

    return () => {
      ApiClient.removeStatusListener(handleStatusChange);
      clearInterval(interval);
    };
  }, []);

  const refreshAllData = async () => {
    try {
      const skillsData = await ApiClient.getSkills();
      setSkills(skillsData);
      
      const pendingData = await ApiClient.getPendingVerifications();
      setPendingVerifications(pendingData);
      
      const inquiriesData = await ApiClient.getInquiries();
      setInquiries(inquiriesData);
    } catch (e) {
      console.error('Error refreshing dashboard data', e);
    }
  };

  /* ─────────────────────────────────────────────────────────────
     VERIFICATION OPERATIONS
     ───────────────────────────────────────────────────────────── */
  const handleVerify = async (userId: string, role: 'WELDER' | 'EMPLOYER', approve: boolean) => {
    try {
      await ApiClient.verifyPicture(userId, role, approve);
      showToast(
        approve 
          ? 'تصویر کاربری با موفقیت تایید و فعال گردید.' 
          : 'تصویر کاربری رد گردید و از حالت معلق خارج شد.', 
        approve ? 'success' : 'warning'
      );
      setSelectedVerification(null);
      refreshAllData();
    } catch (e) {
      showToast('خطا در انجام احراز هویت.', 'warning');
    }
  };

  /* ─────────────────────────────────────────────────────────────
     ESTIMATION OPERATIONS
     ───────────────────────────────────────────────────────────── */
  const addEstimationRow = () => {
    setEstimationItems(prev => [...prev, { title: '', unit: 'متر', quantity: 1, price: 0 }]);
  };

  const removeEstimationRow = (index: number) => {
    if (estimationItems.length === 1) return;
    setEstimationItems(prev => prev.filter((_, i) => i !== index));
  };

  const handleEstimationRowChange = (index: number, field: keyof InquiryItem, value: any) => {
    setEstimationItems(prev => prev.map((item, i) => {
      if (i === index) {
        return { ...item, [field]: value };
      }
      return item;
    }));
  };

  const handleSubmittingEstimation = async (inqId: string) => {
    const invalid = estimationItems.some(item => !item.title || item.quantity <= 0 || !item.price || item.price <= 0);
    if (invalid) {
      showToast('لطفاً اطلاعات تمام اقلام برآورد را به درستی وارد کنید.', 'warning');
      return;
    }

    try {
      await ApiClient.submitEstimation(inqId, estimationItems);
      showToast('لیست اقلام کارشناسی با موفقیت ثبت و برای کارفرما ارسال گردید.', 'success');
      setSelectedInquiry(null);
      setEstimationItems([{ title: '', unit: 'متر', quantity: 1, price: 0 }]);
      refreshAllData();
    } catch (e) {
      showToast('خطا در ثبت برآورد پروژه.', 'warning');
    }
  };

  /* ─────────────────────────────────────────────────────────────
     SKILLS CRUD OPERATIONS
     ───────────────────────────────────────────────────────────── */
  const handleAddSkill = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newSkillName.trim()) return;
    try {
      await ApiClient.createSkill(newSkillName.trim());
      showToast('تخصص جدید با موفقیت به سیستم اضافه شد.', 'success');
      setNewSkillName('');
      refreshAllData();
    } catch (e) {
      showToast('خطا در ثبت تخصص.', 'warning');
    }
  };

  const handleStartEditSkill = (skill: Skill) => {
    setEditingSkillId(skill.id);
    setEditingSkillName(skill.name);
  };

  const handleSaveEditSkill = async (id: number) => {
    if (!editingSkillName.trim()) return;
    try {
      await ApiClient.updateSkill(id, editingSkillName.trim());
      showToast('نام تخصص با موفقیت ویرایش شد.', 'success');
      setEditingSkillId(null);
      refreshAllData();
    } catch (e) {
      showToast('خطا در ویرایش تخصص.', 'warning');
    }
  };

  const handleDeleteSkill = async (id: number) => {
    if (!window.confirm('آیا از حذف این تخصص اطمینان دارید؟ حذف این مورد ممکن است مهارت‌های ثبت شده جوشکاران را تحت تاثیر قرار دهد.')) return;
    try {
      await ApiClient.deleteSkill(id);
      showToast('تخصص مربوطه از سیستم حذف گردید.', 'warning');
      refreshAllData();
    } catch (e) {
      showToast('خطا در حذف تخصص.', 'warning');
    }
  };

  /* ─────────────────────────────────────────────────────────────
     METRICS COMPUTATIONS
     ───────────────────────────────────────────────────────────── */
  const totalWeldersCount = 4; // Mock standard
  const totalEmployersCount = 3;
  const pendingPicsCount = pendingVerifications.length;
  const pendingEstimationsCount = inquiries.filter(i => i.status === 'PENDING_ESTIMATION').length;

  return (
    <div className="app-container">
      {/* Sidebar Navigation */}
      <aside className="sidebar">
        <div className="sidebar-logo">
          <img src="/src/assets/logo/joftojoor.png" alt="جفت و جور" />
          <span>پنل مدیریت جفت‌وجور</span>
        </div>
        
        <nav className="menu-section">
          <button 
            className={`menu-item ${activeTab === 'overview' ? 'active' : ''}`}
            onClick={() => setActiveTab('overview')}
          >
            <svg fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 6a2 2 0 012-2h2a2 2 0 012 2v4a2 2 0 01-2 2H6a2 2 0 01-2-2V6zM14 6a2 2 0 012-2h2a2 2 0 012 2v4a2 2 0 01-2 2h-2a2 2 0 01-2-2V6zM4 16a2 2 0 012-2h2a2 2 0 012 2v4a2 2 0 01-2 2H6a2 2 0 01-2-2v-4zM14 16a2 2 0 012-2h2a2 2 0 012 2v4a2 2 0 01-2 2h-2a2 2 0 01-2-2v-4z" />
            </svg>
            <span>داشبورد عمومی</span>
          </button>

          <button 
            className={`menu-item ${activeTab === 'approvals' ? 'active' : ''}`}
            onClick={() => setActiveTab('approvals')}
          >
            <svg fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" />
            </svg>
            <span>تایید هویت تصاویر</span>
            {pendingPicsCount > 0 && <span style={{ marginRight: 'auto', backgroundColor: 'var(--secondary)', color: 'white', borderRadius: '50%', width: '18px', height: '18px', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '10px', fontWeight: 'bold' }}>{pendingPicsCount}</span>}
          </button>

          <button 
            className={`menu-item ${activeTab === 'estimations' ? 'active' : ''}`}
            onClick={() => setActiveTab('estimations')}
          >
            <svg fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 17v-2m3 2v-4m3 4v-6m2 10H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
            </svg>
            <span>برآورد فنی استعلام‌ها</span>
            {pendingEstimationsCount > 0 && <span style={{ marginRight: 'auto', backgroundColor: 'var(--primary)', color: 'white', borderRadius: '50%', width: '18px', height: '18px', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '10px', fontWeight: 'bold' }}>{pendingEstimationsCount}</span>}
          </button>

          <button 
            className={`menu-item ${activeTab === 'skills' ? 'active' : ''}`}
            onClick={() => setActiveTab('skills')}
          >
            <svg fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10" />
            </svg>
            <span>مدیریت تخصص‌ها</span>
          </button>

          <button 
            className={`menu-item ${activeTab === 'settings' ? 'active' : ''}`}
            onClick={() => setActiveTab('settings')}
          >
            <svg fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z" />
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
            </svg>
            <span>تنظیمات سرور</span>
          </button>
        </nav>
        
        <div style={{ marginTop: 'auto', padding: '12px', borderTop: '1px solid var(--border)', fontSize: '11px', color: 'var(--text-secondary)', textAlign: 'center' }}>
          نسخه وب ۱.۰.۰
        </div>
      </aside>

      {/* Main Content Wrapper */}
      <main className="main-wrapper">
        <header className="topbar">
          <div className="topbar-title">
            <h1>
              {activeTab === 'overview' && 'داشبورد عمومی مدیریت'}
              {activeTab === 'approvals' && 'تایید و صحت‌سنجی مدارک'}
              {activeTab === 'estimations' && 'کارشناسی و برآورد فنی اقلام'}
              {activeTab === 'skills' && 'تنظیمات تخصص‌ها و مهارت‌ها'}
              {activeTab === 'settings' && 'تنظیمات ارتباطی پایگاه داده'}
            </h1>
          </div>
          
          <div className="topbar-actions">
            {isOnline ? (
              <div className="server-badge online">
                <span className="badge-dot pulse"></span>
                <span>متصل به سرور NestJS</span>
              </div>
            ) : (
              <div className="server-badge offline">
                <span className="badge-dot"></span>
                <span>شبیه‌ساز محلی (Offline)</span>
              </div>
            )}
            
            <div className="avatar" style={{ border: '1px solid var(--border)' }}>
              <span>AD</span>
            </div>
          </div>
        </header>

        {/* TAB 1: OVERVIEW */}
        {activeTab === 'overview' && (
          <div style={{ animation: 'fadeIn 0.3s ease-out' }}>
            {/* Stats Metrics Cards */}
            <div className="grid-metrics">
              <div className="glass-card metric-card">
                <div className="metric-info">
                  <h3>جوشکاران فعال</h3>
                  <div className="value">{totalWeldersCount}</div>
                </div>
                <div className="metric-icon">
                  <svg fill="none" viewBox="0 0 24 24" stroke="currentColor" width="24" height="24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
                  </svg>
                </div>
              </div>

              <div className="glass-card metric-card">
                <div className="metric-info">
                  <h3>کارفرمایان ثبت‌شده</h3>
                  <div className="value">{totalEmployersCount}</div>
                </div>
                <div className="metric-icon success">
                  <svg fill="none" viewBox="0 0 24 24" stroke="currentColor" width="24" height="24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4" />
                  </svg>
                </div>
              </div>

              <div className="glass-card metric-card">
                <div className="metric-info">
                  <h3>تصاویر معلق تایید</h3>
                  <div className="value">{pendingPicsCount}</div>
                </div>
                <div className={`metric-icon ${pendingPicsCount > 0 ? 'warning' : ''}`}>
                  <svg fill="none" viewBox="0 0 24 24" stroke="currentColor" width="24" height="24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
                  </svg>
                </div>
              </div>

              <div className="glass-card metric-card">
                <div className="metric-info">
                  <h3>انتظار برای کارشناسی</h3>
                  <div className="value">{pendingEstimationsCount}</div>
                </div>
                <div className={`metric-icon ${pendingEstimationsCount > 0 ? 'danger' : ''}`}>
                  <svg fill="none" viewBox="0 0 24 24" stroke="currentColor" width="24" height="24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                  </svg>
                </div>
              </div>
            </div>

            {/* Visual Charts Section */}
            <div style={{ display: 'grid', gridTemplateColumns: '2fr 1fr', gap: '24px', marginBottom: '28px' }}>
              <div className="glass-card">
                <h3 style={{ fontSize: '15px', fontWeight: '700', marginBottom: '16px' }}>آمار وضعیت استعلام‌های پروژه</h3>
                <div className="chart-container">
                  <div className="chart-bar-wrapper">
                    <div className="chart-bar" style={{ height: '110px' }}></div>
                    <span className="chart-label">انتظار کارشناسی (۲)</span>
                  </div>
                  <div className="chart-bar-wrapper">
                    <div className="chart-bar" style={{ height: '55px', background: 'linear-gradient(to top, var(--secondary), rgba(245,158,11,0.3))' }}></div>
                    <span className="chart-label">برآورد شده (۱)</span>
                  </div>
                  <div className="chart-bar-wrapper">
                    <div className="chart-bar" style={{ height: '70px', background: 'linear-gradient(to top, var(--success), rgba(16,185,129,0.3))' }}></div>
                    <span className="chart-label">انتشار یافته (۱)</span>
                  </div>
                  <div className="chart-bar-wrapper">
                    <div className="chart-bar" style={{ height: '20px', background: 'rgba(255,255,255,0.1)' }}></div>
                    <span className="chart-label">بسته‌شده (۰)</span>
                  </div>
                </div>
              </div>

              <div className="glass-card" style={{ display: 'flex', flexDirection: 'column' }}>
                <h3 style={{ fontSize: '15px', fontWeight: '700', marginBottom: '16px' }}>توزیع جغرافیایی پروژه‌ها</h3>
                <div style={{ display: 'flex', flexDirection: 'column', gap: '14px', flex: 1, justifyContent: 'center' }}>
                  <div>
                    <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '12px', marginBottom: '4px' }}>
                      <span>استان تهران (۷۵٪)</span>
                      <span>۳ استعلام</span>
                    </div>
                    <div style={{ width: '100%', height: '6px', backgroundColor: 'rgba(255,255,255,0.05)', borderRadius: '3px', overflow: 'hidden' }}>
                      <div style={{ width: '75%', height: '100%', backgroundColor: 'var(--primary)' }}></div>
                    </div>
                  </div>

                  <div>
                    <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '12px', marginBottom: '4px' }}>
                      <span>استان البرز (۲۵٪)</span>
                      <span>۱ استعلام</span>
                    </div>
                    <div style={{ width: '100%', height: '6px', backgroundColor: 'rgba(255,255,255,0.05)', borderRadius: '3px', overflow: 'hidden' }}>
                      <div style={{ width: '25%', height: '100%', backgroundColor: 'var(--secondary)' }}></div>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            {/* Recent Log Activities */}
            <div className="glass-card">
              <h3 style={{ fontSize: '15px', fontWeight: '700', marginBottom: '16px' }}>گزارش رویدادهای اخیر پلتفرم</h3>
              <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
                <div style={{ display: 'flex', gap: '12px', fontSize: '13px', borderBottom: '1px solid var(--border)', paddingBottom: '12px' }}>
                  <span style={{ color: 'var(--primary)', fontWeight: 'bold' }}>۱۰:۳۰</span>
                  <span>کارفرما <strong>سازه‌گستر البرز</strong> استعلام جدیدی با عنوان <strong>«لوله‌کشی گاز رایزر ساختمان ۵ طبقه»</strong> ثبت کرد و فایل نقشه بارگذاری شد.</span>
                </div>
                <div style={{ display: 'flex', gap: '12px', fontSize: '13px', borderBottom: '1px solid var(--border)', paddingBottom: '12px' }}>
                  <span style={{ color: 'var(--success)', fontWeight: 'bold' }}>دیروز</span>
                  <span>تصویر پروفایل جوشکار <strong>امیرحسین رضایی</strong> توسط ادمین احراز هویت و تایید گردید.</span>
                </div>
                <div style={{ display: 'flex', gap: '12px', fontSize: '13px' }}>
                  <span style={{ color: 'var(--text-secondary)' }}>۲ روز پیش</span>
                  <span>جوشکار جدید <strong>سجاد محمدی</strong> با شماره تماس ۰۹۱۲۴۴۴۴۴۴۴ ثبت‌نام اولیه خود را انجام داد.</span>
                </div>
              </div>
            </div>
          </div>
        )}

        {/* TAB 2: PROFILE PICTURE APPROVALS */}
        {activeTab === 'approvals' && (
          <div className="glass-card">
            <h3 style={{ fontSize: '16px', fontWeight: '700', marginBottom: '16px' }}>کاربران معلق احراز هویت تصویر پروفایل</h3>
            
            {pendingVerifications.length === 0 ? (
              <div style={{ padding: '40px 0', textAlign: 'center', color: 'var(--text-secondary)' }}>
                <svg fill="none" viewBox="0 0 24 24" stroke="currentColor" width="48" height="48" style={{ marginBottom: '12px', opacity: 0.5 }}>
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
                <p>در حال حاضر هیچ کاربر معلقی برای تایید تصویر پروفایل وجود ندارد.</p>
              </div>
            ) : (
              <div className="table-responsive">
                <table className="custom-table">
                  <thead>
                    <tr>
                      <th>کاربر</th>
                      <th>نقش کاربری</th>
                      <th>شماره تماس</th>
                      <th>تصویر ارسالی</th>
                      <th>عملیات بررسی</th>
                    </tr>
                  </thead>
                  <tbody>
                    {pendingVerifications.map((user) => (
                      <tr key={user.id}>
                        <td>
                          <div className="user-info-cell">
                            <div className="avatar">
                              <span>{user.name.substring(0, 2)}</span>
                            </div>
                            <div className="user-details">
                              <h4>{user.name}</h4>
                            </div>
                          </div>
                        </td>
                        <td>
                          <span style={{ fontSize: '12px', fontWeight: 'bold', color: user.role === 'WELDER' ? 'var(--primary)' : 'var(--success)' }}>
                            {user.role === 'WELDER' ? 'جوشکار' : 'کارفرما'}
                          </span>
                        </td>
                        <td>{user.phone}</td>
                        <td>
                          <img 
                            src={user.pending_url} 
                            alt="Pending Preview" 
                            style={{ width: '42px', height: '42px', borderRadius: '8px', objectFit: 'cover', border: '1px solid var(--border)' }}
                          />
                        </td>
                        <td>
                          <button 
                            className="btn btn-secondary" 
                            onClick={() => setSelectedVerification(user)}
                          >
                            بررسی تصویر
                          </button>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
          </div>
        )}

        {/* TAB 3: INQUIRIES & ESTIMATIONS */}
        {activeTab === 'estimations' && (
          <div className="glass-card">
            <h3 style={{ fontSize: '16px', fontWeight: '700', marginBottom: '16px' }}>استعلام‌های ثبت‌شده بدون برآورد مالی</h3>
            
            {inquiries.filter(i => i.status === 'PENDING_ESTIMATION').length === 0 ? (
              <div style={{ padding: '40px 0', textAlign: 'center', color: 'var(--text-secondary)' }}>
                <svg fill="none" viewBox="0 0 24 24" stroke="currentColor" width="48" height="48" style={{ marginBottom: '12px', opacity: 0.5 }}>
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                </svg>
                <p>تمامی استعلام‌های پروژه‌ها با موفقیت برآورد شده‌اند!</p>
              </div>
            ) : (
              <div className="table-responsive">
                <table className="custom-table">
                  <thead>
                    <tr>
                      <th>عنوان پروژه</th>
                      <th>محدوده جغرافیایی</th>
                      <th>کارفرما</th>
                      <th>فایل نقشه</th>
                      <th>وضعیت برآورد</th>
                      <th>اقدام</th>
                    </tr>
                  </thead>
                  <tbody>
                    {inquiries
                      .filter(i => i.status === 'PENDING_ESTIMATION')
                      .map((inq) => (
                        <tr key={inq.id}>
                          <td style={{ fontWeight: 'bold' }}>{inq.title}</td>
                          <td>{inq.province}، {inq.city}</td>
                          <td>{inq.employer_name}</td>
                          <td>
                            {inq.has_blueprint ? (
                              <span style={{ color: 'var(--primary)', fontSize: '12px', fontWeight: 'bold' }}>دارای نقشه فنی</span>
                            ) : (
                              <span style={{ color: 'var(--text-secondary)', fontSize: '12px' }}>ثبت دستی اقلام</span>
                            )}
                          </td>
                          <td>
                            <span className="status-chip pending">در انتظار کارشناسی</span>
                          </td>
                          <td>
                            <button 
                              className="btn btn-primary" 
                              onClick={() => {
                                setSelectedInquiry(inq);
                                setEstimationItems([{ title: '', unit: 'متر', quantity: 1, price: 0 }]);
                              }}
                            >
                              کارشناسی نقشه
                            </button>
                          </td>
                        </tr>
                      ))}
                  </tbody>
                </table>
              </div>
            )}
          </div>
        )}

        {/* TAB 4: SKILLS CRUD MANAGEMENT */}
        {activeTab === 'skills' && (
          <div style={{ display: 'grid', gridTemplateColumns: '1.2fr 2fr', gap: '24px', alignItems: 'start' }}>
            {/* Create Skill Form */}
            <div className="glass-card">
              <h3 style={{ fontSize: '15px', fontWeight: '700', marginBottom: '18px' }}>افزودن تخصص جوشکاری جدید</h3>
              <form onSubmit={handleAddSkill}>
                <div className="form-group">
                  <label htmlFor="skillName">عنوان تخصص (فارسی)</label>
                  <input 
                    type="text" 
                    id="skillName"
                    className="input-control"
                    placeholder="مثال: جوشکاری آرگون تحت فشار"
                    value={newSkillName}
                    onChange={(e) => setNewSkillName(e.target.value)}
                    required
                  />
                </div>
                <button type="submit" className="btn btn-primary" style={{ width: '100%', height: '42px' }}>
                  ثبت تخصص جدید
                </button>
              </form>
            </div>

            {/* Skills Table List */}
            <div className="glass-card">
              <h3 style={{ fontSize: '15px', fontWeight: '700', marginBottom: '16px' }}>لیست کل تخصص‌های مجاز پلتفرم</h3>
              
              <div className="table-responsive">
                <table className="custom-table">
                  <thead>
                    <tr>
                      <th style={{ width: '80px' }}>شناسه</th>
                      <th>عنوان تخصص</th>
                      <th style={{ width: '160px', textAlign: 'left' }}>عملیات مدیریتی</th>
                    </tr>
                  </thead>
                  <tbody>
                    {skills.map((skill) => (
                      <tr key={skill.id}>
                        <td>#{skill.id}</td>
                        <td>
                          {editingSkillId === skill.id ? (
                            <input 
                              type="text" 
                              className="input-control" 
                              style={{ padding: '4px 8px', fontSize: '13px' }}
                              value={editingSkillName}
                              onChange={(e) => setEditingSkillName(e.target.value)}
                              onKeyDown={(e) => {
                                if (e.key === 'Enter') handleSaveEditSkill(skill.id);
                                else if (e.key === 'Escape') setEditingSkillId(null);
                              }}
                            />
                          ) : (
                            <span style={{ fontWeight: '500' }}>{skill.name}</span>
                          )}
                        </td>
                        <td style={{ textAlign: 'left' }}>
                          {editingSkillId === skill.id ? (
                            <div style={{ display: 'flex', gap: '8px', justifyContent: 'flex-end' }}>
                              <button 
                                className="btn btn-success" 
                                style={{ padding: '4px 10px', fontSize: '11px' }}
                                onClick={() => handleSaveEditSkill(skill.id)}
                              >
                                ذخیره
                              </button>
                              <button 
                                className="btn btn-secondary" 
                                style={{ padding: '4px 10px', fontSize: '11px' }}
                                onClick={() => setEditingSkillId(null)}
                              >
                                انصراف
                              </button>
                            </div>
                          ) : (
                            <div style={{ display: 'flex', gap: '8px', justifyContent: 'flex-end' }}>
                              <button 
                                className="btn btn-secondary" 
                                style={{ padding: '4px 10px', fontSize: '11px' }}
                                onClick={() => handleStartEditSkill(skill)}
                              >
                                ویرایش
                              </button>
                              <button 
                                className="btn btn-danger" 
                                style={{ padding: '4px 10px', fontSize: '11px' }}
                                onClick={() => handleDeleteSkill(skill.id)}
                              >
                                حذف
                              </button>
                            </div>
                          )}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          </div>
        )}

        {/* TAB 5: SERVER SETTINGS */}
        {activeTab === 'settings' && (
          <div className="glass-card" style={{ maxWidth: '600px', margin: '0 auto' }}>
            <h3 style={{ fontSize: '16px', fontWeight: '700', marginBottom: '18px' }}>پیکربندی دیتابیس و ارتباط با بک‌اند (NestJS)</h3>
            
            <div className="form-group">
              <label>آدرس هاست دیتابیس (PostgreSQL Host)</label>
              <input 
                type="text" 
                className="input-control" 
                value={dbHost} 
                onChange={(e) => setDbHost(e.target.value)}
              />
            </div>

            <div className="form-group">
              <label>پورت اتصال (PostgreSQL Port)</label>
              <input 
                type="text" 
                className="input-control" 
                value={dbPort} 
                onChange={(e) => setDbPort(e.target.value)}
              />
            </div>

            <div className="form-group">
              <label>نام پایگاه داده (Database Name)</label>
              <input 
                type="text" 
                className="input-control" 
                value={dbName} 
                onChange={(e) => setDbName(e.target.value)}
              />
            </div>

            <div style={{ display: 'flex', gap: '12px', marginTop: '24px' }}>
              <button 
                className="btn btn-primary" 
                onClick={() => {
                  showToast('تنظیمات پایگاه داده ذخیره شد. سرور در حال راه‌اندازی مجدد است...', 'success');
                }}
              >
                ذخیره تنظیمات دیتابیس
              </button>
              <button 
                className="btn btn-secondary" 
                onClick={async () => {
                  const alive = await ApiClient.ping();
                  if (alive) {
                    showToast('تست اتصال موفقیت‌آمیز بود! ارتباط با NestJS فعال است.', 'success');
                  } else {
                    showToast('تست اتصال ناموفق بود. از روشن بودن سرور بک‌اند اطمینان حاصل کنید.', 'warning');
                  }
                }}
              >
                تست اتصال مجدد
              </button>
            </div>
          </div>
        )}
      </main>

      {/* ─────────────────────────────────────────────────────────────
         MODAL 1: VIEW & VERIFY PENDING PROFILE PICTURE
         ───────────────────────────────────────────────────────────── */}
      {selectedVerification && (
        <div className="modal-overlay" onClick={() => setSelectedVerification(null)}>
          <div className="modal-content" onClick={(e) => e.stopPropagation()}>
            <div className="modal-header">
              <h3>بررسی تصویر ارسالی جهت احراز هویت</h3>
              <button className="modal-close" onClick={() => setSelectedVerification(null)}>&times;</button>
            </div>
            
            <div style={{ textAlign: 'center', marginBottom: '20px' }}>
              <img 
                src={selectedVerification.pending_url} 
                alt="Enlarged User Profile" 
                style={{ width: '220px', height: '220px', borderRadius: '16px', objectFit: 'cover', border: '2px solid var(--border)', boxShadow: '0 8px 24px rgba(0,0,0,0.3)' }}
              />
            </div>

            <div style={{ marginBottom: '24px', backgroundColor: 'rgba(255,255,255,0.02)', padding: '14px', borderRadius: '8px', border: '1px solid var(--border)' }}>
              <p style={{ fontSize: '13px', color: 'var(--text-secondary)', marginBottom: '8px' }}>
                کاربر: <strong style={{ color: 'white' }}>{selectedVerification.name}</strong> ({selectedVerification.role === 'WELDER' ? 'جوشکار' : 'کارفرما'})
              </p>
              <p style={{ fontSize: '13px', color: 'var(--text-secondary)' }}>
                بیوگرافی/توضیحات: <span style={{ color: 'white', fontStyle: 'italic' }}>{selectedVerification.bio || 'توضیحاتی وارد نشده است.'}</span>
              </p>
            </div>

            <div style={{ display: 'flex', gap: '12px', justifyContent: 'flex-end' }}>
              <button 
                className="btn btn-success" 
                onClick={() => handleVerify(selectedVerification.id, selectedVerification.role, true)}
              >
                تایید تصویر و انتشار در اپ
              </button>
              <button 
                className="btn btn-danger" 
                onClick={() => handleVerify(selectedVerification.id, selectedVerification.role, false)}
              >
                رد تصویر
              </button>
              <button 
                className="btn btn-secondary" 
                onClick={() => setSelectedVerification(null)}
              >
                بستن
              </button>
            </div>
          </div>
        </div>
      )}

      {/* ─────────────────────────────────────────────────────────────
         MODAL 2: INQUIRY ESTIMATION & WORKSHOP PLAN ANALYSIS
         ───────────────────────────────────────────────────────────── */}
      {selectedInquiry && (
        <div className="modal-overlay" onClick={() => setSelectedInquiry(null)}>
          <div className="modal-content" style={{ maxWidth: '780px' }} onClick={(e) => e.stopPropagation()}>
            <div className="modal-header">
              <h3>کارشناسی نقشه و ثبت اقلام فنی استعلام</h3>
              <button className="modal-close" onClick={() => setSelectedInquiry(null)}>&times;</button>
            </div>

            <div style={{ display: 'grid', gridTemplateColumns: '1.2fr 1fr', gap: '20px', marginBottom: '20px' }}>
              {/* Left Column: Blueprint Viewer */}
              <div>
                <h4 style={{ fontSize: '13px', color: 'var(--text-secondary)', marginBottom: '8px' }}>فایل نقشه پروژه (Blueprint)</h4>
                {selectedInquiry.has_blueprint ? (
                  <div style={{ position: 'relative', height: '220px', borderRadius: '12px', overflow: 'hidden', border: '1px solid var(--border)' }}>
                    <img 
                      src={selectedInquiry.blueprint_url || ''} 
                      alt="Project Blueprint" 
                      style={{ width: '100%', height: '100%', objectFit: 'cover' }}
                    />
                    <a 
                      href={selectedInquiry.blueprint_url || ''} 
                      target="_blank" 
                      rel="noreferrer"
                      style={{ position: 'absolute', bottom: '12px', left: '12px', backgroundColor: 'rgba(0,0,0,0.7)', color: 'white', padding: '4px 10px', borderRadius: '6px', fontSize: '11px', textDecoration: 'none' }}
                    >
                      مشاهده سایز اصلی
                    </a>
                  </div>
                ) : (
                  <div style={{ height: '220px', borderRadius: '12px', backgroundColor: 'rgba(255,255,255,0.01)', border: '1px dashed var(--border)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'var(--text-secondary)' }}>
                    بدون نقشه ارسالی
                  </div>
                )}
              </div>

              {/* Right Column: Project details */}
              <div style={{ display: 'flex', flexDirection: 'column', gap: '10px' }}>
                <h4 style={{ fontSize: '14px', fontWeight: 'bold' }}>{selectedInquiry.title}</h4>
                <p style={{ fontSize: '12px', color: 'var(--text-secondary)' }}>
                  کارفرما: <strong>{selectedInquiry.employer_name}</strong>
                </p>
                <p style={{ fontSize: '12px', color: 'var(--text-secondary)' }}>
                  موقعیت: <strong>{selectedInquiry.province}، {selectedInquiry.city}</strong>
                </p>
                <div style={{ flex: 1, overflowY: 'auto', maxHeight: '120px', backgroundColor: 'rgba(255,255,255,0.02)', padding: '10px', borderRadius: '8px', border: '1px solid var(--border)' }}>
                  <p style={{ fontSize: '12px', color: 'var(--text-secondary)', lineHeight: '1.6' }}>
                    توضیحات پروژه: <span style={{ color: 'white' }}>{selectedInquiry.description}</span>
                  </p>
                </div>
              </div>
            </div>

            {/* Estimation items rows */}
            <div style={{ borderTop: '1px solid var(--border)', paddingTop: '16px', marginBottom: '20px' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '12px' }}>
                <h4 style={{ fontSize: '14px', fontWeight: 'bold' }}>آیتم‌های استخراج شده و برآورد قیمت</h4>
                <button className="btn btn-secondary" style={{ padding: '4px 10px', fontSize: '11px' }} onClick={addEstimationRow}>
                  + افزودن ردیف جدید
                </button>
              </div>

              <div style={{ maxHeight: '200px', overflowY: 'auto', paddingLeft: '4px' }}>
                {estimationItems.map((item, idx) => (
                  <div key={idx} className="est-item-row">
                    <input 
                      type="text" 
                      className="input-control" 
                      placeholder="عنوان قلم (مثال: جوش لوله ۲ اینچ)"
                      value={item.title}
                      onChange={(e) => handleEstimationRowChange(idx, 'title', e.target.value)}
                    />
                    
                    <select 
                      className="input-control"
                      value={item.unit}
                      onChange={(e) => handleEstimationRowChange(idx, 'unit', e.target.value)}
                      style={{ padding: '8px' }}
                    >
                      <option value="متر">متر</option>
                      <option value="عدد">عدد</option>
                      <option value="کیلوگرم">کیلوگرم</option>
                      <option value="شاخه">شاخه</option>
                    </select>

                    <input 
                      type="number" 
                      className="input-control" 
                      placeholder="تعداد"
                      min="1"
                      value={item.quantity}
                      onChange={(e) => handleEstimationRowChange(idx, 'quantity', parseInt(e.target.value) || 1)}
                    />

                    <input 
                      type="number" 
                      className="input-control" 
                      placeholder="قیمت واحد (تومان)"
                      min="0"
                      value={item.price || ''}
                      onChange={(e) => handleEstimationRowChange(idx, 'price', parseFloat(e.target.value) || 0)}
                    />

                    <button 
                      className="btn btn-danger" 
                      style={{ padding: '8px 12px' }}
                      onClick={() => removeEstimationRow(idx)}
                      disabled={estimationItems.length === 1}
                    >
                      حذف
                    </button>
                  </div>
                ))}
              </div>

              <div style={{ textAlign: 'left', marginTop: '14px', fontSize: '14px', fontWeight: 'bold' }}>
                مجموع برآورد مالی: <span style={{ color: 'var(--primary)' }}>
                  {estimationItems.reduce((acc, curr) => acc + (curr.quantity * (curr.price || 0)), 0).toLocaleString()} تومان
                </span>
              </div>
            </div>

            {/* Modal actions */}
            <div style={{ display: 'flex', gap: '12px', justifyContent: 'flex-end', borderTop: '1px solid var(--border)', paddingTop: '16px' }}>
              <button 
                className="btn btn-primary" 
                onClick={() => handleSubmittingEstimation(selectedInquiry.id)}
              >
                ثبت و ارسال برآورد نهایی به کارفرما
              </button>
              <button 
                className="btn btn-secondary" 
                onClick={() => setSelectedInquiry(null)}
              >
                انصراف
              </button>
            </div>
          </div>
        </div>
      )}

      {/* ─────────────────────────────────────────────────────────────
         TOAST SYSTEM RENDERER
         ───────────────────────────────────────────────────────────── */}
      <div className="toast-overlay">
        {toasts.map(toast => (
          <div key={toast.id} className={`toast ${toast.type}`}>
            <span className="badge-dot"></span>
            <span>{toast.message}</span>
          </div>
        ))}
      </div>
    </div>
  );
}
