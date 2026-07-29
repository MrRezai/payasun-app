import { useState } from 'react';
import { Modal, Row, Col, Card, Input, InputNumber, Select, Button, Space, Typography, Alert, Tag } from 'antd';
import { PlusOutlined, DeleteOutlined, CheckCircleOutlined, FilePdfOutlined, PictureOutlined, DownloadOutlined, BuildOutlined, FileZipOutlined, FileTextOutlined, FolderOpenOutlined } from '@ant-design/icons';
import { BASE_URL } from '../api';
import { Inquiry, InquiryItem, SupplyItem } from '../types';

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

interface EstimateProjectModalProps {
  inquiry: Inquiry;
  supplyItems?: SupplyItem[];
  onClose: () => void;
  onSubmitEstimation: (inqId: string, items: InquiryItem[]) => Promise<void>;
  onRejectInquiry: (inqId: string, reason: string) => Promise<void>;
}

export default function EstimateProjectModal({
  inquiry,
  supplyItems = [],
  onClose,
  onSubmitEstimation,
  onRejectInquiry,
}: EstimateProjectModalProps) {
  // Predefined items state: items defined in Settings
  const [predefinedItems, setPredefinedItems] = useState<InquiryItem[]>(() => {
    const existingMap = new Map<string, InquiryItem>();
    if (inquiry.items) {
      inquiry.items.forEach(it => existingMap.set(it.title.trim(), it));
    }
    return supplyItems.map(s => {
      const match = existingMap.get(s.title.trim());
      const firstUnit = (s.unit || 'متر').split(/[,،/]+/)[0]?.trim() || 'متر';
      return {
        title: s.title,
        unit: match ? match.unit : firstUnit,
        quantity: match ? match.quantity : 0,
        price: 0,
      };
    });
  });

  // Custom items state: items added manually by admin or non-settings items from existing inquiry
  const [customItems, setCustomItems] = useState<InquiryItem[]>(() => {
    if (!inquiry.items) return [];
    const supplyTitles = new Set(supplyItems.map(s => s.title.trim()));
    return inquiry.items.filter(it => !supplyTitles.has(it.title.trim()));
  });

  const [showRejectionForm, setShowRejectionForm] = useState(false);
  const [showConfirmStep, setShowConfirmStep] = useState(false);
  const [rejectionReason, setRejectionReason] = useState('');

  const handlePredefinedQuantityChange = (index: number, quantity: number) => {
    setPredefinedItems(prev => prev.map((item, i) => i === index ? { ...item, quantity } : item));
  };

  const handlePredefinedUnitChange = (index: number, unit: string) => {
    setPredefinedItems(prev => prev.map((item, i) => i === index ? { ...item, unit } : item));
  };

  const addCustomRow = () => {
    setCustomItems(prev => [...prev, { title: '', unit: 'متر', quantity: 1, price: 0 }]);
  };

  const removeCustomRow = (index: number) => {
    setCustomItems(prev => prev.filter((_, i) => i !== index));
  };

  const handleCustomRowChange = (index: number, field: keyof InquiryItem, value: any) => {
    setCustomItems(prev => prev.map((item, i) => i === index ? { ...item, [field]: value } : item));
  };

  const getSelectedItems = (): InquiryItem[] => {
    const activePredefined = predefinedItems
      .filter(item => item.quantity > 0)
      .map(item => ({
        title: item.title,
        unit: item.unit,
        quantity: item.quantity,
        price: 0,
      }));

    const activeCustom = customItems
      .filter(item => item.title.trim().length > 0 && item.quantity > 0)
      .map(item => ({
        title: item.title.trim(),
        unit: item.unit,
        quantity: item.quantity,
        price: 0,
      }));

    return [...activePredefined, ...activeCustom];
  };

  const handleApproveInitial = () => {
    // 1. Check custom items completeness
    const invalidCustom = customItems.some(item => {
      const hasTitle = item.title.trim().length > 0;
      const hasQty = item.quantity > 0;
      const hasUnit = item.unit && item.unit.trim().length > 0;
      // If title or quantity is entered, all 3 must be valid
      if (hasTitle || hasQty) {
        return !hasTitle || !hasQty || !hasUnit;
      }
      return false;
    });

    if (invalidCustom) {
      alert('لطفاً عنوان، واحد و تعداد تمام اقلام سفارشی افزوده‌شده را به طور کامل مشخص کنید.');
      return;
    }

    // 2. Check predefined active items
    const activePredefined = predefinedItems.filter(item => item.quantity > 0);
    const invalidPredefined = activePredefined.some(item => !item.unit || item.unit.trim().length === 0);
    if (invalidPredefined) {
      alert('لطفاً واحد سنجش تمام اقلام انتخابی را مشخص کنید.');
      return;
    }

    const selected = getSelectedItems();
    if (selected.length === 0) {
      alert('لطفاً حداقل مقدار/تعداد یک قلم فنی را به طور کامل مشخص کنید.');
      return;
    }

    setShowConfirmStep(true);
  };

  const handleApproveFinal = () => {
    const selected = getSelectedItems();
    onSubmitEstimation(inquiry.id, selected);
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

  const selectedItems = getSelectedItems();

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
            description={`آیا از ثبت برآورد کارشناسی پروژه «${inquiry.title}» اطمینان دارید؟ با تایید این مرحله، تعداد ${selectedItems.length} قلم فنی جهت بررسی، ویرایش احتمالی و انتشار نهایی برای کارفرما ارسال خواهد شد.`}
            type="info"
            showIcon
            closable
            icon={<CheckCircleOutlined />}
          />

          <Card size="small" title="خلاصه اقلام فنی آماده ارسال به کارفرما:">
            <div style={{ maxHeight: '200px', overflowY: 'auto' }}>
              {selectedItems.map((item, idx) => (
                <Row key={idx} justify="space-between" style={{ padding: '8px 4px', borderBottom: '1px dashed #f0f0f0' }}>
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
          {inquiry.project ? (
            <Alert
              type="info"
              showIcon
              message={
                <Space direction="vertical" style={{ width: '100%' }}>
                  <Text strong style={{ fontSize: '14px', color: '#1E3A8A' }}>
                    پروژه والد: {inquiry.project.title}
                  </Text>
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
                          <Col xs={24} key={idx}>
                            <Card
                              size="small"
                              style={{
                                borderRadius: '10px',
                                border: '1px solid #e2e8f0',
                                backgroundColor: '#ffffff',
                                boxShadow: '0 1px 2px rgba(0,0,0,0.03)',
                              }}
                              bodyStyle={{ padding: '10px 12px' }}
                            >
                              <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: '8px', flexWrap: 'wrap' }}>
                                <div style={{ display: 'flex', alignItems: 'center', gap: '8px', flex: '1 1 160px', minWidth: 0 }}>
                                  {getFileIcon(rawUrl)}
                                  <Text
                                    ellipsis={{ tooltip: fileName }}
                                    style={{ fontSize: '12px', fontWeight: 600, color: '#1e293b', flex: 1, minWidth: 0 }}
                                  >
                                    {fileName}
                                  </Text>
                                </div>
                                <Button
                                  type="primary"
                                  ghost
                                  size="small"
                                  icon={<DownloadOutlined />}
                                  href={fileUrl}
                                  target="_blank"
                                  rel="noopener noreferrer"
                                  download
                                  style={{ borderRadius: '6px', fontSize: '11px', flexShrink: 0 }}
                                >
                                  دانلود / مشاهده
                                </Button>
                              </div>
                            </Card>
                          </Col>
                        );
                      })}
                    </Row>
                  </div>
                );
              })() : (
                <Card style={{ backgroundColor: '#f8fafc', borderRadius: '12px', border: '1px solid #e2e8f0' }}>
                  <Text strong style={{ fontSize: '13px', color: '#1E3A8A', display: 'block', marginBottom: '8px' }}>
                    اقلام اولیه ثبت‌شده توسط کارفرما:
                  </Text>
                  {inquiry.items && inquiry.items.length > 0 ? (
                    inquiry.items.map((item, idx) => (
                      <div key={idx} style={{ padding: '4px 0', borderBottom: '1px dashed #e2e8f0' }}>
                        <Text style={{ fontSize: '12px' }}>• {item.title}: </Text>
                        <Text strong style={{ fontSize: '12px', color: '#4169E1' }}>{item.quantity} {item.unit}</Text>
                      </div>
                    ))
                  ) : (
                    <Text type="secondary" style={{ fontSize: '12px' }}>هیچ قلمی ثبت نشده است.</Text>
                  )}
                </Card>
              )}
            </Col>

            <Col xs={24} md={12}>
              <Card size="small" style={{ height: '100%', borderRadius: '12px' }}>
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
              <Tag color="blue" style={{ borderRadius: '6px' }}>انتخاب‌شده: {selectedItems.length} قلم</Tag>
            </Row>

            {/* Predefined Supply Items from Settings */}
            {predefinedItems.length > 0 && (
              <Card size="small" style={{ marginBottom: '16px', borderRadius: '12px', border: '1px solid #e5e7eb', backgroundColor: '#ffffff' }}>
                <Text strong style={{ fontSize: '13px', color: '#1f2937', marginBottom: '12px', display: 'block' }}>
                  اقلام فنی عمومی (تعریف‌شده در تنظیمات سیستم):
                </Text>
                <Row gutter={[12, 12]}>
                  {predefinedItems.map((item, idx) => {
                    const origSupplyItem = supplyItems.find(s => s.title.trim() === item.title.trim());
                    const rawUnits = origSupplyItem?.unit || item.unit || 'متر';
                    const availableUnits = rawUnits.split(/[,،/]+/).map(u => u.trim()).filter(Boolean);
                    const currentUnit = item.unit || availableUnits[0] || 'متر';
                    const isActive = item.quantity > 0;

                    return (
                      <Col xs={24} sm={12} key={idx}>
                        <div
                          style={{
                            display: 'flex',
                            alignItems: 'center',
                            justifyContent: 'space-between',
                            padding: '10px 12px',
                            borderRadius: '10px',
                            backgroundColor: isActive ? '#f0fdf4' : '#f9fafb',
                            border: isActive ? '1.5px solid #22c55e' : '1px solid #e5e7eb',
                            transition: 'all 0.2s',
                          }}
                        >
                          <div style={{ flex: 1, paddingLeft: '8px', overflow: 'hidden' }}>
                            <Text strong style={{ fontSize: '12px', color: isActive ? '#15803d' : '#374151', display: 'block' }}>
                              {item.title}
                            </Text>
                            <Space size={4} style={{ marginTop: '4px' }} wrap>
                              {availableUnits.map((u) => {
                                const isSelected = currentUnit === u;
                                return (
                                  <Tag
                                    key={u}
                                    style={{
                                      cursor: 'pointer',
                                      borderRadius: '4px',
                                      fontSize: '10px',
                                      fontWeight: isSelected ? 'bold' : 'normal',
                                      marginRight: 0,
                                      border: isSelected ? '1px solid #3b82f6' : '1px solid #d1d5db',
                                      backgroundColor: isSelected ? '#eff6ff' : '#ffffff',
                                      color: isSelected ? '#1d4ed8' : '#6b7280',
                                      userSelect: 'none',
                                    }}
                                    onClick={() => handlePredefinedUnitChange(idx, u)}
                                  >
                                    {u}
                                  </Tag>
                                );
                              })}
                            </Space>
                          </div>
                          <InputNumber
                            min={0}
                            size="small"
                            style={{ width: '85px' }}
                            placeholder="تعداد"
                            value={item.quantity === 0 ? undefined : item.quantity}
                            onChange={(val) => handlePredefinedQuantityChange(idx, val || 0)}
                          />
                        </div>
                      </Col>
                    );
                  })}
                </Row>
              </Card>
            )}

            {/* Custom Items Section */}
            <div style={{ marginBottom: '12px' }}>
              <Row justify="space-between" align="middle" style={{ marginBottom: '8px' }}>
                <Text strong style={{ fontSize: '13px', color: '#1f2937' }}>
                  اقلام و خدمات سفارشی (اختصاصی این پروژه):
                </Text>
                <Button
                  type="primary"
                  ghost
                  icon={<PlusOutlined />}
                  size="small"
                  onClick={addCustomRow}
                  style={{ borderRadius: '6px' }}
                >
                  افزودن قلم سفارشی
                </Button>
              </Row>

              {customItems.length > 0 && (
                <div style={{ maxHeight: '200px', overflowY: 'auto', paddingRight: '2px' }}>
                  {customItems.map((item, idx) => (
                    <Card key={idx} size="small" style={{ marginBottom: '8px', backgroundColor: '#fafafa', borderRadius: '8px' }}>
                      <Row gutter={[8, 8]} align="middle">
                        <Col xs={24} sm={11}>
                          <Input
                            placeholder="عنوان قلم سفارشی (مثال: ساخت پایه بتنی اختصاصی)"
                            value={item.title}
                            onChange={(e) => handleCustomRowChange(idx, 'title', e.target.value)}
                          />
                        </Col>
                        <Col xs={12} sm={6}>
                          <Select
                            style={{ width: '100%' }}
                            value={item.unit}
                            onChange={(val) => handleCustomRowChange(idx, 'unit', val)}
                            options={unitOptions}
                          />
                        </Col>
                        <Col xs={12} sm={5}>
                          <InputNumber
                            min={1}
                            style={{ width: '100%' }}
                            placeholder="تعداد"
                            value={item.quantity}
                            onChange={(val) => handleCustomRowChange(idx, 'quantity', val || 1)}
                          />
                        </Col>
                        <Col xs={24} sm={2} style={{ textAlign: 'left' }}>
                          <Button
                            danger
                            icon={<DeleteOutlined />}
                            onClick={() => removeCustomRow(idx)}
                            block
                          />
                        </Col>
                      </Row>
                    </Card>
                  ))}
                </div>
              )}
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
                  <Button danger type="primary" onClick={handleReject} disabled={!rejectionReason.trim()}>
                    ثبت رد پروژه
                  </Button>
                  <Button onClick={() => setShowRejectionForm(false)}>
                    انصراف
                  </Button>
                </Row>
              </Space>
            ) : (
              <Row justify="space-between" align="middle">
                <Button danger onClick={() => setShowRejectionForm(true)}>
                  رد کردن پروژه / نقشه خوانا نیست
                </Button>
                <Space>
                  <Button onClick={onClose}>
                    انصراف
                  </Button>
                  <Button type="primary" onClick={handleApproveInitial} style={{ fontWeight: 'bold', backgroundColor: '#4169E1' }}>
                    تایید اقلام و مرحله بعدی ({selectedItems.length} قلم)
                  </Button>
                </Space>
              </Row>
            )}
          </div>
        </Space>
      )}
    </Modal>
  );
}
