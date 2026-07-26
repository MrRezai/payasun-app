import { useEffect, useState } from 'react';
import { Modal, Row, Col, Card, Table, Tag, Avatar, Space, Typography, Spin, Alert, Button } from 'antd';
import { UserOutlined, PhoneOutlined, CalendarOutlined, StarOutlined, BankOutlined, CreditCardOutlined } from '@ant-design/icons';
import { ApiClient, BASE_URL } from '../api';

const { Title, Text, Paragraph } = Typography;

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

  const getStatusTag = (status: string) => {
    switch (status) {
      case 'DRAFT': return <Tag>پیش‌نویس</Tag>;
      case 'PENDING_ESTIMATION': return <Tag color="warning">در انتظار تایید</Tag>;
      case 'ESTIMATED': return <Tag color="gold">تایید شده</Tag>;
      case 'BROADCASTED': return <Tag color="success">منتشر شده</Tag>;
      case 'REJECTED': return <Tag color="error">رد شده</Tag>;
      default: return <Tag>{status}</Tag>;
    }
  };

  const welderOffersColumns = [
    {
      title: 'عنوان پروژه',
      key: 'title',
      render: (_: any, off: any) => (
        <Space direction="vertical" size={2}>
          <Text strong>{off.inquiry?.title || 'پروژه حذف شده'}</Text>
          {off.items_prices && off.items_prices.length > 0 && (
            <div style={{ backgroundColor: '#fafafa', padding: '6px 8px', borderRadius: 4, border: '1px solid #f0f0f0', fontSize: '11px' }}>
              {off.items_prices.map((item: any, idx: number) => (
                <div key={idx} style={{ display: 'flex', justifyContent: 'space-between', gap: 12 }}>
                  <Text type="secondary">{item.title}</Text>
                  <Text strong>{formatPrice(item.price)} تومان</Text>
                </div>
              ))}
            </div>
          )}
        </Space>
      ),
    },
    {
      title: 'دستمزد پیشنهادی',
      dataIndex: 'total_price',
      key: 'total_price',
      render: (price: number) => <Text strong style={{ color: '#10B981' }}>{formatPrice(price)} تومان</Text>,
    },
    {
      title: 'تجهیزات',
      key: 'equipment',
      render: (_: any, off: any) => (
        <Space size={4} wrap>
          {off.scaffold_checked && <Tag>داربست</Tag>}
          {off.power_checked && <Tag>برق</Tag>}
          {off.rod_checked && <Tag>الکترود</Tag>}
          {off.delivery_checked && <Tag>حمل</Tag>}
        </Space>
      ),
    },
    {
      title: 'تاریخ ثبت',
      dataIndex: 'created_at',
      key: 'created_at',
      render: (date: string) => <Text type="secondary">{new Date(date).toLocaleDateString('fa-IR')}</Text>,
    },
  ];

  const employerInquiriesColumns = [
    {
      title: 'عنوان پروژه',
      dataIndex: 'title',
      key: 'title',
      render: (title: string) => <Text strong>{title}</Text>,
    },
    {
      title: 'موقعیت',
      key: 'location',
      render: (_: any, inq: any) => <Text>{inq.province}، {inq.city}</Text>,
    },
    {
      title: 'وضعیت',
      dataIndex: 'status',
      key: 'status',
      render: (status: string) => getStatusTag(status),
    },
    {
      title: 'اقلام فنی',
      key: 'items',
      render: (_: any, inq: any) => <Text strong>{(inq.items || []).length} قلم</Text>,
    },
    {
      title: 'تاریخ ثبت',
      dataIndex: 'created_at',
      key: 'created_at',
      render: (date: string) => <Text type="secondary">{new Date(date).toLocaleDateString('fa-IR')}</Text>,
    },
  ];

  return (
    <Modal
      open={true}
      title="جزئیات و سابقه کامل کاربر"
      onCancel={onClose}
      footer={[
        <Button key="close" onClick={onClose}>
          بستن سابقه
        </Button>,
      ]}
      width={800}
      centered
      bodyStyle={{ maxHeight: '80vh', overflowY: 'auto', padding: '16px 8px' }}
    >
      {loading && (
        <div style={{ textAlign: 'center', padding: '40px 0' }}>
          <Spin size="large" />
          <Text type="secondary" style={{ display: 'block', marginTop: 12 }}>در حال دریافت اطلاعات سابقه کاربر...</Text>
        </div>
      )}

      {error && (
        <Alert message="خطا" description={error} type="error" showIcon style={{ marginBottom: 16 }} />
      )}

      {data && !loading && !error && (
        <Space direction="vertical" style={{ width: '100%' }} size="large">
          {/* Header Profile Section */}
          <Card size="small" style={{ backgroundColor: '#fafafa' }}>
            <Row gutter={[16, 16]} align="middle">
              <Col>
                <Avatar 
                  size={64} 
                  src={
                    data.user.role === 'WELDER' && data.welderProfile?.profile_picture_url 
                      ? `${BASE_URL}${data.welderProfile.profile_picture_url}` 
                      : data.user.role === 'EMPLOYER' && data.employerProfile?.profile_picture_url
                      ? `${BASE_URL}${data.employerProfile.profile_picture_url}`
                      : undefined
                  }
                  icon={<UserOutlined />} 
                />
              </Col>
              <Col flex="1">
                <Title level={5} style={{ margin: '0 0 6px 0' }}>
                  {data.user.role === 'WELDER'
                    ? `${data.welderProfile?.first_name || ''} ${data.welderProfile?.last_name || ''}`.trim() || 'جوشکار بدون نام'
                    : data.employerProfile?.company_name || `${data.employerProfile?.first_name || ''} ${data.employerProfile?.last_name || ''}`.trim() || 'کارفرما بدون نام'}
                </Title>
                <Space wrap size="middle">
                  <Tag color={data.user.role === 'WELDER' ? 'processing' : 'success'}>
                    {data.user.role === 'WELDER' ? 'نقش: جوشکار' : 'نقش: کارفرما'}
                  </Tag>
                  <Text type="secondary"><PhoneOutlined /> شماره: <Text dir="ltr" strong>{data.user.phone_number}</Text></Text>
                  <Text type="secondary"><CalendarOutlined /> عضویت: {new Date(data.user.created_at).toLocaleDateString('fa-IR')}</Text>
                </Space>
              </Col>
            </Row>
          </Card>

          {/* Details Row */}
          <Row gutter={[16, 16]}>
            <Col xs={24} md={12}>
              <Card size="small" title={<Text strong>اطلاعات کاربری و بیوگرافی</Text>} style={{ height: '100%' }}>
                <Paragraph style={{ fontSize: '13px' }}>
                  <Text type="secondary">شهر محل سکونت: </Text>
                  <Text strong>
                    {data.user.role === 'WELDER' 
                      ? (data.welderProfile?.home_province ? `${data.welderProfile.home_province}، ${data.welderProfile.home_city}` : 'نامشخص') 
                      : (data.employerProfile?.province ? `${data.employerProfile.province}، ${data.employerProfile.city}` : 'نامشخص')}
                  </Text>
                </Paragraph>

                {data.user.role === 'WELDER' && (
                  <>
                    <Paragraph style={{ fontSize: '13px' }}>
                      <Text type="secondary">امتیاز کل: </Text>
                      <Text strong><StarOutlined style={{ color: '#f59e0b' }} /> {data.welderProfile?.total_score || 0} ستاره</Text>
                    </Paragraph>
                    <Paragraph style={{ fontSize: '13px' }}>
                      <Text type="secondary">پروژه‌های موفق: </Text>
                      <Text strong>{data.welderProfile?.completed_jobs_count || 0} پروژه</Text>
                    </Paragraph>
                    <div style={{ marginBottom: 12 }}>
                      <Text type="secondary" style={{ fontSize: '12px' }}>تخصص‌ها: </Text>
                      <Space size={4} wrap style={{ marginTop: 4 }}>
                        {data.welderProfile?.skills?.map((sk: any) => (
                          <Tag key={sk.id}>{sk.name}</Tag>
                        ))}
                        {(!data.welderProfile?.skills || data.welderProfile.skills.length === 0) && <Text type="secondary">ثبت نشده</Text>}
                      </Space>
                    </div>
                  </>
                )}

                <div>
                  <Text type="secondary" style={{ fontSize: '12px' }}>بیوگرافی / توضیحات: </Text>
                  <Paragraph italic style={{ fontSize: '12px', marginTop: 4 }}>
                    {data.user.role === 'WELDER' ? data.welderProfile?.bio : data.employerProfile?.bio || 'توضیحاتی ثبت نشده است.'}
                  </Paragraph>
                </div>
              </Card>
            </Col>

            <Col xs={24} md={12}>
              <Card size="small" title={<Text strong>تنظیمات حساب مالی</Text>} style={{ height: '100%' }}>
                <Space direction="vertical" style={{ width: '100%' }} size="middle">
                  <div>
                    <Text type="secondary"><BankOutlined /> نام بانک: </Text>
                    <Text strong>{data.user.role === 'WELDER' ? data.welderProfile?.bank_name : data.employerProfile?.bank_name || 'ثبت نشده'}</Text>
                  </div>
                  <div>
                    <Text type="secondary"><CreditCardOutlined /> کارت بانکی: </Text>
                    <Text strong style={{ fontFamily: 'monospace' }}>
                      {data.user.role === 'WELDER' ? data.welderProfile?.card_number : data.employerProfile?.card_number || 'ثبت نشده'}
                    </Text>
                  </div>
                  <div>
                    <Text type="secondary">شماره شبا: </Text>
                    <Text strong style={{ fontFamily: 'monospace' }}>
                      {data.user.role === 'WELDER' 
                        ? (data.welderProfile?.shiba_number ? `IR${data.welderProfile.shiba_number}` : 'ثبت نشده') 
                        : (data.employerProfile?.shiba_number ? `IR${data.employerProfile.shiba_number}` : 'ثبت نشده')}
                    </Text>
                  </div>
                </Space>
              </Card>
            </Col>
          </Row>

          {/* History List Table */}
          <Card 
            size="small" 
            title={
              <Text strong style={{ color: '#4169E1' }}>
                {data.user.role === 'WELDER' ? 'سابقه پیشنهادهای ثبت شده جوشکار' : 'سابقه پروژه‌های ثبت شده کارفرما'}
              </Text>
            }
          >
            {data.user.role === 'WELDER' ? (
              <Table
                dataSource={data.offers}
                columns={welderOffersColumns}
                rowKey="id"
                pagination={{ pageSize: 5 }}
                scroll={{ x: 'max-content' }}
                size="small"
              />
            ) : (
              <Table
                dataSource={data.inquiries}
                columns={employerInquiriesColumns}
                rowKey="id"
                pagination={{ pageSize: 5 }}
                scroll={{ x: 'max-content' }}
                size="small"
              />
            )}
          </Card>
        </Space>
      )}
    </Modal>
  );
}
