import { useState } from 'react';
import { BASE_URL } from '../api';

interface VerifyPictureModalProps {
  user: any;
  onClose: () => void;
  onVerify: (userId: string, role: 'WELDER' | 'EMPLOYER', approve: boolean) => void;
}

export default function VerifyPictureModal({ user, onClose, onVerify }: VerifyPictureModalProps) {
  const [confirmAction, setConfirmAction] = useState<boolean | null>(null);

  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal-content" onClick={(e) => e.stopPropagation()}>
        <div className="modal-header">
          <h3>بررسی تصویر ارسالی جهت احراز هویت</h3>
          <button className="modal-close" onClick={onClose}>&times;</button>
        </div>

        {confirmAction !== null ? (
          <div style={{ animation: 'fadeIn 0.2s ease-out', padding: '12px 0' }}>
            <div style={{ 
              backgroundColor: confirmAction ? 'rgba(16, 185, 129, 0.08)' : 'rgba(239, 68, 68, 0.08)', 
              border: `1px solid ${confirmAction ? 'rgba(16, 185, 129, 0.3)' : 'rgba(239, 68, 68, 0.3)'}`, 
              padding: '16px', 
              borderRadius: '12px', 
              marginBottom: '20px' 
            }}>
              <h4 style={{ fontSize: '15px', color: confirmAction ? 'var(--success)' : 'var(--danger)', fontWeight: 'bold', marginBottom: '8px' }}>
                {confirmAction ? 'تایید نهایی تصویر پروفایل' : 'رد نهایی تصویر پروفایل'}
              </h4>
              <p style={{ fontSize: '13px', color: 'var(--text-primary)', lineHeight: '1.6' }}>
                {confirmAction 
                  ? `آیا از تایید تصویر پروفایل کاربر «${user.name}» اطمینان دارید؟ تصویر جدید پس از تایید در اپلیکیشن فعال و به سایر کاربران نمایش داده خواهد شد.`
                  : `آیا از رد تصویر پروفایل کاربر «${user.name}» اطمینان دارید؟ تصویر ارسالی حذف گردیده و کاربر به حالت تعلیق تصویر باقی خواهد ماند.`}
              </p>
            </div>
            <div style={{ display: 'flex', gap: '12px', justifyContent: 'flex-end' }}>
              <button 
                className={`btn ${confirmAction ? 'btn-success' : 'btn-danger'}`}
                style={{ padding: '10px 20px', fontWeight: 'bold' }}
                onClick={() => onVerify(user.id, user.role, confirmAction)}
              >
                {confirmAction ? 'تایید قطعی و ثبت انتشار' : 'ثبت قطعی رد تصویر'}
              </button>
              <button 
                className="btn btn-secondary"
                onClick={() => setConfirmAction(null)}
              >
                انصراف و بازگشت
              </button>
            </div>
          </div>
        ) : (
          <>
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

            <div style={{ display: 'flex', gap: '12px', justifyContent: 'flex-end', flexWrap: 'wrap' }}>
              <button 
                className="btn btn-success" 
                onClick={() => setConfirmAction(true)}
              >
                تایید تصویر و انتشار در اپ
              </button>
              <button 
                className="btn btn-danger" 
                onClick={() => setConfirmAction(false)}
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
          </>
        )}
      </div>
    </div>
  );
}
