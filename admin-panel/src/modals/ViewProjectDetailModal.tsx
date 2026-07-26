import { useState } from 'react';
import { Modal, Row, Col, Card, Table, Tag, Button, Space, Typography, Input, Alert, Popconfirm, Badge } from 'antd';
import { FilePdfOutlined, PictureOutlined, DeleteOutlined, StopOutlined, EyeOutlined, EyeInvisibleOutlined } from '@ant-design/icons';
import { BASE_URL } from '../api';
import { Inquiry } from '../types';

const { Title, Text, Paragraph } = Typography;

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
      } finally {
        setIsActionLoading(false);
      }
    }
  };

  const handleDelete = async () => {
    if (onDeleteInquiry) {
      setIsActionLoading(true);
      try {
        await onDeleteInquiry(inquiry.id);
      } finally {
        setIsActionLoading(false);
      }
    }
  };

  const getStatusTag = (status: string) => {
    switch (status) {
      case 'DRAFT': return <Tag>پیش‌نویس</Tag>;
      case 'PENDING_ESTIMATION': return <Tag color="warning">در انتظار تایید</Tag>;
      case 'ESTIMATED': return <Tag color="gold">تایید شده</Tag>;
      case 'BROADCASTED': return <Tag color="success">منتشر شده</Tag>;
      case 'REJECTED': return <Tag color="error">رد شده توسط ادمین</Tag>;
      default: return <Tag>{status}</Tag>;
    }
  };

  const offers = inquiry.offers || [];

  const itemsColumns = [
    {
      title: 'عنوان ردیف فنی',
      dataIndex: 'title',
      key: 'title',
      render: (title: string) => <Text strong>{title}</Text>,
    },
    {
      title: 'واحد سنجش',
      dataIndex: 'unit',
      key: 'unit',
    },
    {
      title: 'تعداد / مقدار',
      dataIndex: 'quantity',
      key: 'quantity',
      align: 'right' as const,
      render: (qty: number) => <Text style={{ color: '#4169E1' }} strong>{qty}</Text>,
    },
  ];

  return (
    <Modal
      open={true}
      title="مشاهده جزئیات فنی و اقلام استخراج شده"
      onCancel={onClose}
      footer={null}
      width={820}
      centered
      bodyStyle={{ maxHeight: '80vh', overflowY: 'auto', padding: '16px 8px' }}
    >
      <Space direction="vertical" style={{ width: '100%' }} size="large">
        <Row gutter={[16, 16]}>
          {/* Blueprint Viewer */}
          <Col xs={24} md={12}>
            <Text type="secondary" style={{ fontSize: '13px', display: 'block', marginBottom: '8px' }}>
              نقشه فنی پروژه
            </Text>
            {inquiry.has_blueprint ? (() => {
              const urls = inquiry.blueprint_url 
                ? inquiry.blueprint_url.split(',').filter((u: string) => u.trim().length > 0)
                : [];
              
              if (urls.length === 0) {
                return (
                  <Card style={{ textAlign: 'center', minHeight: '120px', display: 'flex', alignItems: 'center', justifyContent: 'center', backgroundColor: '#fafafa' }}>
                    <Text type="secondary">در انتظار آپلود فایل پلان...</Text>
                  </Card>
                );
              }

              return (
                <Space direction="vertical" style={{ width: '100%', maxHeight: '200px', overflowY: 'auto' }} size="small">
                  {urls.map((rawUrl: string, idx: number) => {
                    const fileUrl = rawUrl.startsWith('http') ? rawUrl : `${BASE_URL}${rawUrl}`;
                    const isPdf = rawUrl.toLowerCase().endsWith('.pdf');
                    return (
                      <Card key={idx} size="small" style={{ borderRadius: '8px', border: '1px solid #e2e8f0' }}>
                        <Row justify="space-between" align="middle">
                          <Col>
                            <Space>
                              {isPdf ? <FilePdfOutlined style={{ color: '#e74c3c', fontSize: '18px' }} /> : <PictureOutlined style={{ color: '#4169E1', fontSize: '18px' }} />}
                              <Text strong style={{ fontSize: '12px' }}>فایل نقشه شماره {idx + 1}</Text>
                            </Space>
                          </Col>
                          <Col>
                            <Button size="small" type="primary" href={fileUrl} target="_blank">
                              دانلود / مشاهده
                            </Button>
                          </Col>
                        </Row>
                      </Card>
                    );
                  })}
                </Space>
              );
            })() : (
              <Card style={{ textAlign: 'center', minHeight: '120px', display: 'flex', alignItems: 'center', justifyContent: 'center', backgroundColor: '#fafafa' }}>
                <Text type="secondary">بدون نقشه ارسالی (اقلام دستی)</Text>
              </Card>
            )}
          </Col>

          {/* Project Header Info */}
          <Col xs={24} md={12}>
            <Card size="small" style={{ height: '100%' }}>
              <Title level={5} style={{ margin: '0 0 8px 0' }}>{inquiry.title}</Title>
              <Paragraph style={{ margin: '0 0 6px 0', fontSize: '13px' }}>
                <Text type="secondary">موقعیت جغرافیایی: </Text>
                <Text strong>{inquiry.province || 'نامشخص'}، {inquiry.city || 'نامشخص'}</Text>
              </Paragraph>
              <Paragraph style={{ margin: '0 0 8px 0', fontSize: '13px' }}>
                <Text type="secondary">وضعیت فعلی: </Text>
                {getStatusTag(inquiry.status)}
              </Paragraph>
              <div style={{ backgroundColor: '#fafafa', padding: '8px 12px', borderRadius: '8px', border: '1px solid #f0f0f0', maxHeight: '90px', overflowY: 'auto' }}>
                <Text type="secondary" style={{ fontSize: '12px' }}>توضیحات: </Text>
                <Text style={{ fontSize: '12px' }}>{inquiry.description}</Text>
              </div>
            </Card>
          </Col>
        </Row>

        {/* Rejection Alert */}
        {inquiry.status === 'REJECTED' && (
          <Alert
            message="علت رد پروژه توسط ادمین:"
            description={inquiry.rejection_reason || 'دلیلی ثبت نشده است.'}
            type="error"
            showIcon
            closable
          />
        )}

        {/* Items Table */}
        <Card size="small" title={<Text strong>اقلام فنی استخراج شده</Text>}>
          <Table
            dataSource={inquiry.items || []}
            columns={itemsColumns}
            rowKey={(item, idx) => item.id || (idx !== undefined ? idx.toString() : '0')}
            pagination={false}
            scroll={{ x: 'max-content' }}
            size="small"
          />
        </Card>

        {/* Welder Offers Section */}
        <Card 
          size="small" 
          title={
            <Space align="center" size="middle">
              <Text strong style={{ color: '#4169E1' }}>پیشنهادهای دستمزد جوشکاران</Text>
              <Badge count={offers.length} overflowCount={999} showZero style={{ backgroundColor: '#4169E1' }} />
            </Space>
          }
        >
          {offers.length === 0 ? (
            <Text type="secondary" style={{ display: 'block', textAlign: 'center', padding: '16px 0' }}>
              هنوز هیچ جوشکاری پیشنهادی روی این پروژه ثبت نکرده است.
            </Text>
          ) : (
            <Space direction="vertical" style={{ width: '100%' }} size="middle">
              {offers.map((off: any) => (
                <Card key={off.id} size="small" style={{ backgroundColor: '#fafafa' }}>
                  <Row justify="space-between" align="middle" style={{ marginBottom: '8px' }}>
                    <Col>
                      <Space>
                        <Text strong>{off.welder_name}</Text>
                        {off.welder_phone && <Text type="secondary" dir="ltr">({off.welder_phone})</Text>}
                      </Space>
                    </Col>
                    <Col>
                      <Space>
                        {off.is_hidden && <Tag color="error">پنهان شده از کارفرما</Tag>}
                        <Text strong style={{ color: '#10B981', fontSize: '14px' }}>
                          {off.total_price.toLocaleString('fa-IR')} تومان
                        </Text>
                      </Space>
                    </Col>
                  </Row>

                  {/* Items Breakdown */}
                  {off.items_prices && off.items_prices.length > 0 && (
                    <div style={{ backgroundColor: '#ffffff', padding: '8px 12px', borderRadius: '6px', border: '1px solid #f0f0f0', marginBottom: '8px' }}>
                      <Text type="secondary" style={{ fontSize: '11px', display: 'block', marginBottom: '4px' }}>
                        ریز قیمت پیشنهادی و محاسباتی هر آیتم:
                      </Text>
                      <Row gutter={[8, 8]}>
                        {off.items_prices.map((item: any, idx: number) => {
                          const inqItem = inquiry.items?.[idx];
                          const qty = inqItem?.quantity || 1;
                          const unitPrice = item.price || 0;
                          const lineTotal = unitPrice * qty;
                          return (
                            <Col xs={24} sm={12} key={idx}>
                              <Row justify="space-between" style={{ fontSize: '11px', borderBottom: '1px dashed #f0f0f0', padding: '2px 0' }}>
                                <Col><Text type="secondary">{item.title} ({qty} {inqItem?.unit || ''} × {unitPrice.toLocaleString('fa-IR')})</Text></Col>
                                <Col><Text strong>{lineTotal.toLocaleString('fa-IR')} تومان</Text></Col>
                              </Row>
                            </Col>
                          );
                        })}
                      </Row>
                    </div>
                  )}

                  {/* Obligations & Toggle */}
                  <Row justify="space-between" align="middle">
                    <Col>
                      <Space size={4} wrap style={{ fontSize: '11px' }}>
                        <Text type="secondary">تعهدات:</Text>
                        {off.scaffold_checked && <Tag>داربست</Tag>}
                        {off.power_checked && <Tag>برق</Tag>}
                        {off.rod_checked && <Tag>الکترود</Tag>}
                        {off.delivery_checked && <Tag>حمل</Tag>}
                      </Space>
                    </Col>
                    <Col>
                      {onToggleOfferVisibility && (
                        <Button
                          size="small"
                          icon={off.is_hidden ? <EyeOutlined /> : <EyeInvisibleOutlined />}
                          onClick={() => onToggleOfferVisibility(off.id, !off.is_hidden)}
                          loading={isActionLoading}
                        >
                          {off.is_hidden ? 'نمایش به کارفرما' : 'پنهان‌سازی از کارفرما'}
                        </Button>
                      )}
                    </Col>
                  </Row>
                </Card>
              ))}
            </Space>
          )}
        </Card>

        {/* De-list reason form */}
        {showRejectionForm && (
          <Space direction="vertical" style={{ width: '100%', borderTop: '1px solid #f0f0f0', paddingTop: '16px' }}>
            <Text type="danger" strong>دلیل دی‌لیست کردن و بازگشت به ویرایش کارفرما را بنویسید:</Text>
            <Input.TextArea
              rows={3}
              placeholder="مثال: این پروژه نیاز به بازبینی و اصلاح آدرس دارد."
              value={rejectionReason}
              onChange={(e) => setRejectionReason(e.target.value)}
              disabled={isActionLoading}
            />
            <Row justify="end" style={{ gap: '8px' }}>
              <Button 
                danger 
                type="primary" 
                onClick={handleReject} 
                loading={isActionLoading} 
                disabled={!rejectionReason.trim()}
              >
                تایید دی‌لیست
              </Button>
              <Button onClick={() => { setShowRejectionForm(false); setRejectionReason(''); }} disabled={isActionLoading}>
                لغو
              </Button>
            </Row>
          </Space>
        )}

        {/* Modal footer actions */}
        {!showRejectionForm && (
          <Row justify="space-between" align="middle" style={{ borderTop: '1px solid #f0f0f0', paddingTop: '16px' }}>
            <Space wrap>
              {inquiry.status !== 'REJECTED' && (inquiry.status as string) !== 'DRAFT' && onRejectInquiry && (
                <Button 
                  danger 
                  icon={<StopOutlined />} 
                  onClick={() => setShowRejectionForm(true)}
                  disabled={isActionLoading}
                >
                  دی‌لیست کردن پروژه
                </Button>
              )}
              {onDeleteInquiry && (
                <Popconfirm
                  title="حذف کامل پروژه"
                  description="آیا از حذف کامل و برگشت‌ناپذیر این پروژه اطمینان دارید؟"
                  onConfirm={handleDelete}
                  okText="بله، حذف کن"
                  cancelText="خیر"
                  okButtonProps={{ danger: true }}
                >
                  <Button danger icon={<DeleteOutlined />} loading={isActionLoading}>
                    حذف کامل پروژه
                  </Button>
                </Popconfirm>
              )}
            </Space>
            <Button onClick={onClose} disabled={isActionLoading}>
              بستن پنجره
            </Button>
          </Row>
        )}
      </Space>
    </Modal>
  );
}
