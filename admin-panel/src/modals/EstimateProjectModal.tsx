import { useState } from 'react';
import { Modal, Row, Col, Card, Input, InputNumber, Select, Button, Space, Typography, Alert } from 'antd';
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
      width={800}
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
            {/* Blueprint Section */}
            <Col xs={24} md={12}>
              <Text type="secondary" style={{ fontSize: '13px', display: 'block', marginBottom: '8px' }}>
                فایل نقشه پروژه (Blueprint)
              </Text>
              {inquiry.has_blueprint ? (() => {
                const isPdf = inquiry.blueprint_url?.toLowerCase().endsWith('.pdf');
                const fileUrl = inquiry.blueprint_url 
                  ? (inquiry.blueprint_url.startsWith('http') ? inquiry.blueprint_url : `${BASE_URL}${inquiry.blueprint_url}`)
                  : '';
                
                if (isPdf) {
                  return (
                    <Card style={{ textAlign: 'center', height: '200px', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                      <FilePdfOutlined style={{ fontSize: '42px', color: '#e74c3c', marginBottom: '8px' }} />
                      <Text strong style={{ display: 'block', marginBottom: '8px' }}>فایل نقشه فنی PDF است</Text>
                      <Button type="primary" danger size="small" href={fileUrl} target="_blank">
                        دانلود و مشاهده PDF
                      </Button>
                    </Card>
                  );
                }

                return (
                  <div style={{ position: 'relative', height: '200px', borderRadius: '12px', overflow: 'hidden', border: '1px solid #f0f0f0' }}>
                    <img 
                      src={fileUrl} 
                      alt="Blueprint" 
                      style={{ width: '100%', height: '100%', objectFit: 'cover' }}
                    />
                    <Button 
                      size="small" 
                      type="primary" 
                      href={fileUrl} 
                      target="_blank"
                      icon={<PictureOutlined />}
                      style={{ position: 'absolute', bottom: '8px', left: '8px', opacity: 0.9 }}
                    >
                      مشاهده سایز اصلی
                    </Button>
                  </div>
                );
              })() : (
                <Card style={{ textAlign: 'center', height: '200px', display: 'flex', alignItems: 'center', justifyContent: 'center', backgroundColor: '#fafafa' }}>
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

