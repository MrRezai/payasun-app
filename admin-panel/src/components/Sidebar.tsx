import { NavLink } from 'react-router-dom';
import { Badge } from 'antd';
import logoImg from '../assets/logo/joftojoor.png';

interface SidebarProps {
  pendingPicsCount: number;
  pendingEstimationsCount: number;
  onLogout: () => void;
  isOpen?: boolean;
  onCloseMobile?: () => void;
}

export default function Sidebar({ pendingPicsCount, pendingEstimationsCount, onLogout, isOpen, onCloseMobile }: SidebarProps) {
  return (
    <>
      {isOpen && <div className="sidebar-overlay" onClick={onCloseMobile} />}
      <aside className={`sidebar ${isOpen ? 'open' : ''}`}>
        <div className="sidebar-logo">
          <img src={logoImg} alt="جفت و جور" />
          <span>پنل مدیریت جفت‌وجور</span>
        </div>
        
        <nav className="menu-section">
          <NavLink 
            to="/overview" 
            className={({ isActive }) => `menu-item ${isActive ? 'active' : ''}`}
            onClick={onCloseMobile}
          >
            <svg fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 6a2 2 0 012-2h2a2 2 0 012 2v4a2 2 0 01-2 2H6a2 2 0 01-2-2V6zM14 6a2 2 0 012-2h2a2 2 0 012 2v4a2 2 0 01-2 2h-2a2 2 0 01-2-2V6zM4 16a2 2 0 012-2h2a2 2 0 012 2v4a2 2 0 01-2 2H6a2 2 0 01-2-2v-4zM14 16a2 2 0 012-2h2a2 2 0 012 2v4a2 2 0 01-2 2h-2a2 2 0 01-2-2v-4z" />
            </svg>
            <span>داشبورد عمومی</span>
          </NavLink>

          <NavLink 
            to="/users" 
            className={({ isActive }) => `menu-item ${isActive ? 'active' : ''}`}
            onClick={onCloseMobile}
          >
            <svg fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a3 3 0 11-6 0 3 3 0 016 0z" />
            </svg>
            <span>لیست کاربران</span>
          </NavLink>

          <NavLink 
            to="/approvals" 
            className={({ isActive }) => `menu-item ${isActive ? 'active' : ''}`}
            onClick={onCloseMobile}
          >
            <svg fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" />
            </svg>
            <span>تایید هویت تصاویر</span>
            {pendingPicsCount > 0 && (
              <Badge 
                count={pendingPicsCount} 
                overflowCount={99}
                style={{ marginInlineStart: 'auto', backgroundColor: '#F59E0B' }} 
              />
            )}
          </NavLink>

          <NavLink 
            to="/projects" 
            className={({ isActive }) => `menu-item ${isActive ? 'active' : ''}`}
            onClick={onCloseMobile}
          >
            <svg fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 17v-2m3 2v-4m3 4v-6m2 10H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
            </svg>
            <span>مدیریت پروژه‌ها</span>
            {pendingEstimationsCount > 0 && (
              <Badge 
                count={pendingEstimationsCount} 
                overflowCount={99}
                style={{ marginInlineStart: 'auto', backgroundColor: '#4169E1' }} 
              />
            )}
          </NavLink>

          <NavLink 
            to="/settings" 
            className={({ isActive }) => `menu-item ${isActive ? 'active' : ''}`}
            onClick={onCloseMobile}
          >
            <svg fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z" />
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
            </svg>
            <span>تنظیمات</span>
          </NavLink>
        </nav>
        
        <div style={{ marginTop: 'auto', padding: '12px', borderTop: '1px solid var(--border)', fontSize: '11px', color: 'var(--text-secondary)', textAlign: 'center' }}>
          <button className="btn btn-secondary" style={{ padding: '6px 12px', width: '100%', fontSize: '11px' }} onClick={onLogout}>
            خروج از حساب ادمین
          </button>
        </div>
      </aside>
    </>
  );
}
