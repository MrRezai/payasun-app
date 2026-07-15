import { useEffect, useState } from 'react';
import { ApiClient, BASE_URL } from '../api';

interface ViewUserHistoryModalProps {
  userId: string;
  onClose: () => void;
}

export default function ViewUserHistoryModal({ userId, onClose }: ViewUserHistoryModalProps) {
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [data, setData] = useState<any>(null);

  useEffect(() => {
    ApiClient.getUserHistory(userId)
      .then((history) => {
        setData(history);
        setLoading(false);
      })
      .catch((err) => {
        setError(err.message || 'خطا در دریافت سابقه کاربر.');
        setLoading(false);
      });
  }, [userId]);

  const formatPrice = (price: any) => {
    if (!price) return '۰';
    const num = typeof price === 'string' ? parseInt(price) : price;
    return num.toLocaleString('fa-IR');
  };

  const getStatusText = (status: string) => {
    switch (status) {
      case 'DRAFT': return 'پیش‌نویس';
      case 'PENDING_ESTIMATION': return 'در انتظار برآورد';
      case 'ESTIMATED': return 'برآورد شده';
      case 'BROADCASTED': return 'منتشر شده';
      case 'REJECTED': return 'رد شده';
      default: return status;
    }
  };

  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal-content" onClick={(e) => e.stopPropagation()} style={{ width: '800px', maxWidth: '95vw', maxHeight: '90vh', overflowY: 'auto' }}>
        <div className="modal-header">
          <h3>جزئیات و سابقه کامل کاربر</h3>
          <button className="modal-close" onClick={onClose}>&times;</button>
        </div>

        {loading && (
          <div style={{ padding: '60px 0', textAlign: 'center' }}>
            <div className="loading-spinner" style={{ margin: '0 auto 16px' }}></div>
            <p style={{ color: 'var(--text-secondary)' }}>در حال دریافت اطلاعات سابقه کاربر...</p>
          </div>
        )}

        {error && (
          <div style={{ padding: '30px', textAlign: 'center', color: 'var(--danger)' }}>
            <p>{error}</p>
            <button className="btn btn-secondary" onClick={onClose} style={{ marginTop: '16px' }}>بستن</button>
          </div>
        )}

        {data && !loading && !error && (
          <div>
            {/* Header Profile Section */}
            <div style={{ display: 'flex', gap: '20px', alignItems: 'center', padding: '16px', backgroundColor: 'var(--bg-dark)', borderRadius: '12px', marginBottom: '24px', border: '1px solid var(--border)' }}>
              <div className="avatar" style={{ width: '70px', height: '70px', fontSize: '24px', borderRadius: '50%', backgroundColor: 'var(--primary)', color: 'white', display: 'flex', alignItems: 'center', justifyContent: 'center', overflow: 'hidden' }}>
                {data.user.role === 'WELDER' && data.welderProfile?.profile_picture_url ? (
                  <img src={`${BASE_URL}${data.welderProfile.profile_picture_url}`} alt="" style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
                ) : data.user.role === 'EMPLOYER' && data.employerProfile?.profile_picture_url ? (
                  <img src={`${BASE_URL}${data.employerProfile.profile_picture_url}`} alt="" style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
                ) : (
                  <span>
                    {data.user.role === 'WELDER'
                      ? `${data.welderProfile?.first_name?.[0] || 'ج'}${data.welderProfile?.last_name?.[0] || 'م'}`
                      : `${data.employerProfile?.first_name?.[0] || 'ک'}${data.employerProfile?.last_name?.[0] || 'م'}`}
                  </span>
                )}
              </div>
              <div style={{ flexGrow: 1 }}>
                <h4 style={{ fontSize: '16px', fontWeight: '700', marginBottom: '6px' }}>
                  {data.user.role === 'WELDER'
                    ? `${data.welderProfile?.first_name || ''} ${data.welderProfile?.last_name || ''}`.trim() || 'جوشکار بدون نام'
                    : data.employerProfile?.company_name || `${data.employerProfile?.first_name || ''} ${data.employerProfile?.last_name || ''}`.trim() || 'کارفرما بدون نام'}
                </h4>
                <div style={{ display: 'flex', gap: '8px', alignItems: 'center', flexWrap: 'wrap' }}>
                  <span className="status-chip approved" style={{ fontSize: '10px' }}>
                    {data.user.role === 'WELDER' ? 'نقش: جوشکار' : 'نقش: کارفرما'}
                  </span>
                  <span style={{ fontSize: '12px', color: 'var(--text-secondary)' }}>
                    شماره همراه: <strong style={{ direction: 'ltr', display: 'inline-block' }}>{data.user.phone_number}</strong>
                  </span>
                  <span style={{ fontSize: '12px', color: 'var(--text-secondary)' }}>
                    عضویت: {new Date(data.user.created_at).toLocaleDateString('fa-IR')}
                  </span>
                </div>
              </div>
            </div>

            {/* General & Financial Details */}
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '20px', marginBottom: '24px' }}>
              {/* Profile details */}
              <div className="glass-card" style={{ padding: '16px', margin: 0 }}>
                <h4 style={{ fontSize: '13px', fontWeight: '700', borderBottom: '1px solid var(--border)', paddingBottom: '8px', marginBottom: '12px', color: 'var(--primary)' }}>
                  اطلاعات کاربری و بیوگرافی
                </h4>
                <p style={{ fontSize: '12px', marginBottom: '8px' }}>
                  <strong>شهر محل سکونت:</strong> {data.user.role === 'WELDER' ? (data.welderProfile?.home_province ? `${data.welderProfile.home_province}، ${data.welderProfile.home_city}` : 'نامشخص') : (data.employerProfile?.province ? `${data.employerProfile.province}، ${data.employerProfile.city}` : 'نامشخص')}
                </p>
                {data.user.role === 'WELDER' && (
                  <>
                    <p style={{ fontSize: '12px', marginBottom: '8px' }}>
                      <strong>امتیاز کل جوشکار:</strong> {data.welderProfile?.total_score} ستاره
                    </p>
                    <p style={{ fontSize: '12px', marginBottom: '8px' }}>
                      <strong>پروژه‌های موفق انجام شده:</strong> {data.welderProfile?.completed_jobs_count} پروژه
                    </p>
                    <p style={{ fontSize: '12px', marginBottom: '8px' }}>
                      <strong>محدوده فعالیت:</strong> {data.welderProfile?.active_province ? `${data.welderProfile.active_province} (${data.welderProfile.active_cities?.join('، ')})` : 'نامشخص'}
                    </p>
                    <div style={{ marginTop: '10px' }}>
                      <strong style={{ fontSize: '12px' }}>تخصص‌ها:</strong>
                      <div style={{ display: 'flex', gap: '4px', flexWrap: 'wrap', marginTop: '6px' }}>
                        {data.welderProfile?.skills?.map((sk: any) => (
                          <span key={sk.id} style={{ fontSize: '10px', backgroundColor: 'var(--bg-dark)', border: '1px solid var(--border)', padding: '2px 8px', borderRadius: '4px' }}>{sk.name}</span>
                        ))}
                        {(!data.welderProfile?.skills || data.welderProfile.skills.length === 0) && <span style={{ fontSize: '11px', color: 'var(--text-secondary)' }}>ثبت نشده</span>}
                      </div>
                    </div>
                  </>
                )}
                <div style={{ marginTop: '10px' }}>
                  <strong style={{ fontSize: '12px' }}>بیوگرافی / توضیحات:</strong>
                  <p style={{ fontSize: '11px', color: 'var(--text-secondary)', marginTop: '4px', fontStyle: 'italic', lineHeight: '1.6' }}>
                    {data.user.role === 'WELDER' ? data.welderProfile?.bio : data.employerProfile?.bio || 'توضیحاتی ثبت نشده است.'}
                  </p>
                </div>
              </div>

              {/* Financial Settings */}
              <div className="glass-card" style={{ padding: '16px', margin: 0 }}>
                <h4 style={{ fontSize: '13px', fontWeight: '700', borderBottom: '1px solid var(--border)', paddingBottom: '8px', marginBottom: '12px', color: 'var(--primary)' }}>
                  تنظیمات حساب مالی
                </h4>
                <div style={{ backgroundColor: 'rgba(0,0,0,0.01)', padding: '12px', borderRadius: '8px', border: '1px solid var(--border)' }}>
                  <p style={{ fontSize: '12px', marginBottom: '10px', display: 'flex', justifyContent: 'space-between' }}>
                    <strong>نام بانک:</strong>
                    <span>{data.user.role === 'WELDER' ? data.welderProfile?.bank_name : data.employerProfile?.bank_name || 'ثبت نشده'}</span>
                  </p>
                  <p style={{ fontSize: '12px', marginBottom: '10px', display: 'flex', justifyContent: 'space-between' }}>
                    <strong>شماره کارت بانکی:</strong>
                    <span style={{ fontFamily: 'monospace', fontSize: '13px', letterSpacing: '1px' }}>
                      {data.user.role === 'WELDER' ? data.welderProfile?.card_number : data.employerProfile?.card_number || 'ثبت نشده'}
                    </span>
                  </p>
                  <p style={{ fontSize: '12px', display: 'flex', justifyContent: 'space-between' }}>
                    <strong>شماره شبا:</strong>
                    <span style={{ fontFamily: 'monospace', fontSize: '13px', letterSpacing: '1px' }}>
                      {data.user.role === 'WELDER' ? (data.welderProfile?.shiba_number ? `IR${data.welderProfile.shiba_number}` : 'ثبت نشده') : (data.employerProfile?.shiba_number ? `IR${data.employerProfile.shiba_number}` : 'ثبت نشده')}
                    </span>
                  </p>
                </div>
              </div>
            </div>

            {/* History List */}
            <div>
              <h4 style={{ fontSize: '14px', fontWeight: '700', marginBottom: '12px', paddingBottom: '6px', borderBottom: '2px solid var(--primary)', display: 'inline-block' }}>
                {data.user.role === 'WELDER' ? 'سابقه پیشنهادهای ثبت شده جوشکار' : 'سابقه پروژه‌های ثبت شده کارفرما'}
              </h4>

              {data.user.role === 'WELDER' && (
                <div>
                  {data.offers.length === 0 ? (
                    <p style={{ padding: '20px', textAlign: 'center', color: 'var(--text-secondary)', fontSize: '12px' }}>هیچ پیشنهادی توسط این جوشکار ثبت نشده است.</p>
                  ) : (
                    <div className="table-responsive">
                      <table className="custom-table" style={{ fontSize: '12px' }}>
                        <thead>
                          <tr>
                            <th>عنوان پروژه</th>
                            <th>دستمزد پیشنهادی (تومان)</th>
                            <th>تجهیزات انتخابی</th>
                            <th>تاریخ ثبت</th>
                          </tr>
                        </thead>
                        <tbody>
                          {data.offers.map((off: any) => (
                            <tr key={off.id}>
                              <td>
                                <strong>{off.inquiry?.title || 'پروژه حذف شده'}</strong>
                                {off.items_prices && off.items_prices.length > 0 && (
                                  <div style={{ marginTop: '8px', padding: '8px', backgroundColor: 'var(--bg-dark)', borderRadius: '6px', border: '1px solid var(--border)' }}>
                                    <div style={{ fontWeight: '600', marginBottom: '4px', fontSize: '10px', color: 'var(--text-secondary)' }}>ریز قیمت پیشنهادی هر آیتم:</div>
                                    {off.items_prices.map((item: any, idx: number) => (
                                      <div key={idx} style={{ display: 'flex', justifyContent: 'space-between', fontSize: '10px', padding: '2px 0', borderBottom: '1px dashed var(--border)' }}>
                                        <span>{item.title}</span>
                                        <strong style={{ color: 'var(--text-primary)' }}>{formatPrice(item.price)} تومان</strong>
                                      </div>
                                    ))}
                                  </div>
                                )}
                              </td>
                              <td style={{ color: 'var(--success)', fontWeight: 'bold' }}>{formatPrice(off.total_price)}</td>
                              <td>
                                <div style={{ display: 'flex', gap: '4px', flexWrap: 'wrap' }}>
                                  {off.scaffold_checked && <span style={{ fontSize: '9px', backgroundColor: 'var(--bg-dark)', padding: '2px 4px', borderRadius: '2px' }}>داربست</span>}
                                  {off.power_checked && <span style={{ fontSize: '9px', backgroundColor: 'var(--bg-dark)', padding: '2px 4px', borderRadius: '2px' }}>برق</span>}
                                  {off.rod_checked && <span style={{ fontSize: '9px', backgroundColor: 'var(--bg-dark)', padding: '2px 4px', borderRadius: '2px' }}>الکترود</span>}
                                  {off.delivery_checked && <span style={{ fontSize: '9px', backgroundColor: 'var(--bg-dark)', padding: '2px 4px', borderRadius: '2px' }}>حمل</span>}
                                </div>
                              </td>
                              <td>{new Date(off.created_at).toLocaleDateString('fa-IR')}</td>
                            </tr>
                          ))}
                        </tbody>
                      </table>
                    </div>
                  )}
                </div>
              )}

              {data.user.role === 'EMPLOYER' && (
                <div>
                  {data.inquiries.length === 0 ? (
                    <p style={{ padding: '20px', textAlign: 'center', color: 'var(--text-secondary)', fontSize: '12px' }}>هیچ پروژه‌ای توسط این کارفرما ثبت نشده است.</p>
                  ) : (
                    <div className="table-responsive">
                      <table className="custom-table" style={{ fontSize: '12px' }}>
                        <thead>
                          <tr>
                            <th>عنوان پروژه</th>
                            <th>موقعیت</th>
                            <th>وضعیت</th>
                            <th>اقلام فنی</th>
                            <th>تاریخ ثبت</th>
                          </tr>
                        </thead>
                        <tbody>
                          {data.inquiries.map((inq: any) => (
                            <tr key={inq.id}>
                              <td>
                                <strong>{inq.title}</strong>
                              </td>
                              <td>{inq.province}، {inq.city}</td>
                              <td>
                                <span className={`status-chip ${inq.status === 'BROADCASTED' ? 'approved' : inq.status === 'REJECTED' ? 'danger' : 'pending'}`}>
                                  {getStatusText(inq.status)}
                                </span>
                              </td>
                              <td>{(inq.items || []).length} قلم</td>
                              <td>{new Date(inq.created_at).toLocaleDateString('fa-IR')}</td>
                            </tr>
                          ))}
                        </tbody>
                      </table>
                    </div>
                  )}
                </div>
              )}
            </div>
          </div>
        )}

        <div className="modal-footer" style={{ marginTop: '24px', display: 'flex', justifyContent: 'flex-end' }}>
          <button className="btn btn-secondary" onClick={onClose}>بستن سابقه</button>
        </div>
      </div>
    </div>
  );
}
