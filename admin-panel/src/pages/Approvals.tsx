import { BASE_URL } from '../api';

interface ApprovalsProps {
  pendingVerifications: any[];
  onSelectVerification: (user: any) => void;
}

export default function Approvals({
  pendingVerifications,
  onSelectVerification,
}: ApprovalsProps) {
  return (
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
                    {user.pending_url ? (
                      <img 
                        src={`${BASE_URL}${user.pending_url}`} 
                        alt="Pending Preview" 
                        style={{ width: '42px', height: '42px', borderRadius: '8px', objectFit: 'cover', border: '1px solid var(--border)' }}
                        onError={(e) => {
                          e.currentTarget.src = user.pending_url;
                        }}
                      />
                    ) : (
                      <span style={{ color: 'var(--text-secondary)' }}>فاقد فایل</span>
                    )}
                  </td>
                  <td>
                    <button 
                      className="btn btn-secondary" 
                      onClick={() => onSelectVerification(user)}
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
  );
}
