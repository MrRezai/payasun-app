import { useState, useEffect } from 'react';
import { BrowserRouter, Routes, Route, Navigate, useNavigate, useLocation } from 'react-router-dom';
import { ApiClient } from './api';
import { Skill, Inquiry, InquiryItem } from './types';

// Components
import Sidebar from './components/Sidebar';
import Topbar from './components/Topbar';
import ToastOverlay, { Toast } from './components/ToastOverlay';

// Pages
import Login from './pages/Login';
import Overview from './pages/Overview';
import Users from './pages/Users';
import Approvals from './pages/Approvals';
import Projects from './pages/Projects';
import Skills from './pages/Skills';

// Modals
import VerifyPictureModal from './modals/VerifyPictureModal';
import EstimateProjectModal from './modals/EstimateProjectModal';
import ViewProjectDetailModal from './modals/ViewProjectDetailModal';

function AppContent() {
  const navigate = useNavigate();
  const location = useLocation();

  const [isAuthenticated, setIsAuthenticated] = useState(ApiClient.isAuthenticated());
  const [isOnline, setIsOnline] = useState(false);
  const [toasts, setToasts] = useState<Toast[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [tabLoading, setTabLoading] = useState(false);

  // Live Database States
  const [weldersCount, setWeldersCount] = useState(0);
  const [employersCount, setEmployersCount] = useState(0);
  const [skills, setSkills] = useState<Skill[]>([]);
  const [pendingVerifications, setPendingVerifications] = useState<any[]>([]);
  const [inquiries, setInquiries] = useState<Inquiry[]>([]);
  const [usersList, setUsersList] = useState<any[]>([]);

  // Selected details / Dialog states
  const [selectedVerification, setSelectedVerification] = useState<any | null>(null);
  const [selectedInquiry, setSelectedInquiry] = useState<Inquiry | null>(null);
  const [viewingProjectDetail, setViewingProjectDetail] = useState<Inquiry | null>(null);

  // Trigger Toast helper
  const showToast = (message: string, type: 'success' | 'warning' = 'success') => {
    const id = Date.now() + Math.random();
    setToasts(prev => [...prev, { id, message, type }]);
    setTimeout(() => {
      setToasts(prev => prev.filter(t => t.id !== id));
    }, 4000);
  };

  // Load all required states dynamically or sequentially
  const loadAllData = async () => {
    setTabLoading(true);
    try {
      // Load Overview data
      const weldersNum = await ApiClient.getWeldersCount().catch(() => 0);
      setWeldersCount(weldersNum);
      const employersNum = await ApiClient.getEmployersCount().catch(() => 0);
      setEmployersCount(employersNum);
      const usersData = await ApiClient.getUsers().catch(() => []);
      setUsersList(usersData);
      
      // Load approvals
      const pendingData = await ApiClient.getPendingVerifications().catch(() => []);
      setPendingVerifications(pendingData);

      // Load inquiries
      const inquiriesData = await ApiClient.getInquiries().catch(() => []);
      setInquiries(inquiriesData);

      // Load skills
      const skillsData = await ApiClient.getSkills().catch(() => []);
      setSkills(skillsData);
    } catch (e: any) {
      if (e.message === 'UNAUTHORIZED') {
        setIsAuthenticated(false);
        showToast('جلسه کاری شما منقضی شده است. لطفا دوباره وارد شوید.', 'warning');
      } else {
        showToast(e.message || 'خطا در دریافت اطلاعات از سرور.', 'warning');
      }
    } finally {
      setTabLoading(false);
    }
  };

  useEffect(() => {
    const handleStatusChange = (status: boolean) => {
      setIsOnline(status);
    };
    
    ApiClient.addStatusListener(handleStatusChange);
    
    if (isAuthenticated) {
      loadAllData();
      if (location.pathname === '/login' || location.pathname === '/') {
        navigate('/overview');
      }
    } else {
      navigate('/login');
    }

    const interval = setInterval(() => {
      ApiClient.ping();
      if (isAuthenticated) {
        // Silent sync in background to keep data fresh without spin loader
        ApiClient.getPendingVerifications().then(setPendingVerifications).catch(console.error);
        ApiClient.getInquiries().then(setInquiries).catch(console.error);
      }
    }, 5000);

    return () => {
      ApiClient.removeStatusListener(handleStatusChange);
      clearInterval(interval);
    };
  }, [isAuthenticated]);

  // Actions
  const handleAdminLogin = async (user: string, pass: string) => {
    setIsLoading(true);
    try {
      await ApiClient.verifyAdminLogin(user, pass);
      setIsAuthenticated(true);
      showToast('خوش آمدید! ورود به پنل مدیریت با موفقیت انجام شد.', 'success');
      navigate('/overview');
    } catch (e: any) {
      showToast(e.message || 'خطا در احراز هویت ادمین.', 'warning');
    } finally {
      setIsLoading(false);
    }
  };

  const handleLogout = () => {
    ApiClient.setToken(null);
    setIsAuthenticated(false);
    showToast('شما با موفقیت از حساب کاربری خارج شدید.', 'success');
    navigate('/login');
  };

  const handleVerifyPicture = async (userId: string, role: 'WELDER' | 'EMPLOYER', approve: boolean) => {
    try {
      await ApiClient.verifyPicture(userId, role, approve);
      showToast(
        approve 
          ? 'تصویر کاربری با موفقیت تایید و فعال گردید.' 
          : 'تصویر کاربری رد گردید و از حالت معلق خارج شد.', 
        approve ? 'success' : 'warning'
      );
      setSelectedVerification(null);
      loadAllData();
    } catch (e: any) {
      if (e.message === 'UNAUTHORIZED') {
        setIsAuthenticated(false);
        showToast('جلسه کاری شما منقضی شده است. لطفا دوباره وارد شوید.', 'warning');
      } else {
        showToast(e.message || 'خطا در انجام احراز هویت.', 'warning');
      }
    }
  };

  const handleSubmitEstimation = async (inqId: string, items: InquiryItem[]) => {
    const invalid = items.some(item => !item.title || item.quantity <= 0);
    if (invalid) {
      showToast('لطفاً اطلاعات تمام اقلام فنی را به درستی وارد کنید.', 'warning');
      return;
    }
    try {
      const itemsToSubmit = items.map(item => ({
        title: item.title,
        unit: item.unit,
        quantity: item.quantity,
        price: 0
      }));
      await ApiClient.submitEstimation(inqId, itemsToSubmit);
      showToast('لیست اقلام فنی با موفقیت ثبت و پروژه در پلتفرم منتشر گردید.', 'success');
      setSelectedInquiry(null);
      loadAllData();
    } catch (e: any) {
      if (e.message === 'UNAUTHORIZED') {
        setIsAuthenticated(false);
        showToast('جلسه کاری شما منقضی شده است. لطفا دوباره وارد شوید.', 'warning');
      } else {
        showToast(e.message || 'خطا در تایید و انتشار استعلام.', 'warning');
      }
    }
  };

  const handleRejectInquiry = async (inqId: string, reason: string) => {
    if (!reason.trim()) {
      showToast('لطفا دلیل رد استعلام را وارد کنید.', 'warning');
      return;
    }
    try {
      await ApiClient.rejectInquiry(inqId, reason.trim());
      showToast('استعلام پروژه با موفقیت رد گردید و دلیل ثبت شد.', 'success');
      setSelectedInquiry(null);
      setViewingProjectDetail(null);
      loadAllData();
    } catch (e: any) {
      if (e.message === 'UNAUTHORIZED') {
        setIsAuthenticated(false);
        showToast('جلسه کاری شما منقضی شده است. لطفا دوباره وارد شوید.', 'warning');
      } else {
        showToast(e.message || 'خطا در رد کردن پروژه.', 'warning');
      }
    }
  };

  const handleDeleteInquiry = async (inqId: string) => {
    try {
      await ApiClient.deleteInquiry(inqId);
      showToast('پروژه با موفقیت و به طور کامل حذف شد.', 'success');
      setViewingProjectDetail(null);
      loadAllData();
    } catch (e: any) {
      if (e.message === 'UNAUTHORIZED') {
        setIsAuthenticated(false);
        showToast('جلسه کاری شما منقضی شده است. لطفا دوباره وارد شوید.', 'warning');
      } else {
        showToast(e.message || 'خطا در حذف پروژه.', 'warning');
      }
    }
  };

  const handleToggleOfferVisibility = async (offerId: string, isHidden: boolean) => {
    try {
      await ApiClient.toggleOfferVisibility(offerId, isHidden);
      showToast(isHidden ? 'پیشنهاد با موفقیت از دید کارفرما پنهان شد.' : 'پیشنهاد مجددا برای کارفرما قابل مشاهده گردید.', 'success');
      loadAllData();
      
      // Update the modal's state if it's currently open
      if (viewingProjectDetail) {
        setViewingProjectDetail(prev => {
          if (!prev) return null;
          const updatedOffers = prev.offers?.map(o => {
            if (o.id === offerId) {
              return { ...o, is_hidden: isHidden };
            }
            return o;
          });
          return { ...prev, offers: updatedOffers };
        });
      }
    } catch (e: any) {
      if (e.message === 'UNAUTHORIZED') {
        setIsAuthenticated(false);
        showToast('جلسه کاری شما منقضی شده است. لطفا دوباره وارد شوید.', 'warning');
      } else {
        showToast(e.message || 'خطا در تغییر وضعیت پیشنهاد.', 'warning');
      }
    }
  };

  const handleAddSkill = async (name: string) => {
    try {
      await ApiClient.createSkill(name);
      showToast('تخصص جدید با موفقیت به سیستم اضافه شد.', 'success');
      loadAllData();
    } catch (e: any) {
      if (e.message === 'UNAUTHORIZED') {
        setIsAuthenticated(false);
        showToast('جلسه کاری شما منقضی شده است. لطفا دوباره وارد شوید.', 'warning');
      } else {
        showToast(e.message || 'خطا در ثبت تخصص.', 'warning');
      }
    }
  };

  const handleEditSkill = async (id: number, name: string) => {
    try {
      await ApiClient.updateSkill(id, name);
      showToast('نام تخصص با موفقیت ویرایش شد.', 'success');
      loadAllData();
    } catch (e: any) {
      if (e.message === 'UNAUTHORIZED') {
        setIsAuthenticated(false);
        showToast('جلسه کاری شما منقضی شده است. لطفا دوباره وارد شوید.', 'warning');
      } else {
        showToast(e.message || 'خطا در ویرایش تخصص.', 'warning');
      }
    }
  };

  const handleDeleteSkill = async (id: number) => {
    if (!window.confirm('آیا از حذف این تخصص اطمینان دارید؟ حذف این مورد ممکن است مهارت‌های ثبت شده جوشکاران را تحت تاثیر قرار دهد.')) return;
    try {
      await ApiClient.deleteSkill(id);
      showToast('تخصص مربوطه از سیستم حذف گردید.', 'warning');
      loadAllData();
    } catch (e: any) {
      if (e.message === 'UNAUTHORIZED') {
        setIsAuthenticated(false);
        showToast('جلسه کاری شما منقضی شده است. لطفا دوباره وارد شوید.', 'warning');
      } else {
        showToast(e.message || 'خطا در حذف تخصص.', 'warning');
      }
    }
  };

  const pendingEstimationsCount = inquiries.filter(i => i.status === 'PENDING_ESTIMATION').length;
  const pendingPicsCount = pendingVerifications.length;

  const TabLoader = () => (
    <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', minHeight: '220px', gap: '14px' }}>
      <div className="spinner"></div>
      <span style={{ fontSize: '13px', color: 'var(--text-secondary)', fontWeight: '500' }}>در حال دریافت اطلاعات زنده از دیتابیس...</span>
    </div>
  );

  return (
    <div className="app-container">
      {isAuthenticated && (
        <Sidebar 
          pendingPicsCount={pendingPicsCount}
          pendingEstimationsCount={pendingEstimationsCount}
          onLogout={handleLogout}
        />
      )}

      <main className="main-wrapper">
        {isAuthenticated && <Topbar isOnline={isOnline} />}

        {tabLoading ? <TabLoader /> : (
          <Routes>
            <Route path="/login" element={
              isAuthenticated ? <Navigate to="/overview" replace /> : <Login onLoginSuccess={handleAdminLogin} isOnline={isOnline} isLoading={isLoading} />
            } />

            <Route path="/overview" element={
              isAuthenticated ? (
                <Overview 
                  weldersCount={weldersCount}
                  employersCount={employersCount}
                  pendingPicsCount={pendingPicsCount}
                  pendingEstimationsCount={pendingEstimationsCount}
                  inquiries={inquiries}
                  usersList={usersList}
                />
              ) : <Navigate to="/login" replace />
            } />

            <Route path="/users" element={
              isAuthenticated ? <Users usersList={usersList} /> : <Navigate to="/login" replace />
            } />

            <Route path="/approvals" element={
              isAuthenticated ? (
                <Approvals 
                  pendingVerifications={pendingVerifications}
                  onSelectVerification={setSelectedVerification}
                />
              ) : <Navigate to="/login" replace />
            } />

            <Route path="/projects" element={
              isAuthenticated ? (
                <Projects 
                  inquiries={inquiries}
                  onEstimateClick={setSelectedInquiry}
                  onViewDetailClick={setViewingProjectDetail}
                />
              ) : <Navigate to="/login" replace />
            } />

            <Route path="/skills" element={
              isAuthenticated ? (
                <Skills 
                  skills={skills}
                  onAddSkill={handleAddSkill}
                  onEditSkill={handleEditSkill}
                  onDeleteSkill={handleDeleteSkill}
                />
              ) : <Navigate to="/login" replace />
            } />

            <Route path="*" element={<Navigate to={isAuthenticated ? "/overview" : "/login"} replace />} />
          </Routes>
        )}
      </main>

      {/* Verify Picture Modal */}
      {selectedVerification && (
        <VerifyPictureModal 
          user={selectedVerification}
          onClose={() => setSelectedVerification(null)}
          onVerify={handleVerifyPicture}
        />
      )}

      {/* Estimate/Carشناسی project modal */}
      {selectedInquiry && (
        <EstimateProjectModal 
          inquiry={selectedInquiry}
          onClose={() => setSelectedInquiry(null)}
          onSubmitEstimation={handleSubmitEstimation}
          onRejectInquiry={handleRejectInquiry}
        />
      )}

      {/* View project technical detail modal */}
      {viewingProjectDetail && (
        <ViewProjectDetailModal 
          inquiry={viewingProjectDetail}
          onClose={() => setViewingProjectDetail(null)}
          onRejectInquiry={handleRejectInquiry}
          onDeleteInquiry={handleDeleteInquiry}
          onToggleOfferVisibility={handleToggleOfferVisibility}
        />
      )}

      <ToastOverlay toasts={toasts} />
    </div>
  );
}

export default function App() {
  return (
    <BrowserRouter>
      <AppContent />
    </BrowserRouter>
  );
}
