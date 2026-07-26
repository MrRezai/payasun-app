import { useState } from 'react';
import { Row, Col, Card, Form, Input, Button, Table, Space, Typography, Popconfirm, Badge, Alert } from 'antd';
import { PlusOutlined, EditOutlined, DeleteOutlined, CheckOutlined, CloseOutlined } from '@ant-design/icons';
import { Skill } from '../types';

const { Title, Text } = Typography;

interface SkillsProps {
  skills: Skill[];
  onAddSkill: (name: string) => Promise<void>;
  onEditSkill: (id: number, name: string) => Promise<void>;
  onDeleteSkill: (id: number) => Promise<void>;
}

export default function Skills({ skills, onAddSkill, onEditSkill, onDeleteSkill }: SkillsProps) {
  const [form] = Form.useForm();
  const [loading, setLoading] = useState(false);
  const [editingSkillId, setEditingSkillId] = useState<number | null>(null);
  const [editingSkillName, setEditingSkillName] = useState('');

  const handleSubmit = async (values: { name: string }) => {
    if (!values.name?.trim()) return;
    setLoading(true);
    try {
      await onAddSkill(values.name.trim());
      form.resetFields();
    } finally {
      setLoading(false);
    }
  };

  const handleStartEdit = (skill: Skill) => {
    setEditingSkillId(skill.id);
    setEditingSkillName(skill.name);
  };

  const handleSave = async (id: number) => {
    if (!editingSkillName.trim()) return;
    await onEditSkill(id, editingSkillName.trim());
    setEditingSkillId(null);
  };

  const columns = [
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
              onPressEnter={() => handleSave(record.id)}
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
              <Button
                type="primary"
                size="small"
                icon={<CheckOutlined />}
                onClick={() => handleSave(record.id)}
              >
                ذخیره
              </Button>
              <Button
                size="small"
                icon={<CloseOutlined />}
                onClick={() => setEditingSkillId(null)}
              >
                انصراف
              </Button>
            </Space>
          );
        }

        return (
          <Space size="small">
            <Button
              size="small"
              icon={<EditOutlined />}
              onClick={() => handleStartEdit(record)}
            >
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

  return (
    <Row gutter={[24, 24]} align="top">
      {/* Create Skill Form */}
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
          <Form
            form={form}
            layout="vertical"
            onFinish={handleSubmit}
            size="large"
          >
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
                loading={loading}
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

      {/* Skills Table List */}
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
            columns={columns}
            rowKey="id"
            pagination={{ pageSize: 8, responsive: true }}
            scroll={{ x: 'max-content' }}
            size="middle"
          />
        </Card>
      </Col>
    </Row>
  );
}
