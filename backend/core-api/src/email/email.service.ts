import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class EmailService {
  private readonly logger = new Logger(EmailService.name);
  private readonly apiKey: string;
  private readonly fromEmail: string;
  private readonly fallbackFromEmail: string;
  private readonly logoUrl: string;

  constructor(private config: ConfigService) {
    this.apiKey = this.config.get<string>('RESEND_API_KEY', '');
    this.fromEmail = this.config.get<string>('EMAIL_FROM', 'OMNIGO <noreply@omnigo.vn>');
    this.fallbackFromEmail = this.config.get<string>(
      'EMAIL_FROM_FALLBACK',
      'OMNIGO <onboarding@resend.dev>',
    );
    this.logoUrl = this.config.get<string>('LOGO_URL', '');
  }

  private async sendViaResend(
    from: string,
    params: {
      to: string | string[];
      subject: string;
      html: string;
      text?: string;
    },
  ): Promise<{ ok: boolean; result: any }> {
    const response = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${this.apiKey}`,
      },
      body: JSON.stringify({
        from,
        to: Array.isArray(params.to) ? params.to : [params.to],
        subject: params.subject,
        html: params.html,
        text: params.text,
      }),
    });

    const result = await response.json();
    return { ok: response.ok, result };
  }

  /** Wrap content in branded email layout */
  private wrapLayout(content: string): string {
    const logo = this.logoUrl
      ? `<img src="${this.logoUrl}" alt="OMNIGO" style="height:60px;margin-bottom:16px">`
      : `<h1 style="color:#2563eb;margin:0 0 16px">OMNIGO</h1>`;

    return `
      <div style="background:#f1f5f9;padding:32px 0">
        <div style="font-family:Arial,sans-serif;max-width:600px;margin:0 auto;background:#fff;border-radius:12px;overflow:hidden;box-shadow:0 2px 8px rgba(0,0,0,0.06)">
          <div style="background:linear-gradient(135deg,#1e3a5f,#2563eb);padding:24px;text-align:center">
            ${logo}
          </div>
          <div style="padding:24px 32px">
            ${content}
          </div>
          <div style="background:#f8fafc;padding:16px 32px;text-align:center;border-top:1px solid #e2e8f0">
            <p style="color:#94a3b8;font-size:12px;margin:0">OMNIGO - Ứng dụng bán hàng đa nền tảng</p>
          </div>
        </div>
      </div>
    `;
  }

  /** Send email via Resend API */
  async send(params: {
    to: string | string[];
    subject: string;
    html: string;
    text?: string;
  }): Promise<any> {
    if (!this.apiKey) {
      this.logger.warn('Resend API key not configured, skipping email');
      return null;
    }

    try {
      const firstAttempt = await this.sendViaResend(this.fromEmail, params);
      if (firstAttempt.ok) {
        this.logger.log(`Email sent to ${params.to}: ${firstAttempt.result.id}`);
        return firstAttempt.result;
      }

      const errorMessage = String(firstAttempt.result?.message || '');
      const isUnverifiedDomainError =
        firstAttempt.result?.statusCode === 403 &&
        errorMessage.toLowerCase().includes('domain is not verified');

      if (
        isUnverifiedDomainError &&
        this.fallbackFromEmail &&
        this.fallbackFromEmail !== this.fromEmail
      ) {
        this.logger.warn(
          `Sender domain not verified, retrying with fallback sender ${this.fallbackFromEmail}`,
        );
        const retryAttempt = await this.sendViaResend(
          this.fallbackFromEmail,
          params,
        );
        if (retryAttempt.ok) {
          this.logger.log(
            `Email sent via fallback sender to ${params.to}: ${retryAttempt.result.id}`,
          );
          return retryAttempt.result;
        }
        this.logger.error('Resend fallback error', retryAttempt.result);
        return null;
      }

      this.logger.error('Resend error', firstAttempt.result);
      return null;
    } catch (err) {
      this.logger.error('Email send failed', (err as Error).message);
      return null;
    }
  }

  /** Send order confirmation email */
  async sendOrderConfirmation(to: string, order: {
    orderNumber: string;
    items: Array<{ name: string; quantity: number; price: number }>;
    totalAmount: number;
    paymentMethod: string;
  }) {
    const itemRows = order.items
      .map(
        (item) =>
          `<tr><td style="padding:8px;border-bottom:1px solid #eee">${item.name}</td>
           <td style="padding:8px;border-bottom:1px solid #eee;text-align:center">${item.quantity}</td>
           <td style="padding:8px;border-bottom:1px solid #eee;text-align:right">${item.price.toLocaleString('vi-VN')}đ</td></tr>`,
      )
      .join('');

    const html = this.wrapLayout(`
        <h2 style="color:#1e3a5f;margin-top:0">Xác nhận đơn hàng</h2>
        <p>Cảm ơn bạn đã mua hàng! Đơn hàng <strong>#${order.orderNumber}</strong> đã được xác nhận.</p>
        <table style="width:100%;border-collapse:collapse;margin:16px 0">
          <thead>
            <tr style="background:#f1f5f9">
              <th style="padding:10px;text-align:left;font-size:13px;color:#64748b">Sản phẩm</th>
              <th style="padding:10px;text-align:center;font-size:13px;color:#64748b">SL</th>
              <th style="padding:10px;text-align:right;font-size:13px;color:#64748b">Giá</th>
            </tr>
          </thead>
          <tbody>${itemRows}</tbody>
        </table>
        <div style="background:#f0fdf4;border-radius:8px;padding:16px;text-align:right;margin:16px 0">
          <span style="font-size:14px;color:#64748b">Tổng cộng: </span>
          <span style="font-size:22px;font-weight:bold;color:#16a34a">${order.totalAmount.toLocaleString('vi-VN')}đ</span>
        </div>
        <p style="color:#64748b">Thanh toán: <strong>${order.paymentMethod}</strong></p>
    `);

    return this.send({
      to,
      subject: `Xác nhận đơn hàng #${order.orderNumber}`,
      html,
    });
  }

  /** Send password reset email */
  async sendPasswordReset(to: string, resetLink: string) {
    const html = this.wrapLayout(`
        <h2 style="color:#1e3a5f;margin-top:0">Đặt lại mật khẩu</h2>
        <p>Bạn đã yêu cầu đặt lại mật khẩu. Nhấn nút bên dưới để tiếp tục:</p>
        <div style="text-align:center;margin:24px 0">
          <a href="${resetLink}" style="display:inline-block;padding:14px 32px;background:#2563eb;color:#fff;text-decoration:none;border-radius:8px;font-weight:bold;font-size:16px">
            Đặt lại mật khẩu
          </a>
        </div>
        <p style="color:#94a3b8;font-size:12px">Link hết hạn sau 1 giờ. Nếu bạn không yêu cầu, hãy bỏ qua email này.</p>
    `);

    return this.send({
      to,
      subject: 'Đặt lại mật khẩu OMNIGO',
      html,
    });
  }

  /** Send signup OTP email */
  async sendSignupOtp(to: string, otp: string, ttlMinutes: number) {
    const html = this.wrapLayout(`
        <h2 style="color:#1e3a5f;margin-top:0">Mã OTP xác minh tài khoản</h2>
        <p>Dùng mã OTP bên dưới để hoàn tất đăng ký tài khoản OMNIGO:</p>
        <div style="margin:22px 0;text-align:center">
          <div style="display:inline-block;padding:14px 20px;border-radius:12px;background:#fff7ed;border:1px dashed #fb923c;color:#9a3412;font-size:34px;font-weight:800;letter-spacing:8px">
            ${otp}
          </div>
        </div>
        <p style="margin:0;color:#334155">Mã sẽ hết hạn sau <strong>${ttlMinutes} phút</strong>.</p>
        <p style="color:#94a3b8;font-size:12px">Nếu bạn không thực hiện đăng ký, có thể bỏ qua email này.</p>
    `);

    return this.send({
      to,
      subject: 'Mã OTP đăng ký OMNIGO',
      html,
    });
  }

  /** Send daily report email */
  async sendDailyReport(to: string, report: {
    date: string;
    totalRevenue: number;
    orderCount: number;
    newCustomers: number;
  }) {
    const html = this.wrapLayout(`
        <h2 style="color:#1e3a5f;margin-top:0">Báo cáo ngày ${report.date}</h2>
        <table style="width:100%;border-collapse:collapse">
          <tr>
            <td style="padding:16px;font-weight:bold;font-size:14px">Doanh thu</td>
            <td style="padding:16px;text-align:right;color:#16a34a;font-size:22px;font-weight:bold">${report.totalRevenue.toLocaleString('vi-VN')}đ</td>
          </tr>
          <tr style="background:#f8fafc">
            <td style="padding:16px;font-weight:bold;font-size:14px">Số đơn hàng</td>
            <td style="padding:16px;text-align:right;font-size:22px;font-weight:bold;color:#2563eb">${report.orderCount}</td>
          </tr>
          <tr>
            <td style="padding:16px;font-weight:bold;font-size:14px">Khách hàng mới</td>
            <td style="padding:16px;text-align:right;font-size:22px;font-weight:bold;color:#f59e0b">${report.newCustomers}</td>
          </tr>
        </table>
    `);

    return this.send({
      to,
      subject: `Báo cáo doanh thu ngày ${report.date}`,
      html,
    });
  }
}
