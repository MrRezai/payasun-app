import { useState } from 'react';
import logoImg from '../assets/logo/joftojoor.png';

interface LoginProps {
  onLoginSuccess: (username: string, pass: string) => Promise<void>;
  isOnline: boolean;
  isLoading: boolean;
}

export default function Login({ onLoginSuccess, isOnline, isLoading }: LoginProps) {
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    onLoginSuccess(username, password);
  };

  return (
    <div style={{ display: 'flex', minHeight: '100vh', alignItems: 'center', justifyContent: 'center', backgroundColor: '#F8FAFC', padding: '16px' }}>
      <div className="glass-card" style={{ width: '100%', maxWidth: '420px', padding: '32px', boxShadow: '0 10px 30px rgba(15, 23, 42, 0.08)' }}>
        <div style={{ textAlign: 'center', marginBottom: '24px' }}>
          <img src={logoImg} alt="جفت و جور" style={{ width: '64px', height: '64px', marginBottom: '12px', borderRadius: '16px' }} />
          <h2 style={{ fontSize: '20px', fontWeight: '800', color: 'var(--text-primary)' }}>ورود به پنل مدیریت جفت‌وجور</h2>
          <p style={{ fontSize: '12px', color: 'var(--text-secondary)', marginTop: '6px' }}>
            احراز هویت کنترل ادمین سیستم
          </p>
        </div>

        <form onSubmit={handleSubmit}>
          <div className="form-group">
            <label htmlFor="adminUser">نام کاربری ادمین (Username)</label>
            <input 
              type="text" 
              id="adminUser"
              className="input-control"
              placeholder="نام کاربری را وارد کنید"
              value={username}
              onChange={(e) => setUsername(e.target.value)}
              disabled={isLoading}
              required
            />
          </div>
          
          <div className="form-group">
            <label htmlFor="adminPass">رمز عبور (Password)</label>
            <input 
              type="password" 
              id="adminPass"
              className="input-control"
              placeholder="رمز عبور را وارد کنید"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              disabled={isLoading}
              required
            />
          </div>

          <button type="submit" className="btn btn-primary" style={{ width: '100%', height: '44px', marginTop: '8px' }} disabled={isLoading}>
            {isLoading ? 'در حال بررسی...' : 'ورود به پنل مدیریت'}
          </button>
        </form>

        <div style={{ marginTop: '24px', paddingTop: '16px', borderTop: '1px solid var(--border)', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '8px' }}>
          <span className={`badge-dot ${isOnline ? 'pulse' : ''}`} style={{ backgroundColor: isOnline ? 'var(--success)' : 'var(--warning)' }}></span>
          <span style={{ fontSize: '11px', color: 'var(--text-secondary)' }}>
            {isOnline ? 'سیستم آنلاین و متصل به دیتابیس است' : 'سیستم در حالت شبیه‌ساز آفلاین است'}
          </span>
        </div>
      </div>
    </div>
  );
}
