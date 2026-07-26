import { useLocation } from 'react-router-dom';

interface TopbarProps {
  isOnline?: boolean;
  onToggleMobileMenu?: () => void;
}

export default function Topbar({ onToggleMobileMenu }: TopbarProps) {
  const location = useLocation();
  const path = location.pathname;

  let title = 'داشبورد عمومی مدیریت';
  if (path === '/users') title = 'لیست کامل کاربران پلتفرم';
  else if (path === '/approvals') title = 'تایید و صحت‌سنجی مدارک';
  else if (path === '/projects') title = 'مدیریت و کارشناسی استعلام‌های پروژه';
  else if (path === '/skills') title = 'تنظیمات تخصص‌ها و مهارت‌ها';

  return (
    <header className="topbar">
      <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
        {onToggleMobileMenu && (
          <button 
            className="mobile-menu-btn" 
            onClick={onToggleMobileMenu} 
            title="منوی اصلی"
            aria-label="Toggle Navigation"
          >
            <svg width="22" height="22" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 6h16M4 12h16M4 18h16" />
            </svg>
          </button>
        )}
        <div className="topbar-title">
          <h1>{title}</h1>
        </div>
      </div>
      
      <div className="topbar-actions">
        <div className="avatar" style={{ border: '1px solid var(--border)' }}>
          <span>AD</span>
        </div>
      </div>
    </header>
  );
}
