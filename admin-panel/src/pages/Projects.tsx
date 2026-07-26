import { useState } from 'react';
import { Card, Table, Tag, Button, Typography, Segmented, Row, Col, Badge, Space } from 'antd';
import { EyeOutlined, FormOutlined } from '@ant-design/icons';
import { Inquiry } from '../types';
import ViewUserHistoryModal from '../modals/ViewUserHistoryModal';

const { Title, Text } = Typography;

interface ProjectsProps {
  inquiries: Inquiry[];
  onEstimateClick: (inq: Inquiry) => void;
  onViewDetailClick: (inq: Inquiry) => void;
}

export default function Projects({ inquiries, onEstimateClick, onViewDetailClick }: ProjectsProps) {
  const [projectSubTab, setProjectSubTab] = useState<'pending' | 'broadcasted' | 'closed'>('pending');
  const [selectedEmployerId, setSelectedEmployerId] = useState<string | null>(null);

  const pendingInquiries = inquiries.filter(i => i.status === 'PENDING_ESTIMATION');
  const broadcastedInquiries = inquiries.filter(i => i.status === 'BROADCASTED' || i.status === 'ESTIMATED');
  const closedInquiries = inquiries.filter(i => i.status === 'CLOSED' || i.status === 'EXPIRED' || i.status === 'REJECTED');

  const pendingCount = pendingInquiries.length;
  const broadcastedCount = broadcastedInquiries.length;
  const closedCount = closedInquiries.length;

  const getSubTabInquiries = () => {
    if (projectSubTab === 'pending') {
      return pendingInquiries;
    } else if (projectSubTab === 'broadcasted') {
      return broadcastedInquiries;
    } else {
      return closedInquiries;
    }
  };

  const filteredInquiries = getSubTabInquiries();

  const columns = [
    {
      title: 'عنوان پروژه',
      dataIndex: 'title',
      key: 'title',
      render: (title: string) => <Text strong>{title}</Text>,
    },
    {
      title: 'کارفرما',
      key: 'employer',
      render: (_: any, inq: Inquiry) => (
        inq.employerId ? (
          <Text 
            style={{ color: '#4169E1', cursor: 'pointer', textDecoration: 'underline' }} 
            onClick={() => setSelectedEmployerId(inq.employerId || null)}
          >
            {inq.employer_name || 'کارفرمای پلتفرم'}
          </Text>
        ) : (
          <Text>{inq.employer_name || 'کارفرمای پلتفرم'}</Text>
        )
      ),
    },
    {
      title: 'موقعیت',
      key: 'location',
      render: (_: any, inq: Inquiry) => (
        <Text type="secondary">{inq.province || 'نامشخص'}، {inq.city || 'نامشخص'}</Text>
      ),
    },
    {
      title: 'نوع نقشه',
      key: 'blueprint',
      render: (_: any, inq: Inquiry) => (
        inq.has_blueprint ? (
          <Tag color="blue">فایل نقشه فنی</Tag>
        ) : (
          <Tag>ورود دستی</Tag>
        )
      ),
    },
    {
      title: 'تعداد اقلام',
      key: 'items_count',
      render: (_: any, inq: Inquiry) => (
        <Badge count={inq.items?.length || 0} showZero style={{ backgroundColor: '#4169E1' }} />
      ),
    },
    {
      title: 'وضعیت فنی',
      key: 'status',
      render: (_: any, inq: Inquiry) => {
        if (inq.status === 'PENDING_ESTIMATION') return <Tag color="warning">در انتظار کارشناسی</Tag>;
        if (inq.status === 'ESTIMATED') return <Tag color="gold">کارشناسی‌شده</Tag>;
        if (inq.status === 'BROADCASTED') return <Tag color="success">انتشار یافته</Tag>;
        if (inq.status === 'REJECTED') return <Tag color="error">رد شده</Tag>;
        return <Tag>خاتمه‌یافته</Tag>;
      },
    },
    {
      title: 'عملیات',
      key: 'actions',
      align: 'left' as const,
      render: (_: any, inq: Inquiry) => (
        inq.status === 'PENDING_ESTIMATION' ? (
          <Button
            type="primary"
            size="small"
            icon={<FormOutlined />}
            onClick={() => onEstimateClick(inq)}
            style={{ fontWeight: 'bold' }}
          >
            افزودن اقلام و انتشار
          </Button>
        ) : (
          <Button
            size="small"
            icon={<EyeOutlined />}
            onClick={() => onViewDetailClick(inq)}
          >
            مشاهده اقلام
          </Button>
        )
      ),
    },
  ];

  return (
    <Card 
      title={
        <Row justify="space-between" align="middle" gutter={[12, 12]}>
          <Col xs={24} sm={10}>
            <Title level={5} style={{ margin: 0 }}>مدیریت استعلام‌ها و پروژه‌ها</Title>
          </Col>
          <Col xs={24} sm={14} style={{ textAlign: 'left' }}>
            <Segmented
              value={projectSubTab}
              onChange={(val) => setProjectSubTab(val as any)}
              options={[
                {
                  label: (
                    <Space size={6}>
                      <span>در انتظار</span>
                      <Badge count={pendingCount} overflowCount={999} style={{ backgroundColor: pendingCount > 0 ? '#EF4444' : '#94A3B8' }} />
                    </Space>
                  ),
                  value: 'pending',
                },
                {
                  label: (
                    <Space size={6}>
                      <span>منتشرشده</span>
                      <Badge count={broadcastedCount} overflowCount={999} style={{ backgroundColor: '#10B981' }} />
                    </Space>
                  ),
                  value: 'broadcasted',
                },
                {
                  label: (
                    <Space size={6}>
                      <span>خاتمه‌یافته</span>
                      <Badge count={closedCount} overflowCount={999} style={{ backgroundColor: '#64748B' }} />
                    </Space>
                  ),
                  value: 'closed',
                },
              ]}
            />
          </Col>
        </Row>
      }
    >
      <Table
        dataSource={filteredInquiries}
        columns={columns}
        rowKey="id"
        pagination={{ pageSize: 10, responsive: true }}
        scroll={{ x: 'max-content' }}
        size="middle"
      />

      {selectedEmployerId && (
        <ViewUserHistoryModal 
          userId={selectedEmployerId} 
          onClose={() => setSelectedEmployerId(null)} 
        />
      )}
    </Card>
  );
}
