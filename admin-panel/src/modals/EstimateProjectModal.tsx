import { useState } from 'react';
import { Modal, Row, Col, Card, Input, InputNumber, Select, Button, Space, Typography, Alert, Tag } from 'antd';
import { PlusOutlined, DeleteOutlined, CheckCircleOutlined, FilePdfOutlined, PictureOutlined } from '@ant-design/icons';
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
            message="گام دوم: تایید نهایی انتشار پروژه در سیستم"
            description={`آیا از تایید کارشناسی و انتشار عمومی پروژه «${inquiry.title}» در پلتفرم اطمینان دارید؟ با تایید این مرحله، تعداد ${estimationItems.length} قلم فنی ثبت شده برای تمامی جوشکاران منتشر خواهد شد.`}
            type="info"
            showIcon
            closable
            icon={<CheckCircleOutlined />}
          />

          <Card size="small" title="خلاصه اقلام فنی آماده انتشار:">
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
              تایید نهایی و انتشار عمومی پروژه
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
                <Row justify="space-between" align="middle" style={{ marginBottom: '8px' }}>
                  <Col>
                    <Text type="secondary" style={{ fontSize: '13px' }}>
                      فایل‌های نقشه فنی پروژه
                    </Text>
                  </Col>
                  <Col>
                    {inquiry.has_blueprint && (
                      inquiry.estimation_type === 'EXACT' ? (
                        <Tag color="purple" style={{ fontWeight: 'bold' }}>محاسبه دقیق</Tag>
                      ) : (
                        <Tag color="orange" style={{ fontWeight: 'bold' }}>برآورد تقریبی</Tag>
                      )
                    )}
                  </Col>
                </Row>

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
                    <Space direction="vertical" style={{ width: '100%', maxHeight: '220px', overflowY: 'auto' }} size="small">
                      <Text style={{ fontSize: '11px', color: '#718096' }}>تعداد {urls.length} فایل بارگذاری شده است:</Text>
                      {urls.map((rawUrl: string, idx: number) => {
                        const fileUrl = rawUrl.startsWith('http') ? rawUrl : `${BASE_URL}${rawUrl}`;
                        const fileName = rawUrl.split('/').pop() || `فایل ${idx + 1}`;
                        const isPdf = rawUrl.toLowerCase().endsWith('.pdf');
                        return (
                          <Card key={idx} size="small" style={{ borderRadius: '8px', border: '1px solid #e2e8f0' }}>
                            <Row justify="space-between" align="middle">
                              <Col style={{ flex: 1, overflow: 'hidden', paddingLeft: '8px' }}>
                                <Space wrap={false}>
                                  {isPdf ? <FilePdfOutlined style={{ color: '#e74c3c', fontSize: '18px' }} /> : <PictureOutlined style={{ color: '#4169E1', fontSize: '18px' }} />}
                                  <Text strong style={{ fontSize: '12px' }} ellipsis title={fileName}>
                                    فایل {idx + 1}: {fileName}
                                  </Text>
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
                  مرحله بعد: تایید فنی و انتشار عمومی پروژه
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

