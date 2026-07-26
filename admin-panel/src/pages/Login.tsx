import { Card, Form, Input, Button, Typography } from 'antd';
import { UserOutlined, LockOutlined } from '@ant-design/icons';
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
    <div style={{ display: 'flex', minHeight: '100vh', alignItems: 'center', justifyContent: 'center', backgroundColor: '#F8FAFC', padding: '16px' }}>
      <Card 
        style={{ width: '100%', maxWidth: '420px', borderRadius: '16px', boxShadow: '0 10px 30px rgba(15, 23, 42, 0.08)' }}
        bodyStyle={{ padding: '32px 24px' }}
      >
        <div style={{ textAlign: 'center', marginBottom: '24px' }}>
          <img src={logoImg} alt="جفت و جور" style={{ width: '64px', height: '64px', marginBottom: '12px', borderRadius: '16px' }} />
          <Title level={4} style={{ margin: 0, fontWeight: 800, color: 'var(--text-primary)' }}>
            ورود به پنل مدیریت جفت‌وجور
          </Title>
          <Text type="secondary" style={{ fontSize: '12px', marginTop: '6px', display: 'block' }}>
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
            label="نام کاربری ادمین (Username)"
            name="username"
            rules={[{ required: true, message: 'لطفاً نام کاربری را وارد کنید.' }]}
          >
            <Input 
              prefix={<UserOutlined style={{ color: 'rgba(0,0,0,0.25)' }} />} 
              placeholder="نام کاربری"
              disabled={isLoading}
            />
          </Form.Item>

          <Form.Item
            label="رمز عبور (Password)"
            name="password"
            rules={[{ required: true, message: 'لطفاً رمز عبور را وارد کنید.' }]}
          >
            <Input.Password 
              prefix={<LockOutlined style={{ color: 'rgba(0,0,0,0.25)' }} />} 
              placeholder="رمز عبور"
              disabled={isLoading}
            />
          </Form.Item>

          <Form.Item style={{ marginTop: '24px', marginBottom: 0 }}>
            <Button 
              type="primary" 
              htmlType="submit" 
              loading={isLoading} 
              block 
              style={{ height: '46px', fontWeight: 'bold' }}
            >
              {isLoading ? 'در حال بررسی...' : 'ورود به پنل مدیریت'}
            </Button>
          </Form.Item>
        </Form>
      </Card>
    </div>
  );
}
