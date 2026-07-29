import { useState } from 'react';
import { Modal, Row, Col, Card, Table, Tag, Button, Space, Typography, Input, Alert, Popconfirm, Badge } from 'antd';
import { FilePdfOutlined, PictureOutlined, DeleteOutlined, StopOutlined, EyeOutlined, EyeInvisibleOutlined, DownloadOutlined, BuildOutlined, FileZipOutlined, FileTextOutlined, FolderOpenOutlined } from '@ant-design/icons';
import { BASE_URL } from '../api';
import { Inquiry } from '../types';
import ViewParentProjectModal from './ViewParentProjectModal';

const { Title, Text, Paragraph } = Typography;

const getFileIcon = (url: string) => {
  const cleanUrl = url.split('?')[0].toLowerCase();
  const ext = cleanUrl.includes('.') ? cleanUrl.split('.').pop() || '' : '';

  if (['jpg', 'jpeg', 'png', 'webp', 'gif', 'bmp'].includes(ext)) {
    return <PictureOutlined style={{ color: '#10b981', fontSize: '20px', flexShrink: 0 }} />;
  }
  if (ext === 'pdf') {
    return <FilePdfOutlined style={{ color: '#ef4444', fontSize: '20px', flexShrink: 0 }} />;
  }
  if (['dwg', 'dxf', 'dwf', 'rvt', 'skp', 'ifc', 'pln'].includes(ext)) {
    return <BuildOutlined style={{ color: '#f59e0b', fontSize: '20px', flexShrink: 0 }} />;
  }
  if (['zip', 'rar', '7z'].includes(ext)) {
    return <FileZipOutlined style={{ color: '#8b5cf6', fontSize: '20px', flexShrink: 0 }} />;
  }
  return <FileTextOutlined style={{ color: '#64748b', fontSize: '20px', flexShrink: 0 }} />;
};

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
  const [showParentProjectModal, setShowParentProjectModal] = useState(false);

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
        {inquiry.project ? (
          <Alert
            type="info"
            showIcon
            message={
              <Space direction="vertical" style={{ width: '100%' }}>
                <Row justify="space-between" align="middle" style={{ width: '100%' }}>
                  <Text strong style={{ fontSize: '14px', color: '#1E3A8A' }}>
                    پروژه والد: {inquiry.project.title}
                  </Text>
                  <Button
                    size="small"
                    type="primary"
                    icon={<BuildOutlined />}
                    onClick={() => setShowParentProjectModal(true)}
                    style={{ borderRadius: '6px', fontWeight: 'bold' }}
                  >
                    مشاهده تمام اطلاعات پروژه والد
                  </Button>
                </Row>
                {inquiry.project.description && (
                  <Text style={{ fontSize: '12px', color: '#334155' }}>
                    توضیحات کلی پروژه: {inquiry.project.description}
                  </Text>
                )}
                {inquiry.project.image_urls && inquiry.project.image_urls.length > 0 && (
                  <Space wrap size="small" style={{ marginTop: '6px' }}>
                    <Text type="secondary" style={{ fontSize: '11px' }}>تصاویر پروژه ({inquiry.project.image_urls.length} تصویر):</Text>
                    {inquiry.project.image_urls.map((img: string, idx: number) => {
                      const url = img.startsWith('http') ? img : `${BASE_URL}${img}`;
                      return (
                        <a key={idx} href={url} target="_blank" rel="noopener noreferrer">
                          <img src={url} alt={`پروژه ${idx + 1}`} style={{ width: 44, height: 44, borderRadius: 6, objectFit: 'cover', border: '1px solid #cbd5e1' }} />
                        </a>
                      );
                    })}
                  </Space>
                )}
              </Space>
            }
            style={{ borderRadius: '12px', border: '1px solid #93C5FD', backgroundColor: '#EFF6FF' }}
          />
        ) : (
          <Tag color="purple" style={{ padding: '4px 10px', borderRadius: '6px', fontSize: '11px' }}>
            ثبت مستقیم / استعلام سیستم قدیم
          </Tag>
        )}

        <Row gutter={[16, 16]}>
          {/* Blueprint Viewer */}
          <Col xs={24} md={12}>
            {inquiry.has_blueprint ? (() => {
              const urls = inquiry.blueprint_url 
                ? inquiry.blueprint_url.split(',').filter((u: string) => u.trim().length > 0)
                : [];
              
              if (urls.length === 0) {
                return (
                  <Card style={{ textAlign: 'center', padding: '24px', backgroundColor: '#f8fafc', borderRadius: '12px', border: '1px dashed #cbd5e1' }}>
                    <Text type="secondary">در انتظار بارگذاری فایل پلان توسط کارفرما...</Text>
                  </Card>
                );
              }

              return (
                <div style={{ backgroundColor: '#f8fafc', padding: '12px', borderRadius: '12px', border: '1px solid #e2e8f0' }}>
                  <Row justify="space-between" align="middle" style={{ marginBottom: '10px', paddingBottom: '8px', borderBottom: '1px solid #edf2f7' }}>
                    <Space align="center">
                      <FolderOpenOutlined style={{ color: '#4169E1', fontSize: '16px' }} />
                      <Text strong style={{ fontSize: '13px', color: '#2d3748' }}>
                        لیست فایل‌های نقشه فنی ({urls.length} فایل)
                      </Text>
                    </Space>
                    {inquiry.estimation_type === 'EXACT' ? (
                      <Tag color="purple" style={{ borderRadius: '6px', fontWeight: 'bold' }}>محاسبه دقیق (پلان + سازه)</Tag>
                    ) : (
                      <Tag color="orange" style={{ borderRadius: '6px', fontWeight: 'bold' }}>برآورد تقریبی (معماری)</Tag>
                    )}
                  </Row>

                  <Row gutter={[10, 10]} style={{ maxHeight: '200px', overflowY: 'auto', paddingRight: '2px' }}>
                    {urls.map((rawUrl: string, idx: number) => {
                      const fileUrl = rawUrl.startsWith('http') ? rawUrl : `${BASE_URL}${rawUrl}`;
                      const fileName = rawUrl.split('/').pop() || `فایل ${idx + 1}`;
                      return (
                        <Col xs={24} sm={12} key={idx}>
                          <div 
                            style={{
                              backgroundColor: '#ffffff',
                              padding: '10px 12px',
                              borderRadius: '10px',
                              border: '1px solid #e2e8f0',
                              display: 'flex',
                              alignItems: 'center',
                              justifyContent: 'space-between',
                              gap: '8px',
                              boxShadow: '0 1px 3px rgba(0,0,0,0.03)',
                            }}
                          >
                            <div style={{ display: 'flex', alignItems: 'center', gap: '8px', flex: 1, minWidth: 0 }}>
                              {getFileIcon(rawUrl)}
                              <div style={{ overflow: 'hidden', flex: 1, minWidth: 0 }}>
                                <Text strong style={{ fontSize: '12px', display: 'block', color: '#1a202c' }}>
                                  فایل {idx + 1}
                                </Text>
                                <Text type="secondary" style={{ fontSize: '11px', display: 'block' }} ellipsis title={fileName}>
                                  {fileName}
                                </Text>
                              </div>
                            </div>

                            <Button 
                              size="small" 
                              type="primary" 
                              ghost
                              href={fileUrl} 
                              target="_blank"
                              icon={<DownloadOutlined />}
                              style={{ borderRadius: '6px', fontSize: '11px', flexShrink: 0 }}
                            >
                              مشاهده
                            </Button>
                          </div>
                        </Col>
                      );
                    })}
                  </Row>
                </div>
              );
            })() : (
              <Card style={{ textAlign: 'center', padding: '16px', backgroundColor: '#f8fafc', borderRadius: '12px', border: '1px dashed #cbd5e1' }}>
                <Text type="secondary">پروژه بدون نقشه ارسالی (بر اساس اقلام دستی)</Text>
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
              {inquiry.address && (
                <Paragraph style={{ margin: '0 0 6px 0', fontSize: '13px' }}>
                  <Text type="secondary">محل اجرای دقیق: </Text>
                  <Text strong>{inquiry.address}</Text>
                </Paragraph>
              )}
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
                        {off.profile_picture_url ? (
                          <img
                            src={off.profile_picture_url.startsWith('http') ? off.profile_picture_url : `${BASE_URL}${off.profile_picture_url}`}
                            alt={off.welder_name}
                            style={{ width: 28, height: 28, borderRadius: '50%', objectFit: 'cover', border: '1px solid #e2e8f0' }}
                          />
                        ) : null}
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
      {showParentProjectModal && inquiry.project && (
        <ViewParentProjectModal
          project={{
            ...inquiry.project,
            employerId: inquiry.employerId || inquiry.employer_id,
            employer_name: inquiry.employer_name,
          }}
          allInquiries={[inquiry]}
          onClose={() => setShowParentProjectModal(false)}
        />
      )}
    </Modal>
  );
}
