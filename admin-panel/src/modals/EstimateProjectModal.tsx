import { useState } from 'react';
import { BASE_URL } from '../api';
import { Inquiry, InquiryItem } from '../types';

interface EstimateProjectModalProps {
  inquiry: Inquiry;
  onClose: () => void;
  onSubmitEstimation: (inqId: string, items: InquiryItem[]) => Promise<void>;
  onRejectInquiry: (inqId: string, reason: string) => Promise<void>;
}

export default function EstimateProjectModal({
  inquiry,
  onClose,
  onSubmitEstimation,
  onRejectInquiry,
}: EstimateProjectModalProps) {
  const [estimationItems, setEstimationItems] = useState<InquiryItem[]>(
    inquiry.items && inquiry.items.length > 0
      ? inquiry.items
      : [{ title: '', unit: 'متر', quantity: 1, price: 0 }]
  );
  
  const [showRejectionForm, setShowRejectionForm] = useState(false);
  const [rejectionReason, setRejectionReason] = useState('');

  const addEstimationRow = () => {
    setEstimationItems(prev => [...prev, { title: '', unit: 'متر', quantity: 1, price: 0 }]);
  };

  const removeEstimationRow = (index: number) => {
    if (estimationItems.length === 1) return;
    setEstimationItems(prev => prev.filter((_, i) => i !== index));
  };

  const handleEstimationRowChange = (index: number, field: keyof InquiryItem, value: any) => {
    setEstimationItems(prev => prev.map((item, i) => {
      if (i === index) {
        return { ...item, [field]: value };
      }
      return item;
    }));
  };

  const handleApprove = () => {
    onSubmitEstimation(inquiry.id, estimationItems);
  };

  const handleReject = () => {
    onRejectInquiry(inquiry.id, rejectionReason);
  };

  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal-content" style={{ maxWidth: '780px' }} onClick={(e) => e.stopPropagation()}>
        <div className="modal-header">
          <h3>کارشناسی نقشه و استخراج اقلام فنی پروژه</h3>
          <button className="modal-close" onClick={onClose}>&times;</button>
        </div>

        <div style={{ display: 'grid', gridTemplateColumns: '1.2fr 1fr', gap: '20px', marginBottom: '20px' }}>
          {/* Left Column: Blueprint Viewer */}
          <div>
            <h4 style={{ fontSize: '13px', color: 'var(--text-secondary)', marginBottom: '8px' }}>فایل نقشه پروژه (Blueprint)</h4>
            {inquiry.has_blueprint ? (
              <div style={{ position: 'relative', height: '220px', borderRadius: '12px', overflow: 'hidden', border: '1px solid var(--border)' }}>
                <img 
                  src={inquiry.blueprint_url ? `${BASE_URL}${inquiry.blueprint_url}` : ''} 
                  alt="Project Blueprint" 
                  style={{ width: '100%', height: '100%', objectFit: 'cover' }}
                  onError={(e) => {
                    if (inquiry.blueprint_url) e.currentTarget.src = inquiry.blueprint_url;
                  }}
                />
                <a 
                  href={inquiry.blueprint_url ? `${BASE_URL}${inquiry.blueprint_url}` : '#'} 
                  target="_blank" 
                  rel="noreferrer"
                  style={{ position: 'absolute', bottom: '12px', left: '12px', backgroundColor: 'rgba(0,0,0,0.7)', color: 'white', padding: '4px 10px', borderRadius: '6px', fontSize: '11px', textDecoration: 'none' }}
                >
                  مشاهده سایز اصلی
                </a>
              </div>
            ) : (
              <div style={{ height: '220px', borderRadius: '12px', backgroundColor: 'rgba(0,0,0,0.01)', border: '1px dashed var(--border)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'var(--text-secondary)' }}>
                بدون نقشه ارسالی (اقلام دستی)
              </div>
            )}
          </div>

          {/* Right Column: Project details */}
          <div style={{ display: 'flex', flexDirection: 'column', gap: '10px' }}>
            <h4 style={{ fontSize: '14px', fontWeight: 'bold' }}>{inquiry.title}</h4>
            <p style={{ fontSize: '12px', color: 'var(--text-secondary)' }}>
              کارفرما: <strong>{inquiry.employer_name || 'کارفرما'}</strong>
            </p>
            <p style={{ fontSize: '12px', color: 'var(--text-secondary)' }}>
              موقعیت: <strong>{inquiry.province}، {inquiry.city}</strong>
            </p>
            <div style={{ flex: 1, overflowY: 'auto', maxHeight: '120px', backgroundColor: 'rgba(0,0,0,0.01)', padding: '10px', borderRadius: '8px', border: '1px solid var(--border)' }}>
              <p style={{ fontSize: '12px', color: 'var(--text-secondary)', lineHeight: '1.6' }}>
                توضیحات پروژه: <span style={{ color: 'var(--text-primary)' }}>{inquiry.description}</span>
              </p>
            </div>
          </div>
        </div>

        {/* Technical items rows */}
        <div style={{ borderTop: '1px solid var(--border)', paddingTop: '16px', marginBottom: '20px' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '12px' }}>
            <h4 style={{ fontSize: '14px', fontWeight: 'bold' }}>آیتم‌های فنی استخراج شده</h4>
            <button className="btn btn-secondary" style={{ padding: '4px 10px', fontSize: '11px' }} onClick={addEstimationRow}>
              + افزودن ردیف جدید
            </button>
          </div>

          <div style={{ maxHeight: '200px', overflowY: 'auto', paddingLeft: '4px' }}>
            {estimationItems.map((item, idx) => (
              <div key={idx} className="est-item-row">
                <input 
                  type="text" 
                  className="input-control" 
                  placeholder="عنوان قلم (مثال: جوش لوله ۲ اینچ)"
                  value={item.title}
                  onChange={(e) => handleEstimationRowChange(idx, 'title', e.target.value)}
                />
                
                <select 
                  className="input-control"
                  value={item.unit}
                  onChange={(e) => handleEstimationRowChange(idx, 'unit', e.target.value)}
                  style={{ padding: '8px' }}
                >
                  <option value="متر">متر</option>
                  <option value="عدد">عدد</option>
                  <option value="کیلوگرم">کیلوگرم</option>
                  <option value="شاخه">شاخه</option>
                </select>

                <input 
                  type="number" 
                  className="input-control" 
                  placeholder="تعداد"
                  min="1"
                  value={item.quantity}
                  onChange={(e) => handleEstimationRowChange(idx, 'quantity', parseInt(e.target.value) || 1)}
                />

                <button 
                  className="btn btn-danger" 
                  style={{ padding: '8px 12px' }}
                  onClick={() => removeEstimationRow(idx)}
                  disabled={estimationItems.length === 1}
                >
                  حذف
                </button>
              </div>
            ))}
          </div>
        </div>

        {/* Modal actions */}
        <div style={{ borderTop: '1px solid var(--border)', paddingTop: '16px', marginTop: '16px' }}>
          {showRejectionForm ? (
            <div style={{ animation: 'fadeIn 0.2s ease-out' }}>
              <div className="form-group" style={{ marginBottom: '12px' }}>
                <label style={{ fontWeight: 'bold', fontSize: '13px', color: 'var(--danger)', display: 'block', marginBottom: '6px' }}>
                  علت رد کردن استعلام پروژه (به کارفرما نمایش داده می‌شود):
                </label>
                <textarea 
                  className="input-control" 
                  style={{ minHeight: '80px', padding: '10px', fontSize: '13px', width: '100%', resize: 'vertical' }}
                  placeholder="مثال: نقشه فنی خوانا نیست یا اطلاعات پروژه نامشخص است."
                  value={rejectionReason}
                  onChange={(e) => setRejectionReason(e.target.value)}
                />
              </div>
              <div style={{ display: 'flex', gap: '12px', justifyContent: 'flex-end' }}>
                <button 
                  className="btn btn-danger" 
                  onClick={handleReject}
                >
                  تایید و ثبت رد استعلام
                </button>
                <button 
                  className="btn btn-secondary" 
                  onClick={() => {
                    setShowRejectionForm(false);
                    setRejectionReason('');
                  }}
                >
                  لغو
                </button>
              </div>
            </div>
          ) : (
            <div style={{ display: 'flex', gap: '12px', justifyContent: 'flex-end' }}>
              <button 
                className="btn btn-primary" 
                onClick={handleApprove}
              >
                تایید فنی و انتشار عمومی پروژه
              </button>
              <button 
                className="btn btn-danger" 
                onClick={() => setShowRejectionForm(true)}
              >
                رد کردن استعلام
              </button>
              <button 
                className="btn btn-secondary" 
                onClick={onClose}
              >
                انصراف
              </button>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
