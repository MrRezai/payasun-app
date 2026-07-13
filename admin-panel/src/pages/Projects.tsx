import { useState } from 'react';
import { Inquiry } from '../types';

interface ProjectsProps {
  inquiries: Inquiry[];
  onEstimateClick: (inq: Inquiry) => void;
  onViewDetailClick: (inq: Inquiry) => void;
}

export default function Projects({ inquiries, onEstimateClick, onViewDetailClick }: ProjectsProps) {
  const [projectSubTab, setProjectSubTab] = useState<'pending' | 'broadcasted' | 'closed'>('pending');

  const pendingCount = inquiries.filter(i => i.status === 'PENDING_ESTIMATION' || i.status === 'ESTIMATED').length;
  const broadcastedCount = inquiries.filter(i => i.status === 'BROADCASTED').length;
  const closedCount = inquiries.filter(i => i.status === 'CLOSED' || i.status === 'EXPIRED' || i.status === 'REJECTED').length;

  const getSubTabInquiries = () => {
    if (projectSubTab === 'pending') {
      return inquiries.filter(i => i.status === 'PENDING_ESTIMATION' || i.status === 'ESTIMATED');
    } else if (projectSubTab === 'broadcasted') {
      return inquiries.filter(i => i.status === 'BROADCASTED');
    } else {
      return inquiries.filter(i => i.status === 'CLOSED' || i.status === 'EXPIRED' || i.status === 'REJECTED');
    }
  };

  const filteredInquiries = getSubTabInquiries();

  return (
    <div className="glass-card" style={{ animation: 'fadeIn 0.3s ease-out' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '20px', borderBottom: '1px solid var(--border)', paddingBottom: '12px' }}>
        <h3 style={{ fontSize: '16px', fontWeight: '700' }}>مدیریت استعلام‌ها و پروژه‌های پلتفرم</h3>
        <span style={{ fontSize: '13px', color: 'var(--text-secondary)' }}>تعداد استعلام‌های این بخش: {filteredInquiries.length} پروژه</span>
      </div>

      {/* Sub-tab Navigation Bar */}
      <div style={{ display: 'flex', gap: '8px', marginBottom: '20px', backgroundColor: 'var(--bg-dark)', padding: '6px', borderRadius: '8px', border: '1px solid var(--border)', width: 'fit-content' }}>
        <button 
          className={`btn ${projectSubTab === 'pending' ? 'btn-primary' : 'btn-secondary'}`}
          style={{ padding: '6px 16px', fontSize: '12px', border: 'none' }}
          onClick={() => setProjectSubTab('pending')}
        >
          در انتظار تایید ادمین یا کارفرما ({pendingCount})
        </button>
        <button 
          className={`btn ${projectSubTab === 'broadcasted' ? 'btn-primary' : 'btn-secondary'}`}
          style={{ padding: '6px 16px', fontSize: '12px', border: 'none' }}
          onClick={() => setProjectSubTab('broadcasted')}
        >
          انتشار یافته‌ها ({broadcastedCount})
        </button>
        <button 
          className={`btn ${projectSubTab === 'closed' ? 'btn-primary' : 'btn-secondary'}`}
          style={{ padding: '6px 16px', fontSize: '12px', border: 'none' }}
          onClick={() => setProjectSubTab('closed')}
        >
          اتمام یافته و رد شده ({closedCount})
        </button>
      </div>

      {/* Inquiries Table */}
      {filteredInquiries.length === 0 ? (
        <div style={{ padding: '50px 0', textAlign: 'center', color: 'var(--text-secondary)' }}>
          <svg fill="none" viewBox="0 0 24 24" stroke="currentColor" width="48" height="48" style={{ marginBottom: '12px', opacity: 0.4 }}>
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M20 13V6a2 2 0 00-2-2H6a2 2 0 00-2 2v7m16 0a2 2 0 01-2 2H6a2 2 0 01-2-2m16 0V9a2 2 0 00-2-2M6 20h12a2 2 0 002-2v-5M6 20v-5a2 2 0 012-2h8a2 2 0 012 2v5" />
          </svg>
          <p>هیچ پروژه‌ای در این بخش یافت نشد.</p>
        </div>
      ) : (
        <div className="table-responsive">
          <table className="custom-table">
            <thead>
              <tr>
                <th>عنوان پروژه</th>
                <th>کارفرما</th>
                <th>محدوده جغرافیایی</th>
                <th>نوع نقشه</th>
                <th>تعداد اقلام فنی</th>
                <th>وضعیت فنی</th>
                <th style={{ textAlign: 'left' }}>عملیات</th>
              </tr>
            </thead>
            <tbody>
              {filteredInquiries.map((inq) => {
                const itemsCount = inq.items ? inq.items.length : 0;
                return (
                  <tr key={inq.id}>
                    <td style={{ fontWeight: 'bold' }}>{inq.title}</td>
                    <td>{inq.employer_name || 'کارفرمای پلتفرم'}</td>
                    <td>{inq.province || 'نامشخص'}، {inq.city || 'نامشخص'}</td>
                    <td>
                      {inq.has_blueprint ? (
                        <span style={{ color: 'var(--primary)', fontWeight: 'bold', fontSize: '12px' }}>فایل نقشه فنی</span>
                      ) : (
                        <span style={{ color: 'var(--text-secondary)', fontSize: '12px' }}>ورود اطلاعات دستی</span>
                      )}
                    </td>
                    <td>
                      <span style={{ fontWeight: 'bold' }}>{itemsCount} ردیف</span>
                    </td>
                    <td>
                      {inq.status === 'PENDING_ESTIMATION' && <span className="status-chip pending">در انتظار کارشناسی</span>}
                      {inq.status === 'ESTIMATED' && <span className="status-chip warning" style={{ backgroundColor: 'rgba(245,158,11,0.15)', color: 'var(--secondary)' }}>کارشناسی‌شده (تایید کارفرما)</span>}
                      {inq.status === 'BROADCASTED' && <span className="status-chip approved">انتشار یافته</span>}
                      {inq.status === 'REJECTED' && <span className="status-chip danger" style={{ backgroundColor: 'rgba(239,68,68,0.15)', color: 'var(--danger)' }}>رد شده</span>}
                      {(inq.status === 'CLOSED' || inq.status === 'EXPIRED') && <span className="status-chip" style={{ backgroundColor: 'rgba(0,0,0,0.06)', color: 'var(--text-secondary)' }}>خاتمه‌یافته</span>}
                    </td>
                    <td style={{ textAlign: 'left' }}>
                      {inq.status === 'PENDING_ESTIMATION' ? (
                        <button 
                          className="btn btn-primary" 
                          style={{ padding: '6px 12px', fontSize: '11px' }}
                          onClick={() => onEstimateClick(inq)}
                        >
                          افزودن اقلام و تایید انتشار
                        </button>
                      ) : (
                        <button 
                          className="btn btn-secondary" 
                          style={{ padding: '6px 12px', fontSize: '11px' }}
                          onClick={() => onViewDetailClick(inq)}
                        >
                          مشاهده اقلام فنی
                        </button>
                      )}
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
