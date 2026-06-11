import { Injectable, Logger, BadRequestException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { SupabaseService } from '../supabase/supabase.service';

const GHN_API = 'https://online-gateway.ghn.vn/shiip/public-api/v2';

@Injectable()
export class ShippingService {
  private readonly logger = new Logger(ShippingService.name);

  constructor(
    private config: ConfigService,
    private supabase: SupabaseService,
  ) {}

  private get db() {
    return this.supabase.getAdminClient();
  }

  private get headers() {
    return {
      'Content-Type': 'application/json',
      Token: this.config.get<string>('GHN_API_TOKEN', ''),
      ShopId: this.config.get<string>('GHN_SHOP_ID', ''),
    };
  }

  /** Calculate shipping fee */
  async calculateFee(params: {
    from_district_id: number;
    to_district_id: number;
    to_ward_code: string;
    weight: number;
    length?: number;
    width?: number;
    height?: number;
    service_type_id?: number;
  }) {
    const response = await fetch(`${GHN_API}/shipping-order/fee`, {
      method: 'POST',
      headers: this.headers,
      body: JSON.stringify({
        service_type_id: params.service_type_id || 2,
        from_district_id: params.from_district_id,
        to_district_id: params.to_district_id,
        to_ward_code: params.to_ward_code,
        weight: params.weight,
        length: params.length || 10,
        width: params.width || 10,
        height: params.height || 10,
      }),
    });

    const result = await response.json();
    if (result.code !== 200) {
      this.logger.error('GHN fee error', result);
      throw new BadRequestException(`GHN error: ${result.message}`);
    }

    return result.data;
  }

  /** Get estimated delivery time */
  async getLeadTime(params: {
    from_district_id: number;
    to_district_id: number;
    to_ward_code: string;
    service_id?: number;
  }) {
    const response = await fetch(`${GHN_API}/shipping-order/leadtime`, {
      method: 'POST',
      headers: this.headers,
      body: JSON.stringify(params),
    });

    const result = await response.json();
    if (result.code !== 200) throw new BadRequestException(`GHN error: ${result.message}`);
    return result.data;
  }

  /** Create shipping order */
  async createShippingOrder(
    tenantId: string,
    orderId: string,
    params: {
      to_name: string;
      to_phone: string;
      to_address: string;
      to_ward_code: string;
      to_district_id: number;
      weight: number;
      length?: number;
      width?: number;
      height?: number;
      cod_amount?: number;
      note?: string;
      items: Array<{ name: string; quantity: number; weight: number }>;
    },
  ) {
    const response = await fetch(`${GHN_API}/shipping-order/create`, {
      method: 'POST',
      headers: this.headers,
      body: JSON.stringify({
        payment_type_id: params.cod_amount ? 2 : 1,
        required_note: 'CHOTHUHANG',
        to_name: params.to_name,
        to_phone: params.to_phone,
        to_address: params.to_address,
        to_ward_code: params.to_ward_code,
        to_district_id: params.to_district_id,
        weight: params.weight,
        length: params.length || 10,
        width: params.width || 10,
        height: params.height || 10,
        cod_amount: params.cod_amount || 0,
        note: params.note || '',
        service_type_id: 2,
        items: params.items,
      }),
    });

    const result = await response.json();
    if (result.code !== 200) {
      this.logger.error('GHN create order error', result);
      throw new BadRequestException(`GHN error: ${result.message}`);
    }

    // Save to DB
    await this.db.from('shipping_orders').insert({
      tenant_id: tenantId,
      order_id: orderId,
      provider: 'ghn',
      tracking_code: result.data.order_code,
      status: 'created',
      shipping_fee: result.data.total_fee,
      estimated_delivery: result.data.expected_delivery_time,
      provider_data: result.data,
    });

    return result.data;
  }

  /** Track shipping order */
  async trackOrder(orderCode: string) {
    const response = await fetch(`${GHN_API}/shipping-order/detail`, {
      method: 'POST',
      headers: this.headers,
      body: JSON.stringify({ order_code: orderCode }),
    });

    const result = await response.json();
    if (result.code !== 200) throw new BadRequestException(`GHN error: ${result.message}`);
    return result.data;
  }

  /** Get provinces */
  async getProvinces() {
    const response = await fetch(
      'https://online-gateway.ghn.vn/shiip/public-api/master-data/province',
      { headers: this.headers },
    );
    const result = await response.json();
    return result.data || [];
  }

  /** Get districts by province */
  async getDistricts(provinceId: number) {
    const response = await fetch(
      'https://online-gateway.ghn.vn/shiip/public-api/master-data/district',
      {
        method: 'POST',
        headers: this.headers,
        body: JSON.stringify({ province_id: provinceId }),
      },
    );
    const result = await response.json();
    return result.data || [];
  }

  /** Get wards by district */
  async getWards(districtId: number) {
    const response = await fetch(
      'https://online-gateway.ghn.vn/shiip/public-api/master-data/ward',
      {
        method: 'POST',
        headers: this.headers,
        body: JSON.stringify({ district_id: districtId }),
      },
    );
    const result = await response.json();
    return result.data || [];
  }
}
