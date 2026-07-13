import { NavLink } from 'react-router-dom';

interface SidebarProps {
  pendingPicsCount: number;
  pendingEstimationsCount: number;
  onLogout: () => void;
}

export default function Sidebar({ pendingPicsCount, pendingEstimationsCount, onLogout }: SidebarProps) {
  return (
    <aside className="sidebar">
      <div className="sidebar-logo">
        <img src="/src/assets/logo/joftojoor.png" alt="جفت و جور" />
        <span>پنل مدیریت جفت‌وجور</span>
      </div>
      
      <nav className="menu-section">
        <NavLink 
          to="/overview" 
          className={({ isActive }) => `menu-item ${isActive ? 'active' : ''}`}
        >
          <svg fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 6a2 2 0 012-2h2a2 2 0 012 2v4a2 2 0 01-2 2H6a2 2 0 01-2-2V6zM14 6a2 2 0 012-2h2a2 2 0 012 2v4a2 2 0 01-2 2h-2a2 2 0 01-2-2V6zM4 16a2 2 0 012-2h2a2 2 0 012 2v4a2 2 0 01-2 2H6a2 2 0 01-2-2v-4zM14 16a2 2 0 012-2h2a2 2 0 012 2v4a2 2 0 01-2 2h-2a2 2 0 01-2-2v-4z" />
          </svg>
          <span>داشبورد عمومی</span>
        </NavLink>

        <NavLink 
          to="/users" 
          className={({ isActive }) => `menu-item ${isActive ? 'active' : ''}`}
        >
          <svg fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a3 3 0 11-6 0 3 3 0 016 0z" />
          </svg>
          <span>لیست کاربران</span>
        </NavLink>

        <NavLink 
          to="/approvals" 
          className={({ isActive }) => `menu-item ${isActive ? 'active' : ''}`}
        >
          <svg fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" />
          </svg>
          <span>تایید هویت تصاویر</span>
          {pendingPicsCount > 0 && (
            <span style={{ marginRight: 'auto', backgroundColor: 'var(--secondary)', color: 'white', borderRadius: '50%', width: '18px', height: '18px', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '10px', fontWeight: 'bold' }}>
              {pendingPicsCount}
            </span>
          )}
        </NavLink>

        <NavLink 
          to="/projects" 
          className={({ isActive }) => `menu-item ${isActive ? 'active' : ''}`}
        >
          <svg fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 17v-2m3 2v-4m3 4v-6m2 10H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
          </svg>
          <span>مدیریت پروژه‌ها</span>
          {pendingEstimationsCount > 0 && (
            <span style={{ marginRight: 'auto', backgroundColor: 'var(--primary)', color: 'white', borderRadius: '50%', width: '18px', height: '18px', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '10px', fontWeight: 'bold' }}>
              {pendingEstimationsCount}
            </span>
          )}
        </NavLink>

        <NavLink 
          to="/skills" 
          className={({ isActive }) => `menu-item ${isActive ? 'active' : ''}`}
        >
          <svg fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10" />
          </svg>
          <span>مدیریت تخصص‌ها</span>
        </NavLink>
      </nav>
      
      <div style={{ marginTop: 'auto', padding: '12px', borderTop: '1px solid var(--border)', fontSize: '11px', color: 'var(--text-secondary)', textAlign: 'center' }}>
        <button className="btn btn-secondary" style={{ padding: '6px 12px', width: '100%', fontSize: '11px' }} onClick={onLogout}>
          خروج از حساب ادمین
        </button>
      </div>
    </aside>
  );
}
