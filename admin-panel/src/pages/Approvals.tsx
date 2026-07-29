import { Card, Table, Tag, Avatar, Button, Space, Typography, Image, Badge } from 'antd';
import { UserOutlined, PictureOutlined } from '@ant-design/icons';
import { BASE_URL } from '../api';

const { Title, Text } = Typography;

interface ApprovalsProps {
  pendingVerifications: any[];
  onSelectVerification: (user: any) => void;
}

export default function Approvals({
  pendingVerifications,
  onSelectVerification,
}: ApprovalsProps) {
  const columns = [
    {
      title: 'کاربر',
      key: 'user',
      render: (_: any, user: any) => (
        <Space size="middle">
          <Avatar size={40} icon={<UserOutlined />} />
          <Text strong>{user.name}</Text>
        </Space>
      ),
    },
    {
      title: 'نقش کاربری',
      dataIndex: 'role',
      key: 'role',
      render: (role: string) => (
        <Tag color={role === 'WELDER' ? 'processing' : 'success'}>
          {role === 'WELDER' ? 'جوشکار' : 'کارفرما'}
        </Tag>
      ),
    },
    {
      title: 'شماره تماس',
      dataIndex: 'phone',
      key: 'phone',
      render: (phone: string) => <Text dir="ltr">{phone}</Text>,
    },
    {
      title: 'تاریخ ارسال / درخواست',
      key: 'created_at',
      render: (_: any, user: any) => {
        const dateStr = user.created_at || user.updated_at
          ? new Date(user.created_at || user.updated_at).toLocaleDateString('fa-IR')
          : 'نامشخص';
        return <Text type="secondary">{dateStr}</Text>;
      },
    },
    {
      title: 'تصویر ارسالی',
      key: 'pending_url',
      render: (_: any, user: any) => (
        user.pending_url ? (
          <Image
            width={48}
            height={48}
            src={user.pending_url.startsWith('http') ? user.pending_url : `${BASE_URL}${user.pending_url}`}
            style={{ borderRadius: 8, objectFit: 'cover' }}
          />
        ) : (
          <Text type="secondary">فاقد فایل</Text>
        )
      ),
    },
    {
      title: 'عملیات بررسی',
      key: 'actions',
      align: 'left' as const,
      render: (_: any, user: any) => (
        <Button
          type="primary"
          icon={<PictureOutlined />}
          onClick={() => onSelectVerification(user)}
        >
          بررسی تصویر
        </Button>
      ),
    },
  ];

  return (
    <Card 
      title={
        <Space align="center" size="middle">
          <Title level={5} style={{ margin: 0 }}>کاربران معلق احراز هویت تصویر پروفایل</Title>
          <Badge count={pendingVerifications.length} overflowCount={999} showZero style={{ backgroundColor: pendingVerifications.length > 0 ? '#F59E0B' : '#94A3B8' }} />
        </Space>
      }
    >
      <Table
        dataSource={pendingVerifications}
        columns={columns}
        rowKey="id"
        pagination={{ pageSize: 8, responsive: true }}
        scroll={{ x: 'max-content' }}
        size="middle"
      />
    </Card>
  );
}
