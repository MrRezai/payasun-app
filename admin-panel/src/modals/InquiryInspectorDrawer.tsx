import { useEffect, useState } from 'react';
import { Drawer, Card, Table, Tag, Space, Typography, Spin, Alert, Button, Select, Row, Col, Steps } from 'antd';
import { ApiClient } from '../api';

const { Title, Text, Paragraph } = Typography;

interface InquiryInspectorDrawerProps {
  inquiryId: string | null;
  onClose: () => void;
  onRefresh: () => void;
}

export default function InquiryInspectorDrawer({ inquiryId, onClose, onRefresh }: InquiryInspectorDrawerProps) {
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [data, setData] = useState<any>(null);
  const [selectedStatus, setSelectedStatus] = useState<string>('');
  const [updating, setUpdating] = useState(false);

  useEffect(() => {
    if (!inquiryId) return;
    setLoading(true);
    setError(null);
    ApiClient.getInquiryInspector(inquiryId)
      .then((res) => {
        setData(res);
        setSelectedStatus(res.inquiry.status);
        setLoading(false);
      })
      .catch((err) => {
        setError(err.message || 'خطا در دریافت اطلاعات بازرسی استعلام.');
        setLoading(false);
      });
  }, [inquiryId]);

  const handleStatusOverride = async () => {
    if (!inquiryId || !selectedStatus) return;
    setUpdating(true);
    try {
      await ApiClient.overrideInquiryStatus(inquiryId, selectedStatus);
      alert('تغییر وضعیت دستی با موفقیت ثبت شد.');
      setUpdating(false);
      onRefresh();
      onClose();
    } catch (e: any) {
      alert(e.message || 'خطا در تغییر وضعیت');
      setUpdating(false);
    }
  };

  const dispatchColumns = [
    {
      title: 'جوشکار',
      key: 'welder',
      render: (_: any, r: any) => (
        <Space direction="vertical" size={0}>
          <Text strong>{r.welder_name}</Text>
          <Text type="secondary" style={{ fontSize: '11px' }}>📱 {r.welder_phone}</Text>
        </Space>
      ),
    },
    {
      title: 'رده / امتیاز',
      key: 'tier_score',
      render: (_: any, r: any) => (
        <Space size={4}>
          <Tag color="blue">گروه {r.welder_tier}</Tag>
          <Tag color="gold">★ {r.welder_score}</Tag>
        </Space>
      ),
    },
    {
      title: 'نوع دیسپچ',
      dataIndex: 'dispatch_type',
      key: 'dispatch_type',
      render: (type: string) => {
        switch (type) {
          case 'TOP_SCORE': return <Tag color="purple">۳ نفر برتر</Tag>;
          case 'NEWCOMER': return <Tag color="cyan">تازه وارد</Tag>;
          case 'RANDOM': return <Tag color="orange">تصادفی</Tag>;
          case 'REPLACEMENT': return <Tag color="volcano">جایگزین ۲۴h</Tag>;
          default: return <Tag>{type}</Tag>;
        }
      },
    },
    {
      title: 'وضعیت پاسخ',
      dataIndex: 'status',
      key: 'status',
      render: (status: string) => {
        switch (status) {
          case 'PENDING': return <Tag color="warning">در انتظار پاسخ</Tag>;
          case 'ACCEPTED': return <Tag color="success">تایید و پذیرفته</Tag>;
          case 'DECLINED': return <Tag color="error">رد شده</Tag>;
          case 'TIMED_OUT': return <Tag color="red">تایم‌آوت ۲۴h</Tag>;
          default: return <Tag>{status}</Tag>;
        }
      },
    },
    {
      title: 'زمان ارجاع',
      dataIndex: 'dispatched_at',
      key: 'dispatched_at',
      render: (date: string) => <Text type="secondary" style={{ fontSize: '11px' }}>{new Date(date).toLocaleString('fa-IR')}</Text>,
    },
  ];

  const getStepIndex = (status: string) => {
    switch (status) {
      case 'DRAFT': return 0;
      case 'PENDING_ESTIMATION': return 1;
      case 'ESTIMATED': return 2;
      case 'DISPATCHED': return 3;
      case 'AGREEMENT_PENDING_WELDER': return 4;
      case 'IN_PROGRESS': return 5;
      case 'COMPLETED_PENDING_EMPLOYER': return 6;
      case 'COMPLETED': return 7;
      default: return 0;
    }
  };

  return (
    <Drawer
      open={!!inquiryId}
      title="نظارت بر پروسه و چرخه حیات استعلام (Lifecycle Inspector)"
      onClose={onClose}
      width={720}
    >
      {loading && (
        <div style={{ textAlign: 'center', padding: '40px 0' }}>
          <Spin size="large" />
          <Text type="secondary" style={{ display: 'block', marginTop: 12 }}>در حال دریافت پرونده بازرسی استعلام...</Text>
        </div>
      )}

      {error && <Alert message="خطا" description={error} type="error" showIcon style={{ marginBottom: 16 }} />}

      {data && !loading && !error && (
        <Space direction="vertical" style={{ width: '100%' }} size="large">
          {/* Header Info */}
          <Card size="small" style={{ backgroundColor: '#fafafa' }}>
            <Title level={5} style={{ margin: '0 0 8px 0' }}>{data.inquiry.title}</Title>
            <Space wrap size="middle">
              <Tag color="blue">شهر: {data.inquiry.city}</Tag>
              <Tag color="purple">رده پروژه: گروه {data.inquiry.tier}</Tag>
              <Tag color="green">مبلغ بیعانه: {(data.inquiry.deposit_amount || 0).toLocaleString('fa-IR')} تومان</Tag>
              <Text type="secondary">تعداد پیشنهادها: <Text strong>{data.offers_count}</Text></Text>
            </Space>
          </Card>

          {/* Stepper Timeline */}
          <Card size="small" title={<Text strong>تایم‌لاین گام‌های اجرایی پروژه</Text>}>
            <Steps
              current={getStepIndex(data.inquiry.status)}
              size="small"
              items={[
                { title: 'ثبت استعلام' },
                { title: 'برآورد ادمین' },
                { title: 'تایید کارفرما' },
                { title: 'ارجاع ۵ تایی' },
                { title: 'توافق اولیه' },
                { title: 'در حال اجرا' },
                { title: 'اتمام پروژه' },
              ]}
            />
          </Card>

          {/* 5-Dispatched Welders Inspector Table */}
          <Card size="small" title={<Text strong>لیست ۵ جوشکار معرفی‌شده (5-Welder Dispatch Inspector)</Text>}>
            <Table
              dataSource={data.dispatches}
              columns={dispatchColumns}
              rowKey="id"
              pagination={false}
              size="small"
            />
          </Card>

          {/* Employer Rating Breakdown if completed */}
          {data.review && (
            <Card size="small" title={<Text strong style={{ color: '#10B981' }}>نظرات و امتیاز ۳ بخشی ثبت‌شده کارفرما</Text>}>
              <Row gutter={[16, 16]}>
                <Col span={8}>
                  <Text type="secondary">کیفیت کار (۴۰٪): </Text>
                  <Text strong>{data.review.quality_score} از ۵</Text>
                </Col>
                <Col span={8}>
                  <Text type="secondary">خوش‌قولی (۳۵٪): </Text>
                  <Text strong>{data.review.punctuality_score} از ۵</Text>
                </Col>
                <Col span={8}>
                  <Text type="secondary">رفتار حرفه‌ای (۲۵٪): </Text>
                  <Text strong>{data.review.behavior_score} از ۵</Text>
                </Col>
                <Col span={24}>
                  <Alert
                    type="success"
                    message={`میانگین امتیاز نهایی: ${data.review.calculated_rating} از ۵.۰`}
                    description={data.review.comment ? `نظر کارفرما: "${data.review.comment}"` : 'توضیحات متنی ثبت نشده است.'}
                    showIcon
                  />
                </Col>
              </Row>
            </Card>
          )}

          {/* Admin Intervention Overrides */}
          <Card size="small" title={<Text strong style={{ color: '#DC2626' }}>مداخله دستی ادمین (Admin Overrides)</Text>}>
            <Paragraph style={{ fontSize: '12px' }}>
              امکان تغییر وضعیت دستی استعلام در صورت بروز مشکل یا لغو قرارداد توسط کارفرما/جوشکار.
            </Paragraph>

            <Space wrap style={{ width: '100%' }}>
              <Select
                value={selectedStatus}
                onChange={(val) => setSelectedStatus(val)}
                style={{ width: 220 }}
                options={[
                  { value: 'PENDING_ESTIMATION', label: 'در انتظار برآورد' },
                  { value: 'ESTIMATED', label: 'برآورد شده (تایید ادمین)' },
                  { value: 'DISPATCHED', label: 'ارجاع داده شده به ۵ نفر' },
                  { value: 'AGREEMENT_PENDING_WELDER', label: 'در انتظار تایید جوشکار' },
                  { value: 'IN_PROGRESS', label: 'در حال اجرا' },
                  { value: 'COMPLETED_PENDING_EMPLOYER', label: 'اعلام پایان کار' },
                  { value: 'COMPLETED', label: 'تکمیل و خاتمه یافته' },
                  { value: 'EXPIRED', label: 'منقضی شده (۷۲h)' },
                  { value: 'REJECTED', label: 'رد شده' },
                ]}
              />
              <Button type="primary" danger loading={updating} onClick={handleStatusOverride}>
                اعمال تغییر وضعیت دستی
              </Button>
            </Space>
          </Card>
        </Space>
      )}
    </Drawer>
  );
}
