import { useState } from 'react';
import { Card, Table, Tag, Button, Typography, Segmented, Row, Col } from 'antd';
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

  const pendingCount = inquiries.filter(i => i.status === 'PENDING_ESTIMATION' || i.status === 'ESTIMATED').length;
  const broadcastedCount = inquiries.filter(i => i.status === 'BROADCASTED').length;
  const closedCount = inquiries.filter(i => i.status === 'CLOSED' || i.status === 'EXPIRED' || i.status === 'REJECTED').length;

  const getSubTabInquiries = () => {
    if (projectSubTab === 'pending') {
      return inquiries.filter(i => i.status === 'PENDING_ESTIMATION' || i.status === 'ESTIMATED');
    } else if (projectSubTab === 'broadcasted') {
      return inquiries.filter(i => i.status === 'BROADCASTED');
    } else {
      return inquiries.filter(i => i.status === 'CLOSED' || i.status === 'EXPIRED' || i.status === 'REJECTED');
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
        <Text strong>{inq.items?.length || 0} ردیف</Text>
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
          <Col xs={24} sm={12}>
            <Title level={5} style={{ margin: 0 }}>مدیریت استعلام‌ها و پروژه‌ها</Title>
          </Col>
          <Col xs={24} sm={12} style={{ textAlign: 'left' }}>
            <Segmented
              value={projectSubTab}
              onChange={(val) => setProjectSubTab(val as any)}
              options={[
                { label: `در انتظار (${pendingCount})`, value: 'pending' },
                { label: `منتشرشده (${broadcastedCount})`, value: 'broadcasted' },
                { label: `خاتمه‌یافته (${closedCount})`, value: 'closed' },
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
        scroll={{ x: true }}
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
