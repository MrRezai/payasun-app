import { useState } from 'react';
import { Card, Table, Tag, Button, Typography, Segmented, Row, Col, Badge, Space, Input, Select } from 'antd';
import { EyeOutlined, FormOutlined, SearchOutlined, BuildOutlined } from '@ant-design/icons';
import { Inquiry } from '../types';
import ViewUserHistoryModal from '../modals/ViewUserHistoryModal';
import ViewParentProjectModal, { ProjectData } from '../modals/ViewParentProjectModal';
import InquiryInspectorDrawer from '../modals/InquiryInspectorDrawer';

const { Title, Text } = Typography;

interface ProjectsProps {
  inquiries: Inquiry[];
  onEstimateClick: (inq: Inquiry) => void;
  onViewDetailClick: (inq: Inquiry) => void;
  onRefreshInquiries?: () => void;
}

export default function Projects({ inquiries, onEstimateClick, onViewDetailClick, onRefreshInquiries }: ProjectsProps) {
  const [projectSubTab, setProjectSubTab] = useState<'pending' | 'broadcasted' | 'closed'>('pending');
  const [selectedEmployerId, setSelectedEmployerId] = useState<string | null>(null);
  const [selectedProject, setSelectedProject] = useState<ProjectData | null>(null);
  const [inspectorInquiryId, setInspectorInquiryId] = useState<string | null>(null);
  const [searchText, setSearchText] = useState('');
  const [systemFilter, setSystemFilter] = useState<'all' | 'project' | 'legacy'>('all');

  const pendingInquiries = inquiries.filter(i => i.status === 'PENDING_ESTIMATION' || i.status === 'DRAFT');
  const broadcastedInquiries = inquiries.filter(i => 
    i.status === 'BROADCASTED' || 
    i.status === 'ESTIMATED' || 
    i.status === 'DISPATCHED' || 
    i.status === 'AGREEMENT_PENDING_WELDER' || 
    i.status === 'IN_PROGRESS' || 
    i.status === 'COMPLETED_PENDING_EMPLOYER'
  );
  const closedInquiries = inquiries.filter(i => i.status === 'COMPLETED' || i.status === 'CLOSED' || i.status === 'EXPIRED' || i.status === 'REJECTED');

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

  const currentTabList = getSubTabInquiries();

  const filteredInquiries = currentTabList.filter((inq) => {
    // System Filter (Legacy vs Project-linked)
    if (systemFilter === 'project' && !inq.project) return false;
    if (systemFilter === 'legacy' && inq.project) return false;

    // Search query filter
    if (!searchText.trim()) return true;
    const query = searchText.trim().toLowerCase();

    const titleMatch = inq.title?.toLowerCase().includes(query);
    const projectTitleMatch = inq.project?.title?.toLowerCase().includes(query);
    const employerMatch = inq.employer_name?.toLowerCase().includes(query);
    const cityMatch = inq.city?.toLowerCase().includes(query);
    const provinceMatch = inq.province?.toLowerCase().includes(query);

    return titleMatch || projectTitleMatch || employerMatch || cityMatch || provinceMatch;
  });

  const columns = [
    {
      title: 'عنوان استعلام',
      dataIndex: 'title',
      key: 'title',
      render: (title: string) => <Text strong>{title}</Text>,
    },
    {
      title: 'پروژه والد / منبع',
      key: 'project',
      render: (_: any, inq: Inquiry) => (
        inq.project ? (
          <Tag 
            color="geekblue" 
            style={{ borderRadius: '6px', fontWeight: 'bold', cursor: 'pointer', padding: '4px 10px' }}
            onClick={() => setSelectedProject(inq.project ? {
              ...inq.project,
              employerId: inq.employerId || inq.employer_id,
              employer_name: inq.employer_name,
            } : null)}
          >
            <BuildOutlined style={{ marginLeft: 4 }} />
            {inq.project.title}
          </Tag>
        ) : (
          <Tag color="purple" style={{ borderRadius: '6px' }}>
            سیستم قدیم (مستقیم)
          </Tag>
        )
      ),
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
      title: 'نوع برآورد',
      key: 'estimation_type',
      render: (_: any, inq: Inquiry) => {
        if (inq.estimation_type === 'EXACT') {
          return <Tag color="purple">محاسبه دقیق (پلان + سازه)</Tag>;
        }
        if (inq.has_blueprint || inq.estimation_type === 'ROUGH') {
          return <Tag color="orange">برآورد حدودی (معماری)</Tag>;
        }
        return <Tag color="blue">برآورد دستی</Tag>;
      },
    },
    {
      title: 'وضعیت فنی',
      key: 'status',
      render: (_: any, inq: Inquiry) => {
        if (inq.status === 'PENDING_ESTIMATION') return <Tag color="warning">در انتظار کارشناسی</Tag>;
        if (inq.status === 'ESTIMATED') return <Tag color="gold">کارشناسی‌شده</Tag>;
        if (inq.status === 'BROADCASTED') return <Tag color="success">انتشار یافته</Tag>;
        if (inq.status === 'AGREEMENT_PENDING_WELDER') return <Tag color="purple">در انتظار تایید جوشکار</Tag>;
        if (inq.status === 'IN_PROGRESS') return <Tag color="processing">در حال اجرا</Tag>;
        if (inq.status === 'COMPLETED_PENDING_EMPLOYER') return <Tag color="magenta">در انتظار تایید کارفرما</Tag>;
        if (inq.status === 'COMPLETED') return <Tag color="cyan">اتمام یافته و امتیازدهی‌شده</Tag>;
        if (inq.status === 'REJECTED') return <Tag color="error">رد شده</Tag>;
        return <Tag>{inq.status}</Tag>;
      },
    },
    {
      title: 'تاریخ ثبت',
      key: 'created_at',
      render: (_: any, inq: Inquiry) => {
        const dateStr = inq.created_at
          ? new Date(inq.created_at).toLocaleDateString('fa-IR')
          : 'نامشخص';
        return <Text type="secondary" style={{ fontSize: '12px' }}>{dateStr}</Text>;
      },
    },
    {
      title: 'عملیات',
      key: 'actions',
      align: 'left' as const,
      render: (_: any, inq: Inquiry) => (
        <Space size={6}>
          {inq.status === 'PENDING_ESTIMATION' ? (
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
              مشاهده جزئیات
            </Button>
          )}

          <Button
            size="small"
            type="dashed"
            onClick={() => setInspectorInquiryId(inq.id)}
            style={{ color: '#8B5CF6', borderColor: '#C4B5FD' }}
          >
            نظارت و چرخه حیات
          </Button>
        </Space>
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
      {/* Search and Filter Toolbar */}
      <Row gutter={[12, 12]} style={{ marginBottom: 16 }}>
        <Col xs={24} sm={14} md={10}>
          <Input
            placeholder="جستجو در عنوان استعلام، عنوان پروژه، نام کارفرما یا شهر..."
            prefix={<SearchOutlined style={{ color: '#94A3B8' }} />}
            value={searchText}
            onChange={(e) => setSearchText(e.target.value)}
            allowClear
          />
        </Col>
        <Col xs={24} sm={10} md={6}>
          <Select
            value={systemFilter}
            onChange={(val) => setSystemFilter(val)}
            style={{ width: '100%' }}
            options={[
              { label: 'همه استعلام‌ها (جدید + قدیم)', value: 'all' },
              { label: 'متصل به پروژه (جدید)', value: 'project' },
              { label: 'ثبت مستقیم (سیستم قدیم)', value: 'legacy' },
            ]}
          />
        </Col>
      </Row>

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

      {selectedProject && (
        <ViewParentProjectModal
          project={selectedProject}
          allInquiries={inquiries}
          onClose={() => setSelectedProject(null)}
          onViewInquiryDetail={(inq) => {
            setSelectedProject(null);
            onViewDetailClick(inq);
          }}
        />
      )}

      <InquiryInspectorDrawer
        inquiryId={inspectorInquiryId}
        onClose={() => setInspectorInquiryId(null)}
        onRefresh={() => {
          if (onRefreshInquiries) onRefreshInquiries();
        }}
      />
    </Card>
  );
}
