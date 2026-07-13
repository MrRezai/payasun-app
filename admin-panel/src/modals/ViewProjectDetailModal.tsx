import { BASE_URL } from '../api';
import { Inquiry } from '../types';

interface ViewProjectDetailModalProps {
  inquiry: Inquiry;
  onClose: () => void;
}

export default function ViewProjectDetailModal({ inquiry, onClose }: ViewProjectDetailModalProps) {
  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal-content" style={{ maxWidth: '780px' }} onClick={(e) => e.stopPropagation()}>
        <div className="modal-header">
          <h3>مشاهده جزئیات فنی و اقلام استخراج شده</h3>
          <button className="modal-close" onClick={onClose}>&times;</button>
        </div>

        <div style={{ display: 'grid', gridTemplateColumns: '1.2fr 1fr', gap: '20px', marginBottom: '20px' }}>
          <div>
            <h4 style={{ fontSize: '13px', color: 'var(--text-secondary)', marginBottom: '8px' }}>نقشه فنی پروژه</h4>
            {inquiry.has_blueprint ? (
              <div style={{ height: '180px', borderRadius: '12px', overflow: 'hidden', border: '1px solid var(--border)' }}>
                <img 
                  src={inquiry.blueprint_url ? `${BASE_URL}${inquiry.blueprint_url}` : ''} 
                  alt="Project Blueprint" 
                  style={{ width: '100%', height: '100%', objectFit: 'cover' }}
                  onError={(e) => {
                    if (inquiry.blueprint_url) e.currentTarget.src = inquiry.blueprint_url;
                  }}
                />
              </div>
            ) : (
              <div style={{ height: '180px', borderRadius: '12px', backgroundColor: 'rgba(0,0,0,0.01)', border: '1px dashed var(--border)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'var(--text-secondary)' }}>
                بدون نقشه فنی (اقلام دستی)
              </div>
            )}
          </div>

          <div style={{ display: 'flex', flexDirection: 'column', gap: '10px' }}>
            <h4 style={{ fontSize: '15px', fontWeight: 'bold' }}>{inquiry.title}</h4>
            <p style={{ fontSize: '12px', color: 'var(--text-secondary)' }}>
              موقعیت جغرافیایی: <strong>{inquiry.province || 'نامشخص'}، {inquiry.city || 'نامشخص'}</strong>
            </p>
            <p style={{ fontSize: '12px', color: 'var(--text-secondary)' }}>
              وضعیت فعلی: <strong style={{ color: inquiry.status === 'BROADCASTED' ? 'var(--success)' : 'var(--secondary)' }}>
                {inquiry.status === 'BROADCASTED' ? 'منتشرشده در پلتفرم' : inquiry.status === 'REJECTED' ? 'رد شده توسط ادمین' : 'خاتمه‌یافته'}
              </strong>
            </p>
            <div style={{ flex: 1, overflowY: 'auto', maxHeight: '100px', backgroundColor: 'rgba(0,0,0,0.01)', padding: '10px', borderRadius: '8px', border: '1px solid var(--border)' }}>
              <p style={{ fontSize: '12px', color: 'var(--text-secondary)', lineHeight: '1.6' }}>
                توضیحات: <span style={{ color: 'var(--text-primary)' }}>{inquiry.description}</span>
              </p>
            </div>
          </div>
        </div>

        {/* Rejection Reason inside Modal 3 if rejected */}
        {inquiry.status === 'REJECTED' && (
          <div style={{ backgroundColor: 'rgba(239,68,68,0.05)', border: '1px solid rgba(239,68,68,0.2)', padding: '12px', borderRadius: '8px', color: 'var(--danger)', fontSize: '12px', marginBottom: '16px' }}>
            <strong>علت رد پروژه توسط ادمین: </strong>
            <span>{inquiry.rejection_reason || 'دلیلی ثبت نشده است.'}</span>
          </div>
        )}

        {/* Estimation items display */}
        <div style={{ borderTop: '1px solid var(--border)', paddingTop: '16px' }}>
          <h4 style={{ fontSize: '14px', fontWeight: 'bold', marginBottom: '12px' }}>اقلام فنی استخراج شده</h4>
          
          {!inquiry.items || inquiry.items.length === 0 ? (
            <div style={{ padding: '20px 0', textAlign: 'center', color: 'var(--text-secondary)' }}>هیچ قلم کارشناسی ثبت نشده است.</div>
          ) : (
            <div className="table-responsive" style={{ maxHeight: '180px', overflowY: 'auto' }}>
              <table className="custom-table" style={{ fontSize: '12px' }}>
                <thead>
                  <tr>
                    <th>عنوان ردیف فنی</th>
                    <th>واحد سنجش</th>
                    <th style={{ textAlign: 'left' }}>تعداد / مقدار</th>
                  </tr>
                </thead>
                <tbody>
                  {inquiry.items.map((item, idx) => {
                    return (
                      <tr key={item.id || idx}>
                        <td style={{ fontWeight: 'bold' }}>{item.title}</td>
                        <td>{item.unit}</td>
                        <td style={{ textAlign: 'left', fontWeight: 'bold', color: 'var(--primary)' }}>
                          {item.quantity}
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          )}
        </div>

        <div style={{ display: 'flex', justifyContent: 'flex-end', marginTop: '16px' }}>
          <button className="btn btn-secondary" onClick={onClose}>بستن پنجره</button>
        </div>
      </div>
    </div>
  );
}
