import { Card, Form, Input, Button, Typography } from 'antd';
import { UserOutlined, LockOutlined, SafetyCertificateOutlined } from '@ant-design/icons';
import logoImg from '../assets/logo/joftojoor.png';

const { Title, Text } = Typography;

interface LoginProps {
  onLoginSuccess: (username: string, pass: string) => Promise<void>;
  isOnline?: boolean;
  isLoading: boolean;
}

export default function Login({ onLoginSuccess, isLoading }: LoginProps) {
  const onFinish = (values: { username: string; password: string }) => {
    onLoginSuccess(values.username, values.password);
  };

  return (
    <div
      style={{
        display: 'flex',
        flexDirection: 'column',
        minHeight: '100vh',
        width: '100%',
        alignItems: 'center',
        justifyContent: 'center',
        backgroundColor: '#F8FAFC',
        padding: '24px 16px',
        boxSizing: 'border-box',
      }}
    >
      <div style={{ width: '100%', maxWidth: '400px', margin: 'auto 0' }}>
        <Card
          style={{
            width: '100%',
            borderRadius: '20px',
            backgroundColor: '#FFFFFF',
            boxShadow: '0 10px 25px -5px rgba(15, 23, 42, 0.08), 0 8px 10px -6px rgba(15, 23, 42, 0.04)',
            border: '1px solid #E2E8F0',
          }}
          bodyStyle={{ padding: '32px 24px' }}
        >
          <div style={{ textAlign: 'center', marginBottom: '24px' }}>
            <img src={logoImg} alt="جفت و جور" style={{ width: '60px', height: '60px', marginBottom: '12px', borderRadius: '14px' }} />
            <Title level={4} style={{ margin: 0, fontWeight: 800, color: '#0F172A', fontSize: '18px' }}>
              ورود به پنل مدیریت جفت‌وجور
            </Title>
            <Text
              type="secondary"
              style={{
                fontSize: '12px',
                marginTop: '6px',
                display: 'inline-flex',
                alignItems: 'center',
                justifyContent: 'center',
                gap: '6px',
                color: '#64748B',
              }}
            >
              <SafetyCertificateOutlined style={{ color: '#4169E1', fontSize: '14px' }} />
              احراز هویت کنترل ادمین سیستم
            </Text>
          </div>

          <Form
            name="admin_login"
            layout="vertical"
            onFinish={onFinish}
            autoComplete="off"
            size="large"
          >
            <Form.Item
              label={<span style={{ fontWeight: 600, fontSize: '13px', color: '#334155' }}>نام کاربری ادمین (Username)</span>}
              name="username"
              rules={[{ required: true, message: 'لطفاً نام کاربری را وارد کنید.' }]}
            >
              <Input
                prefix={<UserOutlined style={{ color: '#94A3B8' }} />}
                placeholder="نام کاربری"
                disabled={isLoading}
                style={{ borderRadius: '10px' }}
              />
            </Form.Item>

            <Form.Item
              label={<span style={{ fontWeight: 600, fontSize: '13px', color: '#334155' }}>رمز عبور (Password)</span>}
              name="password"
              rules={[{ required: true, message: 'لطفاً رمز عبور را وارد کنید.' }]}
            >
              <Input.Password
                prefix={<LockOutlined style={{ color: '#94A3B8' }} />}
                placeholder="رمز عبور"
                disabled={isLoading}
                style={{ borderRadius: '10px' }}
              />
            </Form.Item>

            <Form.Item style={{ marginTop: '24px', marginBottom: 0 }}>
              <Button
                type="primary"
                htmlType="submit"
                loading={isLoading}
                block
                style={{
                  height: '44px',
                  fontWeight: 700,
                  fontSize: '14px',
                  borderRadius: '10px',
                  backgroundColor: '#4169E1',
                  borderColor: '#4169E1',
                }}
              >
                {isLoading ? 'در حال بررسی...' : 'ورود به پنل مدیریت'}
              </Button>
            </Form.Item>
          </Form>
        </Card>
      </div>
    </div>
  );
}
