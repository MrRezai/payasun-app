import { useState } from 'react';
import { Modal, Row, Col, Card, Input, InputNumber, Select, Button, Space, Typography, Alert, Tag } from 'antd';
import { PlusOutlined, DeleteOutlined, CheckCircleOutlined, FilePdfOutlined, PictureOutlined, DownloadOutlined } from '@ant-design/icons';
import { BASE_URL } from '../api';
import { Inquiry, InquiryItem } from '../types';

const { Title, Text, Paragraph } = Typography;

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
  const [showConfirmStep, setShowConfirmStep] = useState(false);
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

  const handleApproveInitial = () => {
    const invalid = estimationItems.some(item => !item.title || item.quantity <= 0);
    if (invalid) {
      alert('لطفاً عنوان و تعداد تمام اقلام فنی را وارد کنید.');
      return;
    }
    setShowConfirmStep(true);
  };

  const handleApproveFinal = () => {
    onSubmitEstimation(inquiry.id, estimationItems);
  };

  const handleReject = () => {
    onRejectInquiry(inquiry.id, rejectionReason);
  };

  const unitOptions = [
    { label: 'عدد', value: 'عدد' },
    { label: 'متر', value: 'متر' },
    { label: 'متر مربع', value: 'متر مربع' },
    { label: 'متر مکعب', value: 'متر مکعب' },
    { label: 'کیلوگرم', value: 'کیلوگرم' },
    { label: 'شاخه', value: 'شاخه' },
    { label: 'تن', value: 'تن' },
    { label: 'بند', value: 'بند' },
    { label: 'ساعت', value: 'ساعت' },
    { label: 'روز', value: 'روز' },
    { label: 'سرجوش', value: 'سرجوش' },
    { label: 'اینچ-قطر', value: 'اینچ-قطر' },
    { label: 'پروژه‌ای / مقطوع', value: 'پروژه‌ای' },
  ];

  return (
    <Modal
      open={true}
      title="کارشناسی نقشه و استخراج اقلام فنی پروژه"
      onCancel={onClose}
      footer={null}
      width={900}
      centered
      bodyStyle={{ maxHeight: '80vh', overflowY: 'auto', padding: '16px 8px' }}
    >
      {showConfirmStep ? (
        <Space direction="vertical" style={{ width: '100%' }} size="middle">
          <Alert
            message="گام دوم: تایید و ارسال برآورد کارشناسی به کارفرما"
            description={`آیا از ثبت برآورد کارشناسی پروژه «${inquiry.title}» اطمینان دارید؟ با تایید این مرحله، تعداد ${estimationItems.length} قلم فنی جهت بررسی، ویرایش احتمالی و انتشار نهایی برای کارفرما ارسال خواهد شد.`}
            type="info"
            showIcon
            closable
            icon={<CheckCircleOutlined />}
          />

          <Card size="small" title="خلاصه اقلام فنی آماده ارسال به کارفرما:">
            <div style={{ maxHeight: '180px', overflowY: 'auto' }}>
              {estimationItems.map((item, idx) => (
                <Row key={idx} justify="space-between" style={{ padding: '6px 0', borderBottom: '1px dashed #f0f0f0' }}>
                  <Col><Text strong>{idx + 1}. {item.title}</Text></Col>
                  <Col><Text style={{ color: '#4169E1' }} strong>{item.quantity} {item.unit}</Text></Col>
                </Row>
              ))}
            </div>
          </Card>

          <Row justify="end" style={{ gap: '8px', marginTop: '12px' }}>
            <Button type="primary" size="large" onClick={handleApproveFinal} style={{ fontWeight: 'bold', backgroundColor: '#10B981', borderColor: '#10B981' }}>
              تایید و ارسال برآورد کارشناسی به کارفرما
            </Button>
            <Button size="large" onClick={() => setShowConfirmStep(false)}>
              بازگشت به ویرایش اقلام
            </Button>
          </Row>
        </Space>
      ) : (
          <Space direction="vertical" style={{ width: '100%' }} size="large">
            <Row gutter={[16, 16]}>
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
                          <FilePdfOutlined style={{ color: '#4169E1', fontSize: '16px' }} />
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
                          const isPdf = rawUrl.toLowerCase().endsWith('.pdf');
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
                                <Space wrap={false} style={{ flex: 1, overflow: 'hidden' }}>
                                  {isPdf ? (
                                    <FilePdfOutlined style={{ color: '#e74c3c', fontSize: '20px', flexShrink: 0 }} />
                                  ) : (
                                    <PictureOutlined style={{ color: '#4169E1', fontSize: '20px', flexShrink: 0 }} />
                                  )}
                                  <div style={{ overflow: 'hidden' }}>
                                    <Text strong style={{ fontSize: '12px', display: 'block', color: '#1a202c' }}>
                                      فایل {idx + 1}
                                    </Text>
                                    <Text type="secondary" style={{ fontSize: '11px', display: 'block' }} ellipsis title={fileName}>
                                      {fileName}
                                    </Text>
                                  </div>
                                </Space>

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

            {/* Project Summary */}
            <Col xs={24} md={12}>
              <Card size="small" style={{ height: '100%' }}>
                <Title level={5} style={{ margin: '0 0 8px 0' }}>{inquiry.title}</Title>
                <Paragraph style={{ margin: '0 0 6px 0', fontSize: '12px' }}>
                  <Text type="secondary">کارفرما: </Text>
                  <Text strong>{inquiry.employer_name || 'کارفرما'}</Text>
                </Paragraph>
                <Paragraph style={{ margin: '0 0 8px 0', fontSize: '12px' }}>
                  <Text type="secondary">موقعیت: </Text>
                  <Text strong>{inquiry.province}، {inquiry.city}</Text>
                </Paragraph>
                {inquiry.address && (
                  <Paragraph style={{ margin: '0 0 8px 0', fontSize: '12px' }}>
                    <Text type="secondary">محل اجرای دقیق: </Text>
                    <Text strong>{inquiry.address}</Text>
                  </Paragraph>
                )}
                <div style={{ backgroundColor: '#fafafa', padding: '8px 12px', borderRadius: '8px', border: '1px solid #f0f0f0', maxHeight: '100px', overflowY: 'auto' }}>
                  <Text type="secondary" style={{ fontSize: '12px' }}>توضیحات: </Text>
                  <Text style={{ fontSize: '12px' }}>{inquiry.description}</Text>
                </div>
              </Card>
            </Col>
          </Row>

          {/* Technical Items Section */}
          <div>
            <Row justify="space-between" align="middle" style={{ marginBottom: '12px' }}>
              <Title level={5} style={{ margin: 0 }}>آیتم‌های فنی استخراج شده</Title>
              <Button type="dashed" icon={<PlusOutlined />} onClick={addEstimationRow} size="small">
                افزودن ردیف جدید
              </Button>
            </Row>

            <div style={{ maxHeight: '240px', overflowY: 'auto', paddingRight: '4px' }}>
              {estimationItems.map((item, idx) => (
                <Card key={idx} size="small" style={{ marginBottom: '10px', backgroundColor: '#fafafa' }}>
                  <Row gutter={[8, 8]} align="middle">
                    <Col xs={24} sm={11}>
                      <Input
                        placeholder="عنوان قلم (مثال: جوش لوله ۲ اینچ)"
                        value={item.title}
                        onChange={(e) => handleEstimationRowChange(idx, 'title', e.target.value)}
                      />
                    </Col>
                    <Col xs={12} sm={6}>
                      <Select
                        style={{ width: '100%' }}
                        value={item.unit}
                        onChange={(val) => handleEstimationRowChange(idx, 'unit', val)}
                        options={unitOptions}
                      />
                    </Col>
                    <Col xs={12} sm={5}>
                      <InputNumber
                        min={1}
                        style={{ width: '100%' }}
                        placeholder="تعداد"
                        value={item.quantity}
                        onChange={(val) => handleEstimationRowChange(idx, 'quantity', val || 1)}
                      />
                    </Col>
                    <Col xs={24} sm={2} style={{ textAlign: 'left' }}>
                      <Button 
                        danger 
                        icon={<DeleteOutlined />} 
                        onClick={() => removeEstimationRow(idx)}
                        disabled={estimationItems.length === 1}
                        block
                      />
                    </Col>
                  </Row>
                </Card>
              ))}
            </div>
          </div>

          {/* Action buttons */}
          <div style={{ borderTop: '1px solid #f0f0f0', paddingTop: '16px' }}>
            {showRejectionForm ? (
              <Space direction="vertical" style={{ width: '100%' }}>
                <Text type="danger" strong>علت رد کردن استعلام پروژه (به کارفرما نمایش داده می‌شود):</Text>
                <Input.TextArea
                  rows={3}
                  placeholder="مثال: نقشه فنی خوانا نیست یا اطلاعات پروژه نامشخص است."
                  value={rejectionReason}
                  onChange={(e) => setRejectionReason(e.target.value)}
                />
                <Row justify="end" style={{ gap: '8px' }}>
                  <Button danger type="primary" onClick={handleReject}>
                    تایید و ثبت رد استعلام
                  </Button>
                  <Button onClick={() => { setShowRejectionForm(false); setRejectionReason(''); }}>
                    لغو
                  </Button>
                </Row>
              </Space>
            ) : (
              <Row justify="end" style={{ gap: '8px' }}>
                <Button type="primary" onClick={handleApproveInitial} style={{ fontWeight: 'bold' }}>
                  مرحله بعد: تایید برآورد و ارسال به کارفرما
                </Button>
                <Button danger onClick={() => setShowRejectionForm(true)}>
                  رد کردن استعلام
                </Button>
                <Button onClick={onClose}>
                  انصراف
                </Button>
              </Row>
            )}
          </div>
        </Space>
      )}
    </Modal>
  );
}

