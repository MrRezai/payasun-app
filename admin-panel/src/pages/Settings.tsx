import { useEffect, useState } from 'react';
import { Tabs, Row, Col, Card, Form, Input, Button, Table, Space, Typography, Popconfirm, Badge, Alert, Switch } from 'antd';
import { PlusOutlined, EditOutlined, DeleteOutlined, CheckOutlined, CloseOutlined, SettingOutlined, AppstoreOutlined, BuildOutlined, BulbOutlined, SaveOutlined } from '@ant-design/icons';
import { Skill, SupplyItem } from '../types';
import { ApiClient } from '../api';

const { Title, Text } = Typography;

interface SettingsProps {
  skills: Skill[];
  supplyItems: SupplyItem[];
  onAddSkill: (name: string) => Promise<void>;
  onEditSkill: (id: number, name: string) => Promise<void>;
  onDeleteSkill: (id: number) => Promise<void>;
  onAddSupplyItem: (title: string, unit: string) => Promise<void>;
  onEditSupplyItem: (id: number, title: string, unit: string) => Promise<void>;
  onDeleteSupplyItem: (id: number) => Promise<void>;
}

export default function Settings({
  skills,
  supplyItems,
  onAddSkill,
  onEditSkill,
  onDeleteSkill,
  onAddSupplyItem,
  onEditSupplyItem,
  onDeleteSupplyItem,
}: SettingsProps) {
  const [activeTab, setActiveTab] = useState('tips');

  // Tip states
  const [employerTipEnabled, setEmployerTipEnabled] = useState(true);
  const [employerTipTitle, setEmployerTipTitle] = useState('راهنمای برآورد دقیق جوشکاری');
  const [employerTipText, setEmployerTipText] = useState('با بارگذاری نقشه‌های باکیفیت و تعیین طول دقیق شاسی، مقادیر مصرفی الکترود و آهن‌آلات را دقیق‌تر دریافت کنید.');
  
  const [welderTipEnabled, setWelderTipEnabled] = useState(true);
  const [welderTipTitle, setWelderTipTitle] = useState('راهنمای دریافت بیشتر پروژه');
  const [welderTipText, setWelderTipText] = useState('با تکمیل دقیق تخصص‌ها، سوابق کاری و پروژه‌ها، پیشنهادهای قیمت شما شانس بیشتری برای انتخاب توسط کارفرمایان دارند.');
  const [tipAlert, setTipAlert] = useState<{ type: 'success' | 'error'; message: string } | null>(null);
  const [tipSaving, setTipSaving] = useState(false);

  useEffect(() => {
    ApiClient.getTips().then((data) => {
      if (data) {
        if (data.employer_enabled !== undefined) setEmployerTipEnabled(!!data.employer_enabled);
        if (data.employer_title) setEmployerTipTitle(data.employer_title);
        if (data.employer_text) setEmployerTipText(data.employer_text);
        if (data.welder_enabled !== undefined) setWelderTipEnabled(!!data.welder_enabled);
        if (data.welder_title) setWelderTipTitle(data.welder_title);
        if (data.welder_text) setWelderTipText(data.welder_text);
      }
    }).catch(() => {});
  }, []);

  const handleSaveTips = async () => {
    setTipSaving(true);
    const payload = {
      employer_enabled: employerTipEnabled,
      employer_title: employerTipTitle,
      employer_text: employerTipText,
      welder_enabled: welderTipEnabled,
      welder_title: welderTipTitle,
      welder_text: welderTipText,
    };
    try {
      await ApiClient.updateTips(payload);
      setTipAlert({ type: 'success', message: 'تنظیمات راهنماها در دیتابیس با موفقیت ذخیره و به‌روزرسانی شدند.' });
    } catch (e: any) {
      setTipAlert({ type: 'error', message: e.message || 'خطا در ثبت تنظیمات در دیتابیس.' });
    } finally {
      setTipSaving(false);
    }
    setTimeout(() => setTipAlert(null), 4000);
  };

  // Skill states
  const [skillForm] = Form.useForm();
  const [skillLoading, setSkillLoading] = useState(false);
  const [editingSkillId, setEditingSkillId] = useState<number | null>(null);
  const [editingSkillName, setEditingSkillName] = useState('');

  // Item states
  const [itemForm] = Form.useForm();
  const [itemLoading, setItemLoading] = useState(false);
  const [editingItemId, setEditingItemId] = useState<number | null>(null);
  const [editingItemTitle, setEditingItemTitle] = useState('');
  const [editingItemUnit, setEditingItemUnit] = useState('');

  // Handlers for Skills
  const handleAddSkillSubmit = async (values: { name: string }) => {
    if (!values.name?.trim()) return;
    setSkillLoading(true);
    try {
      await onAddSkill(values.name.trim());
      skillForm.resetFields();
    } finally {
      setSkillLoading(false);
    }
  };

  const handleStartEditSkill = (skill: Skill) => {
    setEditingSkillId(skill.id);
    setEditingSkillName(skill.name);
  };

  const handleSaveSkill = async (id: number) => {
    if (!editingSkillName.trim()) return;
    await onEditSkill(id, editingSkillName.trim());
    setEditingSkillId(null);
  };

  // Handlers for Items
  const handleAddItemSubmit = async (values: { title: string; unit: string }) => {
    if (!values.title?.trim() || !values.unit?.trim()) return;
    setItemLoading(true);
    try {
      await onAddSupplyItem(values.title.trim(), values.unit.trim());
      itemForm.resetFields();
    } finally {
      setItemLoading(false);
    }
  };

  const handleStartEditItem = (item: SupplyItem) => {
    setEditingItemId(item.id);
    setEditingItemTitle(item.title);
    setEditingItemUnit(item.unit);
  };

  const handleSaveItem = async (id: number) => {
    if (!editingItemTitle.trim() || !editingItemUnit.trim()) return;
    await onEditSupplyItem(id, editingItemTitle.trim(), editingItemUnit.trim());
    setEditingItemId(null);
  };

  // Columns for Skills
  const skillColumns = [
    {
      title: 'شناسه',
      dataIndex: 'id',
      key: 'id',
      width: 90,
      render: (id: number) => <Text type="secondary">#{id}</Text>,
    },
    {
      title: 'عنوان تخصص',
      dataIndex: 'name',
      key: 'name',
      render: (text: string, record: Skill) => {
        if (editingSkillId === record.id) {
          return (
            <Input
              value={editingSkillName}
              onChange={(e) => setEditingSkillName(e.target.value)}
              onPressEnter={() => handleSaveSkill(record.id)}
              autoFocus
            />
          );
        }
        return <Text strong>{text}</Text>;
      },
    },
    {
      title: 'عملیات مدیریتی',
      key: 'actions',
      width: 180,
      align: 'left' as const,
      render: (_: any, record: Skill) => {
        if (editingSkillId === record.id) {
          return (
            <Space size="small">
              <Button type="primary" size="small" icon={<CheckOutlined />} onClick={() => handleSaveSkill(record.id)}>
                ذخیره
              </Button>
              <Button size="small" icon={<CloseOutlined />} onClick={() => setEditingSkillId(null)}>
                انصراف
              </Button>
            </Space>
          );
        }

        return (
          <Space size="small">
            <Button size="small" icon={<EditOutlined />} onClick={() => handleStartEditSkill(record)}>
              ویرایش
            </Button>
            <Popconfirm
              title="حذف تخصص"
              description="آیا از حذف این تخصص اطمینان دارید؟"
              onConfirm={() => onDeleteSkill(record.id)}
              okText="بله، حذف کن"
              cancelText="خیر"
              okButtonProps={{ danger: true }}
            >
              <Button danger size="small" icon={<DeleteOutlined />}>
                حذف
              </Button>
            </Popconfirm>
          </Space>
        );
      },
    },
  ];

  // Columns for Supply Items
  const itemColumns = [
    {
      title: 'شناسه',
      dataIndex: 'id',
      key: 'id',
      width: 90,
      render: (id: number) => <Text type="secondary">#{id}</Text>,
    },
    {
      title: 'عنوان قلم/کالا',
      dataIndex: 'title',
      key: 'title',
      render: (text: string, record: SupplyItem) => {
        if (editingItemId === record.id) {
          return (
            <Input
              value={editingItemTitle}
              onChange={(e) => setEditingItemTitle(e.target.value)}
              placeholder="عنوان قلم"
            />
          );
        }
        return <Text strong>{text}</Text>;
      },
    },
    {
      title: 'واحد(های) سنجش',
      dataIndex: 'unit',
      key: 'unit',
      width: 180,
      render: (text: string, record: SupplyItem) => {
        if (editingItemId === record.id) {
          return (
            <Input
              value={editingItemUnit}
              onChange={(e) => setEditingItemUnit(e.target.value)}
              placeholder="واحدها با کاما (عدد، متر، کیلوگرم)"
            />
          );
        }
        const units = text ? text.split(/[,،]/).map(u => u.trim()).filter(Boolean) : [];
        const colors = ['#4169E1', '#10B981', '#F59E0B', '#8B5CF6', '#EC4899'];
        return (
          <Space wrap size={[4, 4]}>
            {units.length > 0 ? (
              units.map((u, idx) => (
                <Badge
                  key={idx}
                  count={u}
                  style={{ backgroundColor: colors[idx % colors.length] }}
                />
              ))
            ) : (
              <Text type="secondary">-</Text>
            )}
          </Space>
        );
      },
    },
    {
      title: 'عملیات مدیریتی',
      key: 'actions',
      width: 180,
      align: 'left' as const,
      render: (_: any, record: SupplyItem) => {
        if (editingItemId === record.id) {
          return (
            <Space size="small">
              <Button type="primary" size="small" icon={<CheckOutlined />} onClick={() => handleSaveItem(record.id)}>
                ذخیره
              </Button>
              <Button size="small" icon={<CloseOutlined />} onClick={() => setEditingItemId(null)}>
                انصراف
              </Button>
            </Space>
          );
        }

        return (
          <Space size="small">
            <Button size="small" icon={<EditOutlined />} onClick={() => handleStartEditItem(record)}>
              ویرایش
            </Button>
            <Popconfirm
              title="حذف قلم"
              description="آیا از حذف این قلم اطمینان دارید؟"
              onConfirm={() => onDeleteSupplyItem(record.id)}
              okText="بله، حذف کن"
              cancelText="خیر"
              okButtonProps={{ danger: true }}
            >
              <Button danger size="small" icon={<DeleteOutlined />}>
                حذف
              </Button>
            </Popconfirm>
          </Space>
        );
      },
    },
  ];

  return (
    <div style={{ padding: '4px' }}>
      <div style={{ marginBottom: '20px' }}>
        <Title level={4} style={{ margin: 0, display: 'flex', alignItems: 'center', gap: '8px' }}>
          <SettingOutlined style={{ color: '#4169E1' }} />
          تنظیمات سامانه
        </Title>
        <Text type="secondary">مدیریت تخصص‌های جوشکاری و تعریف اقلام استاندارد برای استعلام‌ها</Text>
      </div>

      <Tabs
        activeKey={activeTab}
        onChange={setActiveTab}
        type="card"
        items={[
          {
            key: 'tips',
            label: (
              <span>
                <BulbOutlined /> تنظیم تیپ‌ها و راهنماها
              </span>
            ),
            children: (
              <div style={{ marginTop: '12px' }}>
                {tipAlert && (
                  <Alert
                    message={tipAlert.message}
                    type={tipAlert.type}
                    showIcon
                    style={{ marginBottom: '16px', borderRadius: '8px' }}
                  />
                )}
                <Row gutter={[24, 24]}>
                  {/* Employer Tip Card */}
                  <Col xs={24} lg={12}>
                    <Card
                      title={
                        <Row justify="space-between" align="middle">
                          <Space>
                            <BulbOutlined style={{ color: '#F59E0B' }} />
                            <Title level={5} style={{ margin: 0 }}>
                              راهنمای پنل کارفرما
                            </Title>
                          </Space>
                          <Space>
                            <Text type="secondary" style={{ fontSize: '12px' }}>وضعیت کارت:</Text>
                            <Switch
                              checked={employerTipEnabled}
                              onChange={setEmployerTipEnabled}
                              checkedChildren="فعال"
                              unCheckedChildren="غیرفعال"
                            />
                          </Space>
                        </Row>
                      }
                      style={{ borderRadius: '12px' }}
                    >
                      <Form layout="vertical">
                        <Form.Item label="عنوان کارت راهنما (داشبورد کارفرما)">
                          <Input
                            value={employerTipTitle}
                            onChange={(e) => setEmployerTipTitle(e.target.value)}
                            placeholder="مثال: راهنمای برآورد دقیق جوشکاری"
                          />
                        </Form.Item>
                        <Form.Item label="متن کامل راهنما (داشبورد کارفرما)">
                          <Input.TextArea
                            rows={4}
                            value={employerTipText}
                            onChange={(e) => setEmployerTipText(e.target.value)}
                            placeholder="متن کامل راهنما برای کارفرمایان..."
                          />
                        </Form.Item>
                        <Button
                          type="primary"
                          icon={<SaveOutlined />}
                          loading={tipSaving}
                          onClick={handleSaveTips}
                          style={{ backgroundColor: '#4169E1', fontWeight: 'bold' }}
                          block
                        >
                          ذخیره تغییرات در دیتابیس
                        </Button>
                      </Form>
                    </Card>
                  </Col>

                  {/* Welder Tip Card */}
                  <Col xs={24} lg={12}>
                    <Card
                      title={
                        <Row justify="space-between" align="middle">
                          <Space>
                            <BulbOutlined style={{ color: '#10B981' }} />
                            <Title level={5} style={{ margin: 0 }}>
                              راهنمای پنل جوشکار
                            </Title>
                          </Space>
                          <Space>
                            <Text type="secondary" style={{ fontSize: '12px' }}>وضعیت کارت:</Text>
                            <Switch
                              checked={welderTipEnabled}
                              onChange={setWelderTipEnabled}
                              checkedChildren="فعال"
                              unCheckedChildren="غیرفعال"
                            />
                          </Space>
                        </Row>
                      }
                      style={{ borderRadius: '12px' }}
                    >
                      <Form layout="vertical">
                        <Form.Item label="عنوان کارت راهنما (داشبورد جوشکار)">
                          <Input
                            value={welderTipTitle}
                            onChange={(e) => setWelderTipTitle(e.target.value)}
                            placeholder="مثال: راهنمای افزایش دریافت پروژه"
                          />
                        </Form.Item>
                        <Form.Item label="متن کامل راهنما (داشبورد جوشکار)">
                          <Input.TextArea
                            rows={4}
                            value={welderTipText}
                            onChange={(e) => setWelderTipText(e.target.value)}
                            placeholder="متن کامل راهنما برای جوشکاران..."
                          />
                        </Form.Item>
                        <Button
                          type="primary"
                          icon={<SaveOutlined />}
                          loading={tipSaving}
                          onClick={handleSaveTips}
                          style={{ backgroundColor: '#10B981', borderColor: '#10B981', fontWeight: 'bold' }}
                          block
                        >
                          ذخیره تغییرات در دیتابیس
                        </Button>
                      </Form>
                    </Card>
                  </Col>
                </Row>
              </div>
            ),
          },
          {
            key: 'skills',
            label: (
              <span>
                <BuildOutlined /> مدیریت تخصص‌ها ({skills.length})
              </span>
            ),
            children: (
              <Row gutter={[24, 24]} align="top" style={{ marginTop: '12px' }}>
                <Col xs={24} lg={9}>
                  <Card title={<Title level={5} style={{ margin: 0 }}>افزودن تخصص جوشکاری جدید</Title>}>
                    <Alert
                      message="راهنمای تعریف تخصص"
                      description="عناوین تخصص‌ها را شفاف و استاندارد وارد کنید تا جوشکاران بتوانند به‌درستی مهارت‌های خود را انتخاب نمایند."
                      type="info"
                      showIcon
                      closable
                      style={{ marginBottom: 16 }}
                    />
                    <Form form={skillForm} layout="vertical" onFinish={handleAddSkillSubmit} size="large">
                      <Form.Item
                        label="عنوان تخصص (فارسی)"
                        name="name"
                        rules={[{ required: true, message: 'لطفاً عنوان تخصص را وارد کنید.' }]}
                      >
                        <Input placeholder="مثال: جوشکاری آرگون تحت فشار" />
                      </Form.Item>
                      <Form.Item style={{ marginBottom: 0 }}>
                        <Button
                          type="primary"
                          htmlType="submit"
                          loading={skillLoading}
                          icon={<PlusOutlined />}
                          block
                          style={{ fontWeight: 'bold' }}
                        >
                          ثبت تخصص جدید
                        </Button>
                      </Form.Item>
                    </Form>
                  </Card>
                </Col>

                <Col xs={24} lg={15}>
                  <Card
                    title={
                      <Row justify="space-between" align="middle">
                        <Col>
                          <Space align="center" size="middle">
                            <Title level={5} style={{ margin: 0 }}>لیست کل تخصص‌های مجاز پلتفرم</Title>
                            <Badge count={skills.length} overflowCount={999} showZero style={{ backgroundColor: '#10B981' }} />
                          </Space>
                        </Col>
                      </Row>
                    }
                  >
                    <Table
                      dataSource={skills}
                      columns={skillColumns}
                      rowKey="id"
                      pagination={{ pageSize: 8, responsive: true }}
                      scroll={{ x: 'max-content' }}
                      size="middle"
                    />
                  </Card>
                </Col>
              </Row>
            ),
          },
          {
            key: 'items',
            label: (
              <span>
                <AppstoreOutlined /> مدیریت اقلام ({supplyItems.length})
              </span>
            ),
            children: (
              <Row gutter={[24, 24]} align="top" style={{ marginTop: '12px' }}>
                <Col xs={24} lg={9}>
                  <Card title={<Title level={5} style={{ margin: 0 }}>افزودن قلم کالا / خدمات جدید</Title>}>
                    <Alert
                      message="راهنمای تعریف اقلام"
                      description="اقلام پایه به همراه واحد(های) سنجش تعریف می‌شوند. می‌توانید چند واحد را با کاما جدا کنید (مثال: عدد، متر، کیلوگرم) تا کارفرما بتواند واحد دلخواه را هنگام ثبت انتخاب کند."
                      type="info"
                      showIcon
                      closable
                      style={{ marginBottom: 16 }}
                    />
                    <Form form={itemForm} layout="vertical" onFinish={handleAddItemSubmit} size="large">
                      <Form.Item
                        label="عنوان قلم (کالا / خدمات)"
                        name="title"
                        rules={[{ required: true, message: 'لطفاً عنوان قلم را وارد کنید.' }]}
                      >
                        <Input placeholder="مثال: کپسول گاز آرگون، تیرآهن، ورق سیاه" />
                      </Form.Item>
                      <Form.Item
                        label="واحد(های) سنجش (با کاما جدا کنید)"
                        name="unit"
                        rules={[{ required: true, message: 'لطفاً واحد سنجش را وارد کنید.' }]}
                      >
                        <Input placeholder="مثال: عدد، متر، کیلوگرم، کپسول، شاخه" />
                      </Form.Item>
                      <Form.Item style={{ marginBottom: 0 }}>
                        <Button
                          type="primary"
                          htmlType="submit"
                          loading={itemLoading}
                          icon={<PlusOutlined />}
                          block
                          style={{ fontWeight: 'bold' }}
                        >
                          ثبت قلم جدید
                        </Button>
                      </Form.Item>
                    </Form>
                  </Card>
                </Col>

                <Col xs={24} lg={15}>
                  <Card
                    title={
                      <Row justify="space-between" align="middle">
                        <Col>
                          <Space align="center" size="middle">
                            <Title level={5} style={{ margin: 0 }}>لیست اقلام استاندارد پلتفرم</Title>
                            <Badge count={supplyItems.length} overflowCount={999} showZero style={{ backgroundColor: '#4169E1' }} />
                          </Space>
                        </Col>
                      </Row>
                    }
                  >
                    <Table
                      dataSource={supplyItems}
                      columns={itemColumns}
                      rowKey="id"
                      pagination={{ pageSize: 8, responsive: true }}
                      scroll={{ x: 'max-content' }}
                      size="middle"
                    />
                  </Card>
                </Col>
              </Row>
            ),
          },
        ]}
      />
    </div>
  );
}
