import { BASE_URL } from '../api';

interface VerifyPictureModalProps {
  user: any;
  onClose: () => void;
  onVerify: (userId: string, role: 'WELDER' | 'EMPLOYER', approve: boolean) => void;
}

export default function VerifyPictureModal({ user, onClose, onVerify }: VerifyPictureModalProps) {
  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal-content" onClick={(e) => e.stopPropagation()}>
        <div className="modal-header">
          <h3>بررسی تصویر ارسالی جهت احراز هویت</h3>
          <button className="modal-close" onClick={onClose}>&times;</button>
        </div>
        
        <div style={{ textAlign: 'center', marginBottom: '20px' }}>
          {user.pending_url ? (
            <img 
              src={`${BASE_URL}${user.pending_url}`} 
              alt="Enlarged User Profile" 
              style={{ width: '220px', height: '220px', borderRadius: '16px', objectFit: 'cover', border: '2px solid var(--border)', boxShadow: '0 8px 24px rgba(0,0,0,0.1)' }}
              onError={(e) => {
                e.currentTarget.src = user.pending_url;
              }}
            />
          ) : (
            <div style={{ padding: '40px', backgroundColor: 'var(--bg-dark)', borderRadius: '12px' }}>فاقد تصویر ارسالی</div>
          )}
        </div>

        <div style={{ marginBottom: '24px', backgroundColor: 'rgba(0,0,0,0.02)', padding: '14px', borderRadius: '8px', border: '1px solid var(--border)' }}>
          <p style={{ fontSize: '13px', color: 'var(--text-secondary)', marginBottom: '8px' }}>
            کاربر: <strong style={{ color: 'var(--text-primary)' }}>{user.name}</strong> ({user.role === 'WELDER' ? 'جوشکار' : 'کارفرما'})
          </p>
          <p style={{ fontSize: '13px', color: 'var(--text-secondary)' }}>
            بیوگرافی/توضیحات: <span style={{ color: 'var(--text-primary)', fontStyle: 'italic' }}>{user.bio || 'توضیحاتی وارد نشده است.'}</span>
          </p>
        </div>

        <div style={{ display: 'flex', gap: '12px', justifyContent: 'flex-end' }}>
          <button 
            className="btn btn-success" 
            onClick={() => onVerify(user.id, user.role, true)}
          >
            تایید تصویر و انتشار در اپ
          </button>
          <button 
            className="btn btn-danger" 
            onClick={() => onVerify(user.id, user.role, false)}
          >
            رد تصویر
          </button>
          <button 
            className="btn btn-secondary" 
            onClick={onClose}
          >
            بستن
          </button>
        </div>
      </div>
    </div>
  );
}
