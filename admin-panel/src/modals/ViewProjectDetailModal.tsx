import { useState } from 'react';
import { BASE_URL } from '../api';
import { Inquiry } from '../types';

interface ViewProjectDetailModalProps {
  inquiry: Inquiry;
  onClose: () => void;
  onRejectInquiry?: (id: string, reason: string) => Promise<void>;
  onDeleteInquiry?: (id: string) => Promise<void>;
  onToggleOfferVisibility?: (offerId: string, isHidden: boolean) => Promise<void>;
}

export default function ViewProjectDetailModal({ 
  inquiry, 
  onClose,
  onRejectInquiry,
  onDeleteInquiry,
  onToggleOfferVisibility
}: ViewProjectDetailModalProps) {
  const [showRejectionForm, setShowRejectionForm] = useState(false);
  const [rejectionReason, setRejectionReason] = useState('');
  const [isActionLoading, setIsActionLoading] = useState(false);

  const handleReject = async () => {
    if (!rejectionReason.trim()) return;
    if (onRejectInquiry) {
      setIsActionLoading(true);
      try {
        await onRejectInquiry(inquiry.id, rejectionReason.trim());
        setShowRejectionForm(false);
        setRejectionReason('');
      } catch (e) {
        // Handled in parent
      } finally {
        setIsActionLoading(false);
      }
    }
  };

  const handleDelete = async () => {
    if (window.confirm('آیا از حذف کامل و برگشت‌ناپذیر این پروژه اطمینان دارید؟')) {
      if (onDeleteInquiry) {
        setIsActionLoading(true);
        try {
          await onDeleteInquiry(inquiry.id);
        } catch (e) {
          // Handled in parent
        } finally {
          setIsActionLoading(false);
        }
      }
    }
  };

  const getStatusText = (status: string) => {
    switch (status) {
      case 'DRAFT': return 'پیش‌نویس';
      case 'PENDING_ESTIMATION': return 'در انتظار برآورد';
      case 'ESTIMATED': return 'برآورد شده';
      case 'BROADCASTED': return 'منتشر شده';
      case 'REJECTED': return 'رد شده توسط ادمین';
      default: return status;
    }
  };

  const offers = inquiry.offers || [];

  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal-content" style={{ maxWidth: '820px', width: '95vw', maxHeight: '90vh', overflowY: 'auto' }} onClick={(e) => e.stopPropagation()}>
        <div className="modal-header">
          <h3>مشاهده جزئیات فنی و اقلام استخراج شده</h3>
          <button className="modal-close" onClick={onClose} disabled={isActionLoading}>&times;</button>
        </div>

        <div style={{ display: 'grid', gridTemplateColumns: '1.2fr 1fr', gap: '20px', marginBottom: '20px' }}>
          <div>
            <h4 style={{ fontSize: '13px', color: 'var(--text-secondary)', marginBottom: '8px' }}>نقشه فنی پروژه</h4>
            {inquiry.has_blueprint ? (() => {
              const isPdf = inquiry.blueprint_url?.toLowerCase().endsWith('.pdf');
              const fileUrl = inquiry.blueprint_url 
                ? (inquiry.blueprint_url.startsWith('http') ? inquiry.blueprint_url : `${BASE_URL}${inquiry.blueprint_url}`)
                : '';
              
              if (isPdf) {
                return (
                  <div style={{ 
                    height: '180px', 
                    borderRadius: '12px', 
                    border: '1px solid var(--border)', 
                    display: 'flex', 
                    flexDirection: 'column',
                    alignItems: 'center', 
                    justifyContent: 'center', 
                    backgroundColor: 'rgba(0,0,0,0.02)', 
                    padding: '16px',
                    textAlign: 'center'
                  }}>
                    <svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="#e74c3c" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" style={{ marginBottom: '10px' }}>
                      <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path>
                      <polyline points="14 2 14 8 20 8"></polyline>
                      <line x1="16" y1="13" x2="8" y2="13"></line>
                      <line x1="16" y1="17" x2="8" y2="17"></line>
                      <polyline points="10 9 9 9 8 9"></polyline>
                    </svg>
                    <span style={{ fontSize: '11px', fontWeight: 'bold', marginBottom: '8px', color: 'var(--text-primary)' }}>فایل نقشه فنی PDF است</span>
                    <a 
                      href={fileUrl} 
                      target="_blank" 
                      rel="noreferrer"
                      style={{ padding: '4px 12px', fontSize: '11px', textDecoration: 'none', backgroundColor: '#e74c3c', color: 'white', borderRadius: '6px', fontWeight: 'bold' }}
                    >
                      دانلود و مشاهده PDF
                    </a>
                  </div>
                );
              }

              return (
                <div style={{ height: '180px', borderRadius: '12px', overflow: 'hidden', border: '1px solid var(--border)' }}>
                  <img 
                    src={fileUrl} 
                    alt="Project Blueprint" 
                    style={{ width: '100%', height: '100%', objectFit: 'cover' }}
                    onError={(e) => {
                      e.currentTarget.onerror = null;
                      if (inquiry.blueprint_url && !inquiry.blueprint_url.startsWith('http')) {
                        e.currentTarget.src = inquiry.blueprint_url;
                      }
                    }}
                  />
                </div>
              );
            })() : (
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
              وضعیت فعلی: <strong style={{ color: inquiry.status === 'BROADCASTED' ? 'var(--success)' : inquiry.status === 'REJECTED' ? 'var(--danger)' : 'var(--secondary)' }}>
                {getStatusText(inquiry.status)}
              </strong>
            </p>
            <div style={{ flex: 1, overflowY: 'auto', maxHeight: '100px', backgroundColor: 'rgba(0,0,0,0.01)', padding: '10px', borderRadius: '8px', border: '1px solid var(--border)' }}>
              <p style={{ fontSize: '12px', color: 'var(--text-secondary)', lineHeight: '1.6' }}>
                توضیحات: <span style={{ color: 'var(--text-primary)' }}>{inquiry.description}</span>
              </p>
            </div>
          </div>
        </div>

        {/* Rejection Reason inside Modal if rejected */}
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

        {/* Welder Bids Section */}
        <div style={{ borderTop: '1px solid var(--border)', paddingTop: '16px', marginTop: '16px' }}>
          <h4 style={{ fontSize: '14px', fontWeight: 'bold', marginBottom: '12px', color: 'var(--primary)' }}>پیشنهادهای دستمزد جوشکاران</h4>
          
          {offers.length === 0 ? (
            <div style={{ padding: '20px 0', textAlign: 'center', color: 'var(--text-secondary)', fontSize: '12px' }}>هنوز هیچ جوشکاری پیشنهادی روی این پروژه ثبت نکرده است.</div>
          ) : (
            <div style={{ display: 'flex', flexDirection: 'column', gap: '12px', maxHeight: '320px', overflowY: 'auto', paddingLeft: '4px' }}>
              {offers.map((off: any) => (
                <div key={off.id} style={{ padding: '12px', backgroundColor: 'var(--bg-dark)', borderRadius: '8px', border: '1px solid var(--border)', display: 'flex', flexDirection: 'column', gap: '8px' }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                    <div>
                      <strong style={{ fontSize: '13px' }}>{off.welder_name}</strong>
                      {off.welder_phone && (
                        <span style={{ fontSize: '11px', color: 'var(--text-secondary)', marginRight: '8px', direction: 'ltr', display: 'inline-block' }}>({off.welder_phone})</span>
                      )}
                    </div>
                    <div style={{ display: 'flex', gap: '8px', alignItems: 'center' }}>
                      {off.is_hidden && (
                        <span className="status-chip danger" style={{ fontSize: '9px', padding: '2px 6px', backgroundColor: 'rgba(239,68,68,0.12)', color: 'var(--danger)' }}>پنهان شده از کارفرما</span>
                      )}
                      <strong style={{ color: 'var(--success)', fontSize: '13px' }}>{off.total_price.toLocaleString('fa-IR')} تومان</strong>
                    </div>
                  </div>

                  {/* Per-item rates breakdown */}
                  {off.items_prices && off.items_prices.length > 0 && (
                    <div style={{ padding: '8px', backgroundColor: 'rgba(0,0,0,0.02)', borderRadius: '6px', border: '1px solid var(--border)', marginTop: '4px' }}>
                      <div style={{ fontWeight: '600', marginBottom: '6px', fontSize: '10px', color: 'var(--text-secondary)' }}>ریز قیمت پیشنهادی هر آیتم:</div>
                      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '8px' }}>
                        {off.items_prices.map((item: any, idx: number) => (
                          <div key={idx} style={{ display: 'flex', justifyContent: 'space-between', fontSize: '10px', padding: '2px 0', borderBottom: '1px dashed var(--border)' }}>
                            <span style={{ color: 'var(--text-secondary)' }}>{item.title}</span>
                            <strong style={{ color: 'var(--text-primary)' }}>{item.price.toLocaleString('fa-IR')} تومان</strong>
                          </div>
                        ))}
                      </div>
                    </div>
                  )}

                  {/* Selected Conditions */}
                  <div style={{ display: 'flex', gap: '8px', flexWrap: 'wrap', fontSize: '10px', color: 'var(--text-secondary)', marginTop: '2px' }}>
                    <strong>تعهدات جوشکار:</strong>
                    {off.scaffold_checked && <span style={{ backgroundColor: 'var(--bg-card)', padding: '1px 4px', borderRadius: '2px', border: '1px solid var(--border)' }}>داربست</span>}
                    {off.power_checked && <span style={{ backgroundColor: 'var(--bg-card)', padding: '1px 4px', borderRadius: '2px', border: '1px solid var(--border)' }}>برق</span>}
                    {off.rod_checked && <span style={{ backgroundColor: 'var(--bg-card)', padding: '1px 4px', borderRadius: '2px', border: '1px solid var(--border)' }}>الکترود</span>}
                    {off.delivery_checked && <span style={{ backgroundColor: 'var(--bg-card)', padding: '1px 4px', borderRadius: '2px', border: '1px solid var(--border)' }}>حمل</span>}
                  </div>

                  {/* Hide/Unhide visibility Toggle */}
                  {onToggleOfferVisibility && (
                    <div style={{ display: 'flex', justifyContent: 'flex-end', marginTop: '4px' }}>
                      <button 
                        className={`btn ${off.is_hidden ? 'btn-primary' : 'btn-secondary'}`}
                        style={{ padding: '4px 10px', fontSize: '10px', height: 'auto', border: 'none' }}
                        onClick={() => onToggleOfferVisibility(off.id, !off.is_hidden)}
                        disabled={isActionLoading}
                      >
                        {off.is_hidden ? 'نمایش مجدد پیشنهاد برای کارفرما' : 'پنهان کردن پیشنهاد از کارفرما'}
                      </button>
                    </div>
                  )}
                </div>
              ))}
            </div>
          )}
        </div>

        {/* Action Panel for de-listing / rejection reason */}
        {showRejectionForm && (
          <div style={{ width: '100%', borderTop: '1px solid var(--border)', paddingTop: '16px', marginTop: '16px' }}>
            <label style={{ display: 'block', fontSize: '12px', fontWeight: 'bold', marginBottom: '8px' }}>دلیل دی‌لیست کردن و بازگشت به ویرایش کارفرما را بنویسید:</label>
            <textarea 
              className="input-control" 
              rows={3} 
              placeholder="مثال: این پروژه نیاز به بازبینی و اصلاح آدرس دارد."
              value={rejectionReason}
              onChange={(e) => setRejectionReason(e.target.value)}
              style={{ resize: 'vertical', fontSize: '12px' }}
              disabled={isActionLoading}
            />
            <div style={{ display: 'flex', gap: '8px', justifyContent: 'flex-end', marginTop: '12px' }}>
              <button 
                className="btn btn-danger" 
                style={{ fontSize: '11px', padding: '6px 12px' }} 
                onClick={handleReject}
                disabled={isActionLoading || !rejectionReason.trim()}
              >
                تایید دی‌لیست
              </button>
              <button 
                className="btn btn-secondary" 
                style={{ fontSize: '11px', padding: '6px 12px' }} 
                onClick={() => { setShowRejectionForm(false); setRejectionReason(''); }}
                disabled={isActionLoading}
              >
                انصراف
              </button>
            </div>
          </div>
        )}

        {/* Footer Actions (De-list, Delete, Close) */}
        {!showRejectionForm && (
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginTop: '24px', borderTop: '1px solid var(--border)', paddingTop: '16px' }}>
            <div style={{ display: 'flex', gap: '10px' }}>
              {inquiry.status !== 'REJECTED' && (inquiry.status as string) !== 'DRAFT' && onRejectInquiry && (
                <button 
                  className="btn btn-danger" 
                  style={{ backgroundColor: 'rgba(239, 68, 68, 0.1)', color: 'var(--danger)', border: '1px solid var(--danger)', padding: '6px 12px', fontSize: '11px' }}
                  onClick={() => setShowRejectionForm(true)}
                  disabled={isActionLoading}
                >
                  دی‌لیست کردن پروژه (عدم تایید)
                </button>
              )}
              {onDeleteInquiry && (
                <button 
                  className="btn btn-danger" 
                  style={{ padding: '6px 12px', fontSize: '11px' }}
                  onClick={handleDelete}
                  disabled={isActionLoading}
                >
                  حذف کامل پروژه
                </button>
              )}
            </div>
            <button className="btn btn-secondary" onClick={onClose} disabled={isActionLoading}>بستن پنجره</button>
          </div>
        )}
      </div>
    </div>
  );
}
