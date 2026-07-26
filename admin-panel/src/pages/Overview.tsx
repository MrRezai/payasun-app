import { Row, Col, Card, Statistic, Progress, Timeline, Typography, Tag, Space } from 'antd';
import { UserOutlined, ShopOutlined, PictureOutlined, FileTextOutlined } from '@ant-design/icons';
import { Inquiry } from '../types';

const { Title, Text } = Typography;

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
          color: '#4169E1',
          timestamp: dateObj.getTime(),
        });
      } else if (i.status === 'REJECTED') {
        events.push({
          id: `inq-rejected-${i.id}`,
          time: dateStr,
          message: `استعلام «${i.title}» به علت «${i.rejection_reason || ''}» رد شد.`,
          color: '#EF4444',
          timestamp: dateObj.getTime(),
        });
      } else if (i.status === 'BROADCASTED') {
        events.push({
          id: `inq-broadcasted-${i.id}`,
          time: dateStr,
          message: `استعلام «${i.title}» تایید و در پلتفرم منتشر گردید.`,
          color: '#10B981',
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
        color: '#64748B',
        timestamp: dateObj.getTime(),
      });
    });

    // Sort by timestamp (descending)
    events.sort((a, b) => b.timestamp - a.timestamp);
    return events.slice(0, 5);
  };

  const recentEvents = compileRecentEvents();

  return (
    <Space direction="vertical" size="large" style={{ width: '100%' }}>
      {/* Stats Metrics Cards */}
      <Row gutter={[16, 16]}>
        <Col xs={24} sm={12} lg={6}>
          <Card size="small">
            <Statistic
              title={<Text type="secondary">جوشکاران فعال</Text>}
              value={weldersCount}
              prefix={<UserOutlined style={{ color: '#4169E1', marginLeft: 8 }} />}
              valueStyle={{ fontWeight: 800 }}
            />
          </Card>
        </Col>

        <Col xs={24} sm={12} lg={6}>
          <Card size="small">
            <Statistic
              title={<Text type="secondary">کارفرمایان ثبت‌شده</Text>}
              value={employersCount}
              prefix={<ShopOutlined style={{ color: '#10B981', marginLeft: 8 }} />}
              valueStyle={{ fontWeight: 800 }}
            />
          </Card>
        </Col>

        <Col xs={24} sm={12} lg={6}>
          <Card size="small">
            <Statistic
              title={<Text type="secondary">تصاویر معلق تایید</Text>}
              value={pendingPicsCount}
              prefix={<PictureOutlined style={{ color: pendingPicsCount > 0 ? '#F59E0B' : '#64748B', marginLeft: 8 }} />}
              valueStyle={{ fontWeight: 800, color: pendingPicsCount > 0 ? '#F59E0B' : undefined }}
            />
          </Card>
        </Col>

        <Col xs={24} sm={12} lg={6}>
          <Card size="small">
            <Statistic
              title={<Text type="secondary">انتظار برای کارشناسی</Text>}
              value={pendingEstimationsCount}
              prefix={<FileTextOutlined style={{ color: pendingEstimationsCount > 0 ? '#EF4444' : '#64748B', marginLeft: 8 }} />}
              valueStyle={{ fontWeight: 800, color: pendingEstimationsCount > 0 ? '#EF4444' : undefined }}
            />
          </Card>
        </Col>
      </Row>

      {/* Visual Charts & Distribution Section */}
      <Row gutter={[24, 24]}>
        <Col xs={24} lg={16}>
          <Card
            title={
              <Row justify="space-between" align="middle">
                <Col><Title level={5} style={{ margin: 0 }}>آمار وضعیت استعلام‌های پروژه</Title></Col>
                <Col><Text type="secondary" style={{ fontSize: '12px' }}>کل: {inquiries.length} عدد</Text></Col>
              </Row>
            }
          >
            <div className="chart-container" style={{ minHeight: '180px' }}>
              <div className="chart-bar-wrapper">
                <div className="chart-bar" style={{ height: pendingBarHeight }}></div>
                <span className="chart-label">انتظار کارشناسی ({pendingEstimationsCount})</span>
              </div>
              <div className="chart-bar-wrapper">
                <div className="chart-bar" style={{ height: estimatedBarHeight, background: 'linear-gradient(to top, var(--secondary), rgba(245,158,11,0.3))' }}></div>
                <span className="chart-label">تایید شده ({estimatedCount})</span>
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
          </Card>
        </Col>

        <Col xs={24} lg={8}>
          <Card title={<Title level={5} style={{ margin: 0 }}>توزیع جغرافیایی پروژه‌ها</Title>} style={{ height: '100%' }}>
            <Space direction="vertical" style={{ width: '100%' }} size="middle">
              {inquiries.length === 0 ? (
                <Text type="secondary" style={{ display: 'block', textAlign: 'center' }}>اطلاعات موقعیتی ثبت نشده است.</Text>
              ) : (
                Array.from(new Set(inquiries.map(i => i.province))).slice(0, 4).map(prov => {
                  const count = inquiries.filter(i => i.province === prov).length;
                  const pct = Math.round((count / inquiries.length) * 100);
                  const provinceName = prov || 'نامشخص';
                  return (
                    <div key={prov || 'unknown'}>
                      <Row justify="space-between" style={{ fontSize: '12px', marginBottom: 4 }}>
                        <Col><Text strong>استان {provinceName}</Text></Col>
                        <Col><Text type="secondary">{count} استعلام ({pct}٪)</Text></Col>
                      </Row>
                      <Progress percent={pct} showInfo={false} strokeColor={provinceName === 'تهران' ? '#4169E1' : '#F59E0B'} />
                    </div>
                  );
                })
              )}
            </Space>
          </Card>
        </Col>
      </Row>

      {/* Dynamic Live Event Reports */}
      <Card title={<Title level={5} style={{ margin: 0 }}>گزارش رویدادهای اخیر پلتفرم</Title>}>
        {recentEvents.length === 0 ? (
          <Text type="secondary" style={{ display: 'block', textAlign: 'center', padding: '16px 0' }}>
            رویدادی ثبت نشده است.
          </Text>
        ) : (
          <Timeline
            items={recentEvents.map(evt => ({
              color: evt.color,
              children: (
                <Space wrap align="baseline">
                  <Tag color={evt.color === '#4169E1' ? 'processing' : evt.color === '#10B981' ? 'success' : evt.color === '#EF4444' ? 'error' : 'default'}>
                    {evt.time}
                  </Tag>
                  <Text>{evt.message}</Text>
                </Space>
              ),
            }))}
          />
        )}
      </Card>
    </Space>
  );
}
