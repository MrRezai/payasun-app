import { Inquiry } from '../types';

interface OverviewProps {
  weldersCount: number;
  employersCount: number;
  pendingPicsCount: number;
  pendingEstimationsCount: number;
  inquiries: Inquiry[];
  usersList: any[];
}

export default function Overview({
  weldersCount,
  employersCount,
  pendingPicsCount,
  pendingEstimationsCount,
  inquiries,
  usersList,
}: OverviewProps) {
  
  const estimatedCount = inquiries.filter(i => i.status === 'ESTIMATED').length;
  const broadcastedCount = inquiries.filter(i => i.status === 'BROADCASTED').length;
  const closedCount = inquiries.filter(i => i.status === 'CLOSED' || i.status === 'EXPIRED' || i.status === 'REJECTED').length;

  const maxChartCount = Math.max(pendingEstimationsCount, estimatedCount, broadcastedCount, closedCount, 1);
  const pendingBarHeight = `${Math.round((pendingEstimationsCount / maxChartCount) * 140)}px`;
  const estimatedBarHeight = `${Math.round((estimatedCount / maxChartCount) * 140)}px`;
  const broadcastedBarHeight = `${Math.round((broadcastedCount / maxChartCount) * 140)}px`;
  const closedBarHeight = `${Math.round((closedCount / maxChartCount) * 140)}px`;

  // Dynamic Event Compilation
  const compileRecentEvents = () => {
    const events: { id: string; time: string; message: string; color: string; timestamp: number }[] = [];
    
    // Process Inquiries
    inquiries.forEach(i => {
      const dateObj = new Date(i.updated_at || i.created_at || Date.now());
      const dateStr = dateObj.toLocaleDateString('fa-IR');
      if (i.status === 'PENDING_ESTIMATION') {
        events.push({
          id: `inq-pending-${i.id}`,
          time: dateStr,
          message: `استعلام جدید با عنوان «${i.title}» ثبت شد و در انتظار کارشناسی نقشه است.`,
          color: 'var(--primary)',
          timestamp: dateObj.getTime(),
        });
      } else if (i.status === 'REJECTED') {
        events.push({
          id: `inq-rejected-${i.id}`,
          time: dateStr,
          message: `استعلام «${i.title}» به علت «${i.rejection_reason || ''}» رد شد.`,
          color: 'var(--danger)',
          timestamp: dateObj.getTime(),
        });
      } else if (i.status === 'BROADCASTED') {
        events.push({
          id: `inq-broadcasted-${i.id}`,
          time: dateStr,
          message: `استعلام «${i.title}» تایید و در پلتفرم منتشر گردید.`,
          color: 'var(--success)',
          timestamp: dateObj.getTime(),
        });
      }
    });

    // Process Users
    usersList.forEach(u => {
      const dateObj = new Date(u.created_at || Date.now());
      const dateStr = dateObj.toLocaleDateString('fa-IR');
      const roleLabel = u.role === 'WELDER' ? 'جوشکار' : 'کارفرما';
      events.push({
        id: `usr-reg-${u.id}`,
        time: dateStr,
        message: `کاربر جدید (${roleLabel}) با نام «${u.name}» و شماره ${u.phone_number} در سامانه عضو شد.`,
        color: 'var(--text-secondary)',
        timestamp: dateObj.getTime(),
      });
    });

    // Sort by timestamp (descending)
    events.sort((a, b) => b.timestamp - a.timestamp);
    return events.slice(0, 5);
  };

  const recentEvents = compileRecentEvents();

  return (
    <div style={{ animation: 'fadeIn 0.3s ease-out' }}>
      {/* Stats Metrics Cards */}
      <div className="grid-metrics">
        <div className="glass-card metric-card">
          <div className="metric-info">
            <h3>جوشکاران فعال</h3>
            <div className="value">{weldersCount}</div>
          </div>
          <div className="metric-icon">
            <svg fill="none" viewBox="0 0 24 24" stroke="currentColor" width="24" height="24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
            </svg>
          </div>
        </div>

        <div className="glass-card metric-card">
          <div className="metric-info">
            <h3>کارفرمایان ثبت‌شده</h3>
            <div className="value">{employersCount}</div>
          </div>
          <div className="metric-icon success">
            <svg fill="none" viewBox="0 0 24 24" stroke="currentColor" width="24" height="24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4" />
            </svg>
          </div>
        </div>

        <div className="glass-card metric-card">
          <div className="metric-info">
            <h3>تصاویر معلق تایید</h3>
            <div className="value">{pendingPicsCount}</div>
          </div>
          <div className={`metric-icon ${pendingPicsCount > 0 ? 'warning' : ''}`}>
            <svg fill="none" viewBox="0 0 24 24" stroke="currentColor" width="24" height="24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
            </svg>
          </div>
        </div>

        <div className="glass-card metric-card">
          <div className="metric-info">
            <h3>انتظار برای کارشناسی</h3>
            <div className="value">{pendingEstimationsCount}</div>
          </div>
          <div className={`metric-icon ${pendingEstimationsCount > 0 ? 'danger' : ''}`}>
            <svg fill="none" viewBox="0 0 24 24" stroke="currentColor" width="24" height="24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
            </svg>
          </div>
        </div>
      </div>

      {/* Visual Charts Section */}
      <div style={{ display: 'grid', gridTemplateColumns: '2fr 1fr', gap: '24px', marginBottom: '28px' }}>
        <div className="glass-card">
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '16px' }}>
            <h3 style={{ fontSize: '15px', fontWeight: '700' }}>آمار وضعیت استعلام‌های پروژه</h3>
            <span style={{ fontSize: '12px', color: 'var(--text-secondary)' }}>تعداد کل پروژه‌ها: {inquiries.length} عدد</span>
          </div>
          <div className="chart-container" style={{ minHeight: '180px' }}>
            <div className="chart-bar-wrapper">
              <div className="chart-bar" style={{ height: pendingBarHeight }}></div>
              <span className="chart-label">انتظار کارشناسی ({pendingEstimationsCount})</span>
            </div>
            <div className="chart-bar-wrapper">
              <div className="chart-bar" style={{ height: estimatedBarHeight, background: 'linear-gradient(to top, var(--secondary), rgba(245,158,11,0.3))' }}></div>
              <span className="chart-label">برآورد شده ({estimatedCount})</span>
            </div>
            <div className="chart-bar-wrapper">
              <div className="chart-bar" style={{ height: broadcastedBarHeight, background: 'linear-gradient(to top, var(--success), rgba(16,185,129,0.3))' }}></div>
              <span className="chart-label">انتشار یافته ({broadcastedCount})</span>
            </div>
            <div className="chart-bar-wrapper">
              <div className="chart-bar" style={{ height: closedBarHeight, background: 'rgba(0, 0, 0, 0.05)' }}></div>
              <span className="chart-label">بسته‌شده ({closedCount})</span>
            </div>
          </div>
        </div>

        <div className="glass-card" style={{ display: 'flex', flexDirection: 'column' }}>
          <h3 style={{ fontSize: '15px', fontWeight: '700', marginBottom: '16px' }}>توزیع جغرافیایی پروژه‌ها</h3>
          <div style={{ display: 'flex', flexDirection: 'column', gap: '14px', flex: 1, justifyContent: 'center' }}>
            {inquiries.length === 0 ? (
              <div style={{ fontSize: '12px', color: 'var(--text-secondary)', textAlign: 'center' }}>اطلاعات موقعیتی ثبت نشده است.</div>
            ) : (
              Array.from(new Set(inquiries.map(i => i.province))).slice(0, 3).map(prov => {
                const count = inquiries.filter(i => i.province === prov).length;
                const pct = Math.round((count / inquiries.length) * 100);
                const provinceName = prov || 'نامشخص';
                return (
                  <div key={prov || 'unknown'}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '12px', marginBottom: '4px' }}>
                      <span>استان {provinceName} ({pct}٪)</span>
                      <span>{count} استعلام</span>
                    </div>
                    <div style={{ width: '100%', height: '6px', backgroundColor: 'rgba(0,0,0,0.05)', borderRadius: '3px', overflow: 'hidden' }}>
                      <div style={{ width: `${pct}%`, height: '100%', backgroundColor: provinceName === 'تهران' ? 'var(--primary)' : 'var(--secondary)' }}></div>
                    </div>
                  </div>
                );
              })
            )}
          </div>
        </div>
      </div>

      {/* Dynamic Live Event Reports */}
      <div className="glass-card">
        <h3 style={{ fontSize: '15px', fontWeight: '700', marginBottom: '16px' }}>گزارش رویدادهای اخیر پلتفرم</h3>
        <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
          {recentEvents.length === 0 ? (
            <div style={{ fontSize: '12px', color: 'var(--text-secondary)', textAlign: 'center' }}>رویدادی ثبت نشده است.</div>
          ) : (
            recentEvents.map((evt) => (
              <div key={evt.id} style={{ display: 'flex', gap: '12px', fontSize: '13px', borderBottom: '1px solid var(--border)', paddingBottom: '12px' }}>
                <span style={{ color: evt.color, fontWeight: 'bold', width: '100px', display: 'inline-block' }}>{evt.time}</span>
                <span>{evt.message}</span>
              </div>
            ))
          )}
        </div>
      </div>
    </div>
  );
}
