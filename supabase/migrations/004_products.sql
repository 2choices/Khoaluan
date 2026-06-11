-- ============================================
-- OMNIGO Patch: Product image support (safe)
-- ============================================

-- 1) Add fallback image columns to products
alter table products
  add column if not exists thumbnail text;

alter table products
  add column if not exists thumbnail_url text;

-- 2) Backfill from existing product_images
update products p
set
  thumbnail = img.url,
  thumbnail_url = coalesce(img.thumbnail_url, img.url)
from (
  select distinct on (product_id)
    product_id,
    url,
    thumbnail_url
  from product_images
  order by product_id, is_primary desc, sort_order asc, created_at asc
) img
where p.id = img.product_id
  and (
    p.thumbnail is null
    or p.thumbnail_url is null
  );

-- 3) Ensure one primary image per product
drop index if exists idx_product_images_one_primary_per_product;

create unique index if not exists idx_product_images_one_primary_per_product
on product_images(product_id)
where is_primary = true;

-- 4) Helpful indexes
create index if not exists idx_product_images_tenant
on product_images(tenant_id);

create index if not exists idx_product_images_product_sort
on product_images(product_id, sort_order);

create index if not exists idx_products_thumbnail
on products(id, thumbnail);

-- 5) Sync function
create or replace function sync_product_thumbnail_from_images()
returns trigger
language plpgsql
as $$
declare
  target_product_id uuid;
  primary_image record;
begin
  target_product_id := coalesce(new.product_id, old.product_id);

  select
    url,
    thumbnail_url
  into primary_image
  from product_images
  where product_id = target_product_id
  order by is_primary desc, sort_order asc, created_at asc
  limit 1;

  if primary_image is null then
    update products
    set
      thumbnail = null,
      thumbnail_url = null,
      updated_at = now()
    where id = target_product_id;
  else
    update products
    set
      thumbnail = primary_image.url,
      thumbnail_url = coalesce(primary_image.thumbnail_url, primary_image.url),
      updated_at = now()
    where id = target_product_id;
  end if;

  return coalesce(new, old);
end;
$$;

-- 6) Triggers
drop trigger if exists trg_sync_product_thumbnail_after_insert on product_images;
drop trigger if exists trg_sync_product_thumbnail_after_update on product_images;
drop trigger if exists trg_sync_product_thumbnail_after_delete on product_images;

create trigger trg_sync_product_thumbnail_after_insert
after insert on product_images
for each row
execute function sync_product_thumbnail_from_images();

create trigger trg_sync_product_thumbnail_after_update
after update on product_images
for each row
execute function sync_product_thumbnail_from_images();

create trigger trg_sync_product_thumbnail_after_delete
after delete on product_images
for each row
execute function sync_product_thumbnail_from_images();