import { useLocation } from 'react-router-dom';

interface TopbarProps {
  isOnline: boolean;
}

export default function Topbar({ isOnline }: TopbarProps) {
  const location = useLocation();
  const path = location.pathname;

  let title = 'داشبورد عمومی مدیریت';
  if (path === '/users') title = 'لیست کامل کاربران پلتفرم';
  else if (path === '/approvals') title = 'تایید و صحت‌سنجی مدارک';
  else if (path === '/projects') title = 'مدیریت و کارشناسی استعلام‌های پروژه';
  else if (path === '/skills') title = 'تنظیمات تخصص‌ها و مهارت‌ها';

  return (
    <header className="topbar">
      <div className="topbar-title">
        <h1>{title}</h1>
      </div>
      
      <div className="topbar-actions">
        {isOnline ? (
          <div className="server-badge online">
            <span className="badge-dot pulse"></span>
            <span>متصل به سرور</span>
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
  );
}
