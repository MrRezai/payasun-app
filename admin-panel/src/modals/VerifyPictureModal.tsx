import { useState } from 'react';
import { Modal, Button, Space, Image, Typography, Alert, Card, Row } from 'antd';
import { CheckCircleOutlined, CloseCircleOutlined } from '@ant-design/icons';
import { BASE_URL } from '../api';

const { Text, Paragraph } = Typography;

interface VerifyPictureModalProps {
  user: any;
  onClose: () => void;
  onVerify: (userId: string, role: 'WELDER' | 'EMPLOYER', approve: boolean) => void;
}

export default function VerifyPictureModal({ user, onClose, onVerify }: VerifyPictureModalProps) {
  const [confirmAction, setConfirmAction] = useState<boolean | null>(null);

  const imageUrl = user.pending_url 
    ? (user.pending_url.startsWith('http') ? user.pending_url : `${BASE_URL}${user.pending_url}`)
    : '';

  return (
    <Modal
      open={true}
      title="بررسی تصویر ارسالی جهت احراز هویت"
      onCancel={onClose}
      footer={null}
      width={520}
      centered
    >
      {confirmAction !== null ? (
        <Space direction="vertical" style={{ width: '100%' }} size="medium">
          <Alert
            message={confirmAction ? 'تایید نهایی تصویر پروفایل' : 'رد نهایی تصویر پروفایل'}
            description={
              confirmAction
                ? `آیا از تایید تصویر پروفایل کاربر «${user.name}» اطمینان دارید؟ تصویر جدید پس از تایید در اپلیکیشن فعال خواهد شد.`
                : `آیا از رد تصویر پروفایل کاربر «${user.name}» اطمینان دارید؟ تصویر ارسالی حذف خواهد شد.`
            }
            type={confirmAction ? 'success' : 'error'}
            showIcon
            icon={confirmAction ? <CheckCircleOutlined /> : <CloseCircleOutlined />}
          />

          <Row justify="end" style={{ gap: '8px', marginTop: '16px' }}>
            <Button
              type="primary"
              danger={!confirmAction}
              style={confirmAction ? { backgroundColor: '#10B981', borderColor: '#10B981', fontWeight: 'bold' } : { fontWeight: 'bold' }}
              onClick={() => onVerify(user.id, user.role, confirmAction)}
            >
              {confirmAction ? 'تایید قطعی و ثبت انتشار' : 'ثبت قطعی رد تصویر'}
            </Button>
            <Button onClick={() => setConfirmAction(null)}>
              انصراف و بازگشت
            </Button>
          </Row>
        </Space>
      ) : (
        <Space direction="vertical" style={{ width: '100%', textAlign: 'center' }} size="large">
          <div style={{ textAlign: 'center' }}>
            {imageUrl ? (
              <Image
                width={220}
                height={220}
                src={imageUrl}
                style={{ borderRadius: 16, objectFit: 'cover', boxShadow: '0 8px 24px rgba(0,0,0,0.1)' }}
              />
            ) : (
              <Card style={{ width: 220, margin: '0 auto', textAlign: 'center' }}>
                <Text type="secondary">فاقد تصویر ارسالی</Text>
              </Card>
            )}
          </div>

          <Card size="small" style={{ textAlign: 'right', backgroundColor: '#fafafa' }}>
            <Paragraph style={{ margin: '0 0 6px 0', fontSize: '13px' }}>
              <Text type="secondary">کاربر: </Text>
              <Text strong>{user.name}</Text>
              <Text type="secondary"> ({user.role === 'WELDER' ? 'جوشکار' : 'کارفرما'})</Text>
            </Paragraph>
            <Paragraph style={{ margin: 0, fontSize: '13px' }}>
              <Text type="secondary">بیوگرافی / توضیحات: </Text>
              <Text italic>{user.bio || 'توضیحاتی وارد نشده است.'}</Text>
            </Paragraph>
          </Card>

          <Row justify="end" style={{ gap: '8px' }}>
            <Button
              type="primary"
              style={{ backgroundColor: '#10B981', borderColor: '#10B981', fontWeight: 'bold' }}
              onClick={() => setConfirmAction(true)}
            >
              تایید تصویر و انتشار
            </Button>
            <Button danger onClick={() => setConfirmAction(false)}>
              رد تصویر
            </Button>
            <Button onClick={onClose}>
              بستن
            </Button>
          </Row>
        </Space>
      )}
    </Modal>
  );
}
