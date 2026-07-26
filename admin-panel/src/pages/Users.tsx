import { useState } from 'react';
import { Card, Table, Tag, Avatar, Button, Space, Typography, Popconfirm, Input, Row, Col } from 'antd';
import { UserOutlined, EyeOutlined, LockOutlined, UnlockOutlined, DeleteOutlined, SearchOutlined } from '@ant-design/icons';
import { BASE_URL } from '../api';
import ViewUserHistoryModal from '../modals/ViewUserHistoryModal';

const { Title, Text } = Typography;

interface UsersProps {
  usersList: any[];
  onDeleteUser: (id: string) => Promise<void>;
  onToggleBlockUser: (id: string, isBlocked: boolean) => Promise<void>;
}

export default function Users({ usersList, onDeleteUser, onToggleBlockUser }: UsersProps) {
  const [selectedUserId, setSelectedUserId] = useState<string | null>(null);
  const [searchText, setSearchText] = useState('');

  const filteredUsers = usersList.filter((usr) => {
    if (!searchText) return true;
    const term = searchText.toLowerCase();
    return (
      usr.name?.toLowerCase().includes(term) ||
      usr.phone_number?.includes(term) ||
      usr.province?.toLowerCase().includes(term) ||
      usr.city?.toLowerCase().includes(term)
    );
  });

  const columns = [
    {
      title: 'کاربر',
      key: 'user',
      render: (_: any, usr: any) => (
        <Space size="middle">
          <Avatar 
            size={40} 
            src={usr.profile_picture_url ? `${BASE_URL}${usr.profile_picture_url}` : undefined} 
            icon={!usr.profile_picture_url ? <UserOutlined /> : undefined} 
          />
          <div>
            <Space size="small">
              <Text strong>{usr.name}</Text>
              {usr.is_blocked && <Tag color="error">مسدود شده</Tag>}
            </Space>
          </div>
        </Space>
      ),
    },
    {
      title: 'شماره همراه',
      dataIndex: 'phone_number',
      key: 'phone_number',
      render: (phone: string) => <Text dir="ltr">{phone}</Text>,
    },
    {
      title: 'نقش فعال',
      dataIndex: 'role',
      key: 'role',
      render: (role: string) => (
        <Tag color={role === 'WELDER' ? 'processing' : 'success'}>
          {role === 'WELDER' ? 'جوشکار' : 'کارفرما'}
        </Tag>
      ),
    },
    {
      title: 'موقعیت',
      key: 'location',
      render: (_: any, usr: any) => (
        <Text type="secondary">
          {usr.province || usr.city ? `${usr.province || ''}، ${usr.city || ''}` : 'نامشخص'}
        </Text>
      ),
    },
    {
      title: 'نقش‌ها',
      dataIndex: 'roles',
      key: 'roles',
      render: (roles: string[]) => (
        <Space size={4} wrap>
          {(roles || []).map((r) => (
            <Tag key={r}>{r === 'WELDER' ? 'جوشکار' : 'کارفرما'}</Tag>
          ))}
        </Space>
      ),
    },
    {
      title: 'عضویت',
      dataIndex: 'created_at',
      key: 'created_at',
      render: (date: string) => <Text type="secondary">{new Date(date).toLocaleDateString('fa-IR')}</Text>,
    },
    {
      title: 'عملیات',
      key: 'actions',
      align: 'left' as const,
      render: (_: any, usr: any) => (
        <Space size="small" wrap>
          <Button
            size="small"
            icon={<EyeOutlined />}
            onClick={() => setSelectedUserId(usr.id)}
          >
            سابقه
          </Button>
          <Button
            size="small"
            type={usr.is_blocked ? 'primary' : 'default'}
            danger={!usr.is_blocked}
            icon={usr.is_blocked ? <UnlockOutlined /> : <LockOutlined />}
            onClick={() => onToggleBlockUser(usr.id, !usr.is_blocked)}
          >
            {usr.is_blocked ? 'رفع مسدودیت' : 'مسدودسازی'}
          </Button>
          <Popconfirm
            title="حذف کامل کاربر"
            description="آیا از حذف کامل این کاربر به همراه تمامی استعلام‌ها اطمینان دارید؟"
            onConfirm={() => onDeleteUser(usr.id)}
            okText="بله، حذف کن"
            cancelText="خیر"
            okButtonProps={{ danger: true }}
          >
            <Button size="small" danger icon={<DeleteOutlined />}>
              حذف
            </Button>
          </Popconfirm>
        </Space>
      ),
    },
  ];

  return (
    <Card 
      title={
        <Row justify="space-between" align="middle" gutter={[12, 12]}>
          <Col xs={24} sm={12}>
            <Title level={5} style={{ margin: 0 }}>لیست کاربران پلتفرم ({usersList.length} نفر)</Title>
          </Col>
          <Col xs={24} sm={12}>
            <Input 
              prefix={<SearchOutlined />} 
              placeholder="جستجو نام، شماره یا شهر..." 
              value={searchText}
              onChange={(e) => setSearchText(e.target.value)}
              allowClear
            />
          </Col>
        </Row>
      }
    >
      <Table
        dataSource={filteredUsers}
        columns={columns}
        rowKey="id"
        pagination={{ pageSize: 10, responsive: true }}
        scroll={{ x: true }}
        size="middle"
      />

      {selectedUserId && (
        <ViewUserHistoryModal 
          userId={selectedUserId} 
          onClose={() => setSelectedUserId(null)} 
        />
      )}
    </Card>
  );
}
