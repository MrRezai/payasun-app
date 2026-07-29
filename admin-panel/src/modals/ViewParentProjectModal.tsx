import { useState } from 'react';
import { Modal, Row, Col, Card, Table, Tag, Button, Space, Typography, Badge, Image } from 'antd';
import { 
  BuildOutlined, 
  EnvironmentOutlined, 
  UserOutlined, 
  CalendarOutlined, 
  FileTextOutlined, 
  EyeOutlined, 
  PictureOutlined, 
  AppstoreOutlined,
  CheckCircleOutlined
} from '@ant-design/icons';
import { BASE_URL } from '../api';
import { Inquiry } from '../types';
import ViewUserHistoryModal from './ViewUserHistoryModal';

const { Title, Text, Paragraph } = Typography;

export interface ProjectData {
  id: string;
  title: string;
  description?: string;
  city?: string;
  province?: string;
  address?: string;
  image_urls?: string[];
  created_at?: string;
  employerId?: string;
  employer_name?: string;
}

interface ViewParentProjectModalProps {
  project: ProjectData;
  allInquiries?: Inquiry[];
  onClose: () => void;
  onViewInquiryDetail?: (inquiry: Inquiry) => void;
}

export default function ViewParentProjectModal({
  project,
  allInquiries = [],
  onClose,
  onViewInquiryDetail,
}: ViewParentProjectModalProps) {
  const [selectedEmployerId, setSelectedEmployerId] = useState<string | null>(null);

  // Find all child inquiries linked to this project
  const linkedInquiries = allInquiries.filter(
    (inq) => inq.projectId === project.id || (inq.project && inq.project.id === project.id)
  );

  // Format date if available
  const dateStr = project.created_at
    ? new Date(project.created_at).toLocaleDateString('fa-IR')
    : 'نامشخص';

  // Extract photos
  const photoUrls = (project.image_urls || []).map((img) =>
    img.startsWith('http') ? img : `${BASE_URL}${img}`
  );

  const getStatusTag = (status: string) => {
    switch (status) {
      case 'PENDING_ESTIMATION':
        return <Tag color="warning">در انتظار کارشناسی</Tag>;
      case 'ESTIMATED':
        return <Tag color="gold">کارشناسی‌شده</Tag>;
      case 'BROADCASTED':
        return <Tag color="success">منتشر شده</Tag>;
      case 'REJECTED':
        return <Tag color="error">رد شده</Tag>;
      default:
        return <Tag>خاتمه‌یافته</Tag>;
    }
  };

  const inquiryColumns = [
    {
      title: 'عنوان استعلام',
      dataIndex: 'title',
      key: 'title',
      render: (title: string) => <Text strong>{title}</Text>,
    },
    {
      title: 'وضعیت',
      key: 'status',
      render: (_: any, inq: Inquiry) => getStatusTag(inq.status),
    },
    {
      title: 'تعداد اقلام',
      key: 'items',
      render: (_: any, inq: Inquiry) => (
        <Badge count={inq.items?.length || 0} showZero style={{ backgroundColor: '#4169E1' }} />
      ),
    },
    {
      title: 'نوع نقشه',
      key: 'blueprint',
      render: (_: any, inq: Inquiry) =>
        inq.has_blueprint ? <Tag color="blue">نقشه فنی دارد</Tag> : <Tag>ورود دستی</Tag>,
    },
    {
      title: 'عملیات',
      key: 'actions',
      align: 'left' as const,
      render: (_: any, inq: Inquiry) => (
        <Button
          size="small"
          type="primary"
          ghost
          icon={<EyeOutlined />}
          onClick={() => {
            if (onViewInquiryDetail) {
              onViewInquiryDetail(inq);
            }
          }}
          style={{ borderRadius: '6px' }}
        >
          مشاهده استعلام
        </Button>
      ),
    },
  ];

  return (
    <>
      <Modal
        open={true}
        onCancel={onClose}
        footer={null}
        width={820}
        centered
        bodyStyle={{ maxHeight: '82vh', overflowY: 'auto', padding: '16px 20px' }}
        title={
          <Space align="center" size="middle">
            <BuildOutlined style={{ fontSize: '20px', color: '#4169E1' }} />
            <div>
              <Title level={5} style={{ margin: 0 }}>
                {project.title}
              </Title>
              <Text type="secondary" style={{ fontSize: '11px' }}>
                اطلاعات کامل پروژه والد
              </Text>
            </div>
          </Space>
        }
      >
        <div style={{ paddingTop: '8px' }}>
          <Space direction="vertical" size="large" style={{ width: '100%' }}>
            {/* Quick Metrics Grid */}
            <Row gutter={[16, 16]}>
              <Col xs={24} sm={8}>
                <Card
                  size="small"
                  style={{
                    borderRadius: '12px',
                    backgroundColor: '#F8FAFC',
                    border: '1px solid #E2E8F0',
                  }}
                >
                  <Space align="center">
                    <EnvironmentOutlined style={{ fontSize: 20, color: '#4169E1' }} />
                    <div>
                      <Text type="secondary" style={{ fontSize: '11px', display: 'block' }}>
                        موقعیت مکانی
                      </Text>
                      <Text strong style={{ fontSize: '13px', color: '#0F172A' }}>
                        {project.province || 'نامشخص'}، {project.city || 'نامشخص'}
                      </Text>
                    </div>
                  </Space>
                </Card>
              </Col>

              <Col xs={24} sm={8}>
                <Card
                  size="small"
                  style={{
                    borderRadius: '12px',
                    backgroundColor: '#F8FAFC',
                    border: '1px solid #E2E8F0',
                  }}
                >
                  <Space align="center">
                    <AppstoreOutlined style={{ fontSize: 20, color: '#F59E0B' }} />
                    <div>
                      <Text type="secondary" style={{ fontSize: '11px', display: 'block' }}>
                        تعداد استعلام‌های وابسـته
                      </Text>
                      <Text strong style={{ fontSize: '14px', color: '#0F172A' }}>
                        {linkedInquiries.length} استعلام ثبت‌شده
                      </Text>
                    </div>
                  </Space>
                </Card>
              </Col>

              <Col xs={24} sm={8}>
                <Card
                  size="small"
                  style={{
                    borderRadius: '12px',
                    backgroundColor: '#F8FAFC',
                    border: '1px solid #E2E8F0',
                  }}
                >
                  <Space align="center">
                    <CalendarOutlined style={{ fontSize: 20, color: '#10B981' }} />
                    <div>
                      <Text type="secondary" style={{ fontSize: '11px', display: 'block' }}>
                        تاریخ ثبت پروژه
                      </Text>
                      <Text strong style={{ fontSize: '13px', color: '#0F172A' }}>
                        {dateStr}
                      </Text>
                    </div>
                  </Space>
                </Card>
              </Col>
            </Row>

            {/* Employer Info Row */}
            {(project.employer_name || project.employerId) && (
              <Card
                size="small"
                style={{
                  borderRadius: '12px',
                  backgroundColor: '#EFF6FF',
                  border: '1px solid #BFDBFE',
                }}
              >
                <Row justify="space-between" align="middle">
                  <Col>
                    <Space align="center" size="middle">
                      <UserOutlined style={{ fontSize: 18, color: '#1E3A8A' }} />
                      <div>
                        <Text type="secondary" style={{ fontSize: '11px', color: '#1E40AF', display: 'block' }}>
                          کارفرمای این پروژه:
                        </Text>
                        <Text strong style={{ fontSize: '14px', color: '#1E3A8A' }}>
                          {project.employer_name || 'کارفرمای پلتفرم'}
                        </Text>
                      </div>
                    </Space>
                  </Col>
                  {project.employerId && (
                    <Col>
                      <Button
                        size="small"
                        type="primary"
                        icon={<UserOutlined />}
                        onClick={() => setSelectedEmployerId(project.employerId!)}
                        style={{ borderRadius: '8px', fontWeight: 'bold' }}
                      >
                        مشاهده سوابق و کارت کارفرما
                      </Button>
                    </Col>
                  )}
                </Row>
              </Card>
            )}

            {/* Project Full Description & Location */}
            <Card
              size="small"
              title={
                <Space>
                  <FileTextOutlined style={{ color: '#4169E1' }} />
                  <Text strong>توضیحات کامل و مشخصات پروژه</Text>
                </Space>
              }
              style={{ borderRadius: '12px' }}
            >
              <Paragraph style={{ margin: '0 0 10px 0', fontSize: '13px', lineHeight: 1.7 }}>
                {project.description || 'توضیحات تکمیلی برای این پروژه ثبت نشده است.'}
              </Paragraph>
              {project.address && (
                <div
                  style={{
                    backgroundColor: '#F8FAFC',
                    padding: '8px 12px',
                    borderRadius: '8px',
                    border: '1px solid #E2E8F0',
                  }}
                >
                  <Text type="secondary" style={{ fontSize: '12px' }}>
                    <EnvironmentOutlined style={{ marginLeft: 4, color: '#F59E0B' }} />
                    آدرس کامل اجرای کارگاه:{' '}
                  </Text>
                  <Text strong style={{ fontSize: '12px' }}>
                    {project.address}
                  </Text>
                </div>
              )}
            </Card>

            {/* Project Photo Gallery */}
            {photoUrls.length > 0 && (
              <Card
                size="small"
                title={
                  <Space>
                    <PictureOutlined style={{ color: '#F59E0B' }} />
                    <Text strong>آلبوم تصاویر پروژه ({photoUrls.length} تصویر)</Text>
                  </Space>
                }
                style={{ borderRadius: '12px' }}
              >
                <Image.PreviewGroup>
                  <Row gutter={[12, 12]}>
                    {photoUrls.map((url, idx) => (
                      <Col xs={12} sm={8} md={6} key={idx}>
                        <Image
                          src={url}
                          alt={`تصویر پروژه ${idx + 1}`}
                          style={{
                            width: '100%',
                            height: 110,
                            objectFit: 'cover',
                            borderRadius: 10,
                            border: '1px solid #E2E8F0',
                          }}
                        />
                      </Col>
                    ))}
                  </Row>
                </Image.PreviewGroup>
              </Card>
            )}

            {/* Linked Inquiries List */}
            <Card
              size="small"
              title={
                <Row justify="space-between" align="middle">
                  <Space>
                    <CheckCircleOutlined style={{ color: '#10B981' }} />
                    <Text strong>لیست استعلام‌های صادر شده تحت این پروژه</Text>
                  </Space>
                  <Badge
                    count={linkedInquiries.length}
                    style={{ backgroundColor: '#4169E1' }}
                  />
                </Row>
              }
              style={{ borderRadius: '12px' }}
            >
              {linkedInquiries.length === 0 ? (
                <Text type="secondary" style={{ display: 'block', textAlign: 'center', padding: '20px 0' }}>
                  هنوز هیچ استعلامی روی این پروژه ثبت نشده است.
                </Text>
              ) : (
                <Table
                  dataSource={linkedInquiries}
                  columns={inquiryColumns}
                  rowKey="id"
                  pagination={false}
                  size="small"
                  scroll={{ x: 'max-content' }}
                />
              )}
            </Card>
          </Space>
        </div>
      </Modal>

      {/* User History Modal (when clicking Employer profile) */}
      {selectedEmployerId && (
        <ViewUserHistoryModal
          userId={selectedEmployerId}
          onClose={() => setSelectedEmployerId(null)}
        />
      )}
    </>
  );
}
