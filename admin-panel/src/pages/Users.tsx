import { useState } from 'react';
import { BASE_URL } from '../api';
import ViewUserHistoryModal from '../modals/ViewUserHistoryModal';

interface UsersProps {
  usersList: any[];
  onDeleteUser: (id: string) => Promise<void>;
  onToggleBlockUser: (id: string, isBlocked: boolean) => Promise<void>;
}

export default function Users({ usersList, onDeleteUser, onToggleBlockUser }: UsersProps) {
  const [selectedUserId, setSelectedUserId] = useState<string | null>(null);

  return (
    <div className="glass-card" style={{ animation: 'fadeIn 0.3s ease-out' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '18px' }}>
        <h3 style={{ fontSize: '16px', fontWeight: '700' }}>لیست کامل کاربران پلتفرم جفت‌وجور</h3>
        <span style={{ fontSize: '13px', color: 'var(--text-secondary)' }}>
          تعداد کل کاربران: <strong>{usersList.length} نفر</strong>
        </span>
      </div>
      
      {usersList.length === 0 ? (
        <div style={{ padding: '40px 0', textAlign: 'center', color: 'var(--text-secondary)' }}>
          هیچ کاربری یافت نشد.
        </div>
      ) : (
        <div className="table-responsive">
          <table className="custom-table">
            <thead>
              <tr>
                <th>نام کاربر</th>
                <th>شماره همراه</th>
                <th>نقش فعال فعلی</th>
                <th>محدوده جغرافیایی</th>
                <th>نقش‌های ثبت شده</th>
                <th>تاریخ عضویت</th>
                <th>عملیات</th>
              </tr>
            </thead>
            <tbody>
              {usersList.map((usr) => (
                <tr key={usr.id}>
                  <td>
                    <div className="user-info-cell">
                      <div className="avatar">
                        {usr.profile_picture_url ? (
                          <img 
                            src={`${BASE_URL}${usr.profile_picture_url}`} 
                            alt={usr.name}
                            onError={(e) => {
                              e.currentTarget.src = '';
                            }} 
                          />
                        ) : (
                          <span>{usr.name.substring(0, 2)}</span>
                        )}
                      </div>
                      <div className="user-details">
                        <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                          <h4>{usr.name}</h4>
                          {usr.is_blocked && (
                            <span className="status-chip rejected" style={{ fontSize: '9px', padding: '2px 6px', margin: '0' }}>
                              مسدود شده
                            </span>
                          )}
                        </div>
                      </div>
                    </div>
                  </td>
                  <td style={{ direction: 'ltr' }}>{usr.phone_number}</td>
                  <td>
                    <span className={`status-chip ${usr.role === 'WELDER' ? 'pending' : 'approved'}`} style={{ fontSize: '11px' }}>
                      {usr.role === 'WELDER' ? 'جوشکار' : 'کارفرما'}
                    </span>
                  </td>
                  <td>
                    {usr.province || usr.city ? `${usr.province || ''}، ${usr.city || ''}` : 'نامشخص'}
                  </td>
                  <td>
                    <div style={{ display: 'flex', gap: '4px' }}>
                      {(usr.roles || []).map((r: string) => (
                        <span key={r} style={{ fontSize: '10px', padding: '2px 6px', borderRadius: '4px', backgroundColor: 'var(--bg-dark)', border: '1px solid var(--border)', color: 'var(--text-secondary)' }}>
                          {r === 'WELDER' ? 'جوشکار' : 'کارفرما'}
                        </span>
                      ))}
                    </div>
                  </td>
                  <td>
                    {new Date(usr.created_at).toLocaleDateString('fa-IR')}
                  </td>
                  <td>
                    <div style={{ display: 'flex', gap: '6px', flexWrap: 'wrap' }}>
                      <button 
                        className="btn btn-secondary" 
                        style={{ fontSize: '11px', padding: '6px 12px', borderRadius: '8px' }}
                        onClick={() => setSelectedUserId(usr.id)}
                      >
                        مشاهده سابقه
                      </button>
                      <button 
                        className={`btn ${usr.is_blocked ? 'btn-success' : 'btn-danger'}`}
                        style={{ fontSize: '11px', padding: '6px 12px', borderRadius: '8px' }}
                        onClick={() => onToggleBlockUser(usr.id, !usr.is_blocked)}
                      >
                        {usr.is_blocked ? 'رفع مسدودیت' : 'مسدود کردن'}
                      </button>
                      <button 
                        className="btn btn-danger" 
                        style={{ fontSize: '11px', padding: '6px 12px', borderRadius: '8px', border: '1px dashed var(--danger)' }}
                        onClick={() => {
                          if (window.confirm('آیا از حذف کامل این کاربر به همراه تمامی استعلام‌ها و پیشنهادهای مربوطه اطمینان دارید؟ این عمل غیرقابل بازگشت است.')) {
                            onDeleteUser(usr.id);
                          }
                        }}
                      >
                        حذف کامل
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {selectedUserId && (
        <ViewUserHistoryModal 
          userId={selectedUserId} 
          onClose={() => setSelectedUserId(null)} 
        />
      )}
    </div>
  );
}
